#include "agent_core_internal.hpp"
#include "core_rust_bridge.hpp"

namespace better_agent::core_internal {

std::string get_string_or(const json &obj, const char *key, const std::string &fallback) {
    if (!obj.is_object() || !obj.contains(key) || !obj.at(key).is_string()) {
        return fallback;
    }
    return obj.at(key).get<std::string>();
}

json get_json_or(const json &obj, const char *key, const json &fallback) {
    if (!obj.is_object() || !obj.contains(key)) {
        return fallback;
    }
    return obj.at(key);
}

std::vector<std::string> json_string_array_to_vector(const json &value) {
    std::vector<std::string> out;
    if (!value.is_array()) {
        return out;
    }
    for (const auto &entry : value) {
        if (entry.is_string()) {
            out.push_back(entry.get<std::string>());
        }
    }
    return out;
}

PolicyView build_policy_view(const json &policy) {
    json err;
    const json built = build_policy_view_via_rust(policy, &err);
    if (!err.is_null()) {
        return PolicyView{
            .raw_json = policy,
            .allow_tools = json_string_array_to_vector(policy.value("allow_tools", json::array())),
            .deny_tools = json_string_array_to_vector(policy.value("deny_tools", json::array())),
            .execution_id = policy.value("execution_id", ""),
            .timeout_ms = policy.value("timeout_ms", static_cast<std::uint64_t>(0)),
            .network_access = policy.value("network_access", false),
            .max_stdout_bytes = policy.value("max_stdout_bytes", static_cast<std::size_t>(0)),
            .max_stderr_bytes = policy.value("max_stderr_bytes", static_cast<std::size_t>(0)),
            .max_artifacts = policy.value("max_artifacts", static_cast<std::size_t>(0)),
            .require_network = policy.value("requires_network", false),
            .cpu_limit = policy.value("cpu_limit", json(nullptr)),
            .memory_limit = policy.value("memory_limit", json(nullptr))
        };
    }
    return PolicyView{
        .raw_json = built.value("raw_json", policy),
        .allow_tools = json_string_array_to_vector(built.value("allow_tools", json::array())),
        .deny_tools = json_string_array_to_vector(built.value("deny_tools", json::array())),
        .execution_id = built.value("execution_id", std::string()),
        .timeout_ms = built.value("timeout_ms", static_cast<std::uint64_t>(0)),
        .network_access = built.value("network_access", false),
        .max_stdout_bytes = static_cast<std::size_t>(built.value("max_stdout_bytes", static_cast<std::uint64_t>(0))),
        .max_stderr_bytes = static_cast<std::size_t>(built.value("max_stderr_bytes", static_cast<std::uint64_t>(0))),
        .max_artifacts = static_cast<std::size_t>(built.value("max_artifacts", static_cast<std::uint64_t>(0))),
        .require_network = built.value("require_network", false),
        .cpu_limit = built.value("cpu_limit", json(nullptr)),
        .memory_limit = built.value("memory_limit", json(nullptr))
    };
}

json serialize_normalized_call(const NormalizedCall &call) {
    return json{
        {"provider_kind", call.provider_kind},
        {"tool_name", call.tool_name},
        {"intent", call.intent},
        {"input_raw", call.input_raw},
        {"input_normalized", call.input_normalized},
        {"provider_call_id", call.provider_call_id}
    };
}

json serialize_execution_record(const ExecutionRecord &record) {
    return json{
        {"execution_id", record.execution_id},
        {"tool_kind", record.tool_kind},
        {"provider_kind", record.provider_kind},
        {"intent", record.intent},
        {"provider_call_id", record.provider_call_id},
        {"input_raw", record.input_raw},
        {"input_normalized", record.input_normalized},
        {"policy_snapshot", record.policy_snapshot},
        {"status", record.status},
        {"evidence", record.evidence},
        {"error", record.error},
        {"handoff", record.handoff},
        {"timestamp", record.timestamp},
        {"result", record.result}
    };
}

ExecutionRecord deserialize_execution_record(const json &obj) {
    ExecutionRecord record;
    record.execution_id = get_string_or(obj, "execution_id");
    record.tool_kind = get_string_or(obj, "tool_kind", "function");
    record.provider_kind = get_string_or(obj, "provider_kind", "custom");
    record.intent = get_string_or(obj, "intent");
    record.provider_call_id = get_string_or(obj, "provider_call_id");
    record.input_raw = get_json_or(obj, "input_raw", json::object());
    record.input_normalized = get_json_or(obj, "input_normalized", json::object());
    record.policy_snapshot = get_json_or(obj, "policy_snapshot", json::object());
    record.status = get_string_or(obj, "status", "failed");
    record.evidence = get_json_or(obj, "evidence", json::array());
    record.error = get_json_or(obj, "error", nullptr);
    record.handoff = get_string_or(obj, "handoff");
    record.timestamp = get_string_or(obj, "timestamp");
    record.result = get_json_or(obj, "result", json::object());
    return record;
}

json serialize_runtime_event_record(const RuntimeEventRecord &record) {
    return json{
        {"execution_id", record.execution_id},
        {"source", record.source},
        {"event_type", record.event_type},
        {"tool_kind", record.tool_kind},
        {"intent", record.intent},
        {"input_raw", record.input_raw},
        {"input_normalized", record.input_normalized},
        {"policy_snapshot", record.policy_snapshot},
        {"status", record.status},
        {"evidence", record.evidence},
        {"error", record.error},
        {"handoff", record.handoff},
        {"timestamp", record.timestamp}
    };
}

std::string default_handoff(const std::string &status) {
    if (status == "failed" || status == "blocked" || status == "timeout" || status == "interrupted") {
        return "retry_or_manual_takeover";
    }
    if (status == "running" || status == "partial" || status == "queued") {
        return "continue_observing";
    }
    return "continue";
}

json make_error_json(
    const std::string &error_code,
    const std::string &message,
    const json &detail
) {
    json err{
        {"error_code", error_code},
        {"message", message}
    };
    if (!detail.is_null()) {
        err["detail"] = detail;
    }
    return err;
}

bool fail_function_call(const json &err, const std::string &status, const std::string &tool_name) {
    g_last_error = err.dump();
    json out{
        {"status", status},
        {"error", err}
    };
    if (!tool_name.empty()) {
        out["tool_name"] = tool_name;
    }
    g_last_output = out.dump();
    return false;
}

json parse_optional_object_json(const char *json_text) {
    if (json_text == nullptr) {
        return json::object();
    }
    const json parsed = json::parse(json_text, nullptr, false);
    return parsed.is_object() ? parsed : json::object();
}

} // namespace better_agent::core_internal
