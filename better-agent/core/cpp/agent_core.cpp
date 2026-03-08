#include "agent_core.h"
#include "internal/agent_core_internal.hpp"
#include "internal/core_rust_bridge.hpp"

namespace {

using json = nlohmann::json;
namespace core_internal = better_agent::core_internal;

bool parse_json_object_arg(const char *json_text, const char *field_name, json *out, json *err_out) {
    *out = json::object();
    *err_out = nullptr;

    if (json_text == nullptr) {
        return true;
    }

    try {
        const json parsed = json::parse(json_text);
        if (!parsed.is_object()) {
            *err_out = core_internal::make_error_json(
                "E_PARSE",
                std::string(field_name) + " must be a JSON object"
            );
            return false;
        }
        *out = parsed;
        return true;
    } catch (const std::exception &e) {
        *err_out = core_internal::make_error_json(
            "E_PARSE",
            std::string("invalid ") + field_name,
            e.what()
        );
        return false;
    }
}

const char *fail_memory_api(const json &err) {
    core_internal::g_last_error = err.dump();
    core_internal::g_last_output = json{
        {"status", "failed"},
        {"error", err}
    }.dump();
    return core_internal::g_last_output.c_str();
}

bool enrich_execution_record_input(json *input, json *err_out) {
    if (!input->is_object()) {
        *err_out = core_internal::make_error_json(
            "E_MEMORY_INPUT",
            "memory_input_json must be a JSON object"
        );
        return false;
    }
    if (core_internal::get_string_or(*input, "input_type") != "execution_record") {
        return true;
    }
    if (input->contains("record") && (*input).at("record").is_object() && !(*input).at("record").empty()) {
        return true;
    }

    const std::string execution_id = core_internal::get_string_or(*input, "execution_id");
    if (execution_id.empty()) {
        return true;
    }

    std::lock_guard<std::mutex> lk(core_internal::g_tools_mu);
    if (!core_internal::g_executions.contains(execution_id)) {
        *err_out = core_internal::make_error_json(
            "E_NOT_FOUND",
            "execution record not found",
            json{{"execution_id", execution_id}}
        );
        return false;
    }
    (*input)["record"] = core_internal::serialize_execution_record(core_internal::g_executions.at(execution_id));
    return true;
}

} // namespace

int agent_core_init(void) {
    std::scoped_lock lk(core_internal::g_tools_mu, core_internal::g_memory_mu);
    core_internal::g_tools.clear();
    core_internal::g_executions.clear();
    {
        std::lock_guard<std::mutex> sandbox_lk(core_internal::g_sandbox_mu);
        core_internal::g_sandbox_capability_cache = json::object();
        core_internal::g_sandbox_capability_cache_valid = false;
    }
    core_internal::reset_memory_state_locked();
    return 0;
}

void agent_core_shutdown(void) {
    std::scoped_lock lk(core_internal::g_tools_mu, core_internal::g_memory_mu);
    core_internal::g_tools.clear();
    core_internal::g_executions.clear();
    {
        std::lock_guard<std::mutex> sandbox_lk(core_internal::g_sandbox_mu);
        core_internal::g_sandbox_capability_cache = json::object();
        core_internal::g_sandbox_capability_cache_valid = false;
    }
    core_internal::reset_memory_state_locked();
}

const char *agent_core_version(void) {
    return "0.3.0";
}

int agent_core_register_tool(const char *tool_definition_json) {
    core_internal::g_last_error.clear();
    if (tool_definition_json == nullptr) {
        core_internal::g_last_error = R"({"error_code":"E_INPUT","message":"tool_definition_json is null"})";
        return 1;
    }

    try {
        core_internal::ToolRegistration tool;
        if (!core_internal::parse_tool_registration_json(tool_definition_json, &tool)) {
            return 2;
        }

        std::lock_guard<std::mutex> lk(core_internal::g_tools_mu);
        core_internal::g_tools[tool.spec.name] = std::move(tool);
        return 0;
    } catch (const std::exception &e) {
        core_internal::g_last_error = json{
            {"error_code", "E_PARSE"},
            {"message", "invalid tool definition json"},
            {"detail", e.what()}
        }.dump();
        return 3;
    }
}

const char *agent_core_sandbox_probe(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (!parse_json_object_arg(request_json, "request_json", &request, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    std::lock_guard<std::mutex> lk(core_internal::g_sandbox_mu);
    json err;
    const json out = core_internal::get_sandbox_capabilities_locked(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_normalize_runtime_event(const char *raw_event_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    if (raw_event_json == nullptr) {
        core_internal::g_last_error = "raw_event_json is null";
        core_internal::g_last_output = json{
            {"execution_id", core_internal::next_id("invalid")},
            {"source", "unknown"},
            {"event_type", "unknown"},
            {"tool_kind", "function"},
            {"intent", nullptr},
            {"input_raw", json::object()},
            {"input_normalized", json::object()},
            {"policy_snapshot", json::object()},
            {"status", "failed"},
            {"evidence", json::array()},
            {"error", json{{"code", "invalid_input"}, {"message", core_internal::g_last_error}}},
            {"handoff", "manual_takeover"},
            {"timestamp", core_internal::now_iso8601_utc()}
        }.dump();
        return core_internal::g_last_output.c_str();
    }

    try {
        const json raw = json::parse(raw_event_json);
        json err;
        const json out = core_internal::normalize_runtime_event_via_rust(raw, &err);
        if (!err.is_null()) {
            core_internal::g_last_error = err.dump();
            core_internal::g_last_output = json{
                {"execution_id", core_internal::next_id("runtime")},
                {"source", "unknown"},
                {"event_type", "error"},
                {"tool_kind", "function"},
                {"intent", "parse_failure"},
                {"input_raw", json::object()},
                {"input_normalized", json::object()},
                {"policy_snapshot", json::object()},
                {"status", "failed"},
                {"evidence", json::array()},
                {"error", err},
                {"handoff", "manual_classification"},
                {"timestamp", core_internal::now_iso8601_utc()}
            }.dump();
            return core_internal::g_last_output.c_str();
        }
        core_internal::g_last_output = out.dump();
        return core_internal::g_last_output.c_str();
    } catch (const std::exception &e) {
        core_internal::g_last_error = e.what();
        core_internal::g_last_output = json{
            {"execution_id", core_internal::next_id("parse-error")},
            {"source", "unknown"},
            {"event_type", "unknown"},
            {"tool_kind", "function"},
            {"intent", nullptr},
            {"input_raw", json{{"raw_text", raw_event_json}}},
            {"input_normalized", json::object()},
            {"policy_snapshot", json::object()},
            {"status", "failed"},
            {"evidence", json::array()},
            {"error", json{{"code", "invalid_json"}, {"message", core_internal::g_last_error}}},
            {"handoff", "manual_takeover"},
            {"timestamp", core_internal::now_iso8601_utc()}
        }.dump();
        return core_internal::g_last_output.c_str();
    }
}

const char *agent_core_last_error(void) {
    return core_internal::g_last_error.c_str();
}

const char *agent_core_memory_configure(const char *config_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json config;
    json parse_err;
    if (!parse_json_object_arg(config_json, "config_json", &config, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    std::lock_guard<std::mutex> lk(core_internal::g_memory_mu);
    json err;
    const json out = core_internal::configure_memory_locked(config, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_memory_ingest(const char *memory_input_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    if (memory_input_json == nullptr) {
        return fail_memory_api(core_internal::make_error_json(
            "E_INPUT",
            "memory_input_json is null"
        ));
    }

    json input;
    json parse_err;
    if (!parse_json_object_arg(memory_input_json, "memory_input_json", &input, &parse_err)) {
        return fail_memory_api(parse_err);
    }
    if (!enrich_execution_record_input(&input, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    std::lock_guard<std::mutex> lk(core_internal::g_memory_mu);
    json err;
    const json out = core_internal::ingest_memory_locked(input, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_memory_query(const char *query_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    if (query_json == nullptr) {
        return fail_memory_api(core_internal::make_error_json(
            "E_INPUT",
            "query_json is null"
        ));
    }

    json query;
    json parse_err;
    if (!parse_json_object_arg(query_json, "query_json", &query, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    std::lock_guard<std::mutex> lk(core_internal::g_memory_mu);
    json err;
    const json out = core_internal::query_memory_locked(query, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_memory_get(const char *memory_id) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    if (memory_id == nullptr) {
        return fail_memory_api(core_internal::make_error_json(
            "E_INPUT",
            "memory_id is null"
        ));
    }

    std::lock_guard<std::mutex> lk(core_internal::g_memory_mu);
    json err;
    const json out = core_internal::get_memory_locked(memory_id, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_memory_reset(void) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    std::lock_guard<std::mutex> lk(core_internal::g_memory_mu);
    json err;
    const json out = core_internal::reset_memory_store_locked(&err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }
    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_build_gpt_responses_request(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (!parse_json_object_arg(request_json, "request_json", &request, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    json err;
    const json out = core_internal::build_gpt_responses_request_via_rust(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }

    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_build_gpt_toolset(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (!parse_json_object_arg(request_json, "request_json", &request, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    json err;
    const json out = core_internal::build_gpt_toolset_via_rust(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }

    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_build_gpt_basic_abilities(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (!parse_json_object_arg(request_json, "request_json", &request, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    json err;
    const json out = core_internal::build_gpt_basic_abilities_via_rust(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }

    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_build_after_tool_use_hook_payload(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (!parse_json_object_arg(request_json, "request_json", &request, &parse_err)) {
        return fail_memory_api(parse_err);
    }

    json err;
    const json out = core_internal::build_after_tool_use_hook_payload_via_rust(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }

    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_render_skills_section(const char *request_json) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output.clear();

    json request;
    json parse_err;
    if (request_json == nullptr) {
        request = json::array();
    } else {
        try {
            request = json::parse(request_json);
        } catch (const std::exception &e) {
            return fail_memory_api(core_internal::make_error_json("E_PARSE", "request_json must be valid JSON", e.what()));
        }
    }

    json err;
    const json out = core_internal::render_skills_section_via_rust(request, &err);
    if (!err.is_null()) {
        return fail_memory_api(err);
    }

    core_internal::g_last_output = out.dump();
    return core_internal::g_last_output.c_str();
}

const char *agent_core_rust_runtime_version(void) {
    core_internal::g_last_error.clear();
    core_internal::g_last_output = json{
        {"status", "success"},
        {"runtime", "rust"},
        {"version", core_internal::rust_runtime_version()}
    }.dump();
    return core_internal::g_last_output.c_str();
}
