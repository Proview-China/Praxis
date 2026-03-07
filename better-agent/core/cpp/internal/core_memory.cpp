#include "agent_core_internal.hpp"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace better_agent::core_internal {

namespace {

namespace fs = std::filesystem;

struct ScoredMemoryResult {
    MemoryEntry entry;
    double score = 0.0;
    json reasons = json::array();
    bool is_expired = false;
};

std::string default_memory_store_path() {
    return (fs::temp_directory_path() / "better-agent-memory-store.json").string();
}

void ensure_memory_defaults_locked() {
    if (g_memory_config.store_path.empty()) {
        g_memory_config.store_path = default_memory_store_path();
    }
    if (g_memory_config.max_injection_entries == 0) {
        g_memory_config.max_injection_entries = 5;
    }
    if (g_memory_config.max_injection_chars == 0) {
        g_memory_config.max_injection_chars = 2000;
    }
}

bool is_valid_memory_layer(const std::string &layer) {
    return layer == "short_term" || layer == "task" || layer == "strategy";
}

std::string lower_copy(const std::string &value) {
    std::string out = value;
    std::transform(out.begin(), out.end(), out.begin(), [](const unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return out;
}

bool contains_case_insensitive(const std::string &haystack, const std::string &needle) {
    if (needle.empty()) {
        return true;
    }
    return lower_copy(haystack).find(lower_copy(needle)) != std::string::npos;
}

std::string json_to_compact_string(const json &value) {
    if (value.is_string()) {
        return value.get<std::string>();
    }
    if (value.is_null()) {
        return "";
    }
    return value.dump();
}

void merge_unique_strings(std::vector<std::string> *target, const std::vector<std::string> &incoming) {
    for (const auto &item : incoming) {
        if (item.empty()) {
            continue;
        }
        if (std::find(target->begin(), target->end(), item) == target->end()) {
            target->push_back(item);
        }
    }
}

void append_unique_evidence(json *target, const json &incoming) {
    if (!target->is_array()) {
        *target = json::array();
    }
    if (!incoming.is_array()) {
        return;
    }
    for (const auto &entry : incoming) {
        bool exists = false;
        for (const auto &existing : *target) {
            if (existing == entry) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            target->push_back(entry);
        }
    }
}

std::string iso8601_after_seconds(long long seconds_from_now) {
    const auto now = std::chrono::system_clock::now() + std::chrono::seconds(seconds_from_now);
    const auto tt = std::chrono::system_clock::to_time_t(now);
    std::tm tm {};
#if defined(_WIN32)
    gmtime_s(&tm, &tt);
#else
    gmtime_r(&tt, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
    return oss.str();
}

bool is_expired_memory(const MemoryEntry &entry) {
    return !entry.expires_at.empty() && entry.expires_at <= now_iso8601_utc();
}

bool scope_matches_query(const json &query_scope, const json &entry_scope) {
    if (!query_scope.is_object() || query_scope.empty()) {
        return true;
    }
    if (!entry_scope.is_object()) {
        return false;
    }
    for (auto it = query_scope.begin(); it != query_scope.end(); ++it) {
        if (!entry_scope.contains(it.key()) || entry_scope.at(it.key()) != it.value()) {
            return false;
        }
    }
    return true;
}

std::string infer_topic_from_execution_record(const json &record) {
    if (record.is_object() && record.contains("input_raw") && record.at("input_raw").is_object()) {
        const json &raw = record.at("input_raw");
        const std::string name = get_string_or(raw, "name");
        if (!name.empty()) {
            return name;
        }
        const std::string tool = get_string_or(raw, "tool");
        if (!tool.empty()) {
            return tool;
        }
    }
    const std::string intent = get_string_or(record, "intent");
    if (!intent.empty()) {
        return intent;
    }
    return "execution";
}

std::string summarize_execution_record(const json &record) {
    const std::string topic = infer_topic_from_execution_record(record);
    const std::string status = get_string_or(record, "status", "unknown");
    if (status == "success") {
        return "工具 " + topic + " 成功执行";
    }
    if (record.is_object() && record.contains("error") && record.at("error").is_object()) {
        return "工具 " + topic + " 执行失败: " + get_string_or(record.at("error"), "message", status);
    }
    return "工具 " + topic + " 执行状态: " + status;
}

json build_execution_record_evidence(const json &record) {
    json evidence = json::array();
    const std::string execution_id = get_string_or(record, "execution_id");
    if (!execution_id.empty()) {
        evidence.push_back(json{{"kind", "execution_id"}, {"value", execution_id}});
    }
    const std::string provider_kind = get_string_or(record, "provider_kind");
    if (!provider_kind.empty()) {
        evidence.push_back(json{{"kind", "provider_kind"}, {"value", provider_kind}});
    }
    const std::string tool_kind = get_string_or(record, "tool_kind");
    if (!tool_kind.empty()) {
        evidence.push_back(json{{"kind", "tool_kind"}, {"value", tool_kind}});
    }
    if (record.contains("evidence") && record.at("evidence").is_array()) {
        append_unique_evidence(&evidence, record.at("evidence"));
    }
    return evidence;
}

std::vector<std::string> json_array_to_strings(const json &value) {
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

bool query_layer_matches(const std::vector<std::string> &layers, const std::string &entry_layer) {
    if (layers.empty()) {
        return true;
    }
    return std::find(layers.begin(), layers.end(), entry_layer) != layers.end();
}

std::size_t approximate_memory_chars(const MemoryEntry &entry) {
    return entry.topic.size() + entry.summary.size() + json_to_compact_string(entry.scope).size();
}

std::string normalize_memory_status_for_query(const MemoryEntry &entry) {
    if (is_expired_memory(entry)) {
        return "expired";
    }
    return entry.status;
}

json make_memory_response(
    const std::string &status,
    const json &payload = json::object(),
    const json &error = nullptr
) {
    json out{{"status", status}};
    if (payload.is_object()) {
        for (auto it = payload.begin(); it != payload.end(); ++it) {
            out[it.key()] = it.value();
        }
    }
    if (!error.is_null()) {
        out["error"] = error;
    }
    return out;
}

MemoryEntry build_memory_entry_from_input(const json &input_json, json *err_out) {
    const std::string input_type = get_string_or(input_json, "input_type");
    if (input_type != "execution_record" && input_type != "conclusion") {
        *err_out = make_error_json(
            "E_MEMORY_INPUT",
            "input_type must be execution_record or conclusion",
            json{{"input_type", input_type}}
        );
        return MemoryEntry{};
    }

    MemoryEntry entry;
    entry.memory_id = next_id("memory");
    entry.kind = get_string_or(input_json, "kind", input_type);
    entry.layer = get_string_or(input_json, "layer", "task");
    entry.scope = input_json.value("scope", json::object());
    entry.source = input_json.value("source", json::object());
    entry.confidence = input_json.contains("confidence") && input_json.at("confidence").is_number()
        ? input_json.at("confidence").get<double>()
        : (input_type == "execution_record" ? 0.75 : 0.85);
    entry.confidence = std::clamp(entry.confidence, 0.0, 1.0);
    entry.created_at = now_iso8601_utc();
    entry.updated_at = entry.created_at;
    entry.status = "active";
    entry.supersedes = json_array_to_strings(input_json.value("supersedes", json::array()));
    entry.conflicts_with = json_array_to_strings(input_json.value("conflicts_with", json::array()));

    if (!is_valid_memory_layer(entry.layer)) {
        *err_out = make_error_json(
            "E_MEMORY_LAYER",
            "layer must be one of short_term, task, strategy",
            json{{"layer", entry.layer}}
        );
        return MemoryEntry{};
    }

    if (!entry.scope.is_object()) {
        *err_out = make_error_json("E_MEMORY_SCOPE", "scope must be a JSON object");
        return MemoryEntry{};
    }
    if (!entry.source.is_object()) {
        *err_out = make_error_json("E_MEMORY_SOURCE", "source must be a JSON object");
        return MemoryEntry{};
    }

    if (input_json.contains("ttl_seconds")) {
        if (!input_json.at("ttl_seconds").is_number_integer()) {
            *err_out = make_error_json("E_MEMORY_TTL", "ttl_seconds must be an integer");
            return MemoryEntry{};
        }
        entry.expires_at = iso8601_after_seconds(input_json.at("ttl_seconds").get<long long>());
    } else if (input_json.contains("expires_at") && input_json.at("expires_at").is_string()) {
        entry.expires_at = input_json.at("expires_at").get<std::string>();
    }

    if (input_type == "execution_record") {
        json record = input_json.value("record", json::object());
        if (!record.is_object() || record.empty()) {
            const std::string execution_id = get_string_or(input_json, "execution_id");
            if (execution_id.empty()) {
                *err_out = make_error_json(
                    "E_MEMORY_INPUT",
                    "execution_record input requires record or execution_id"
                );
                return MemoryEntry{};
            }
            std::lock_guard<std::mutex> exec_lk(g_tools_mu);
            if (!g_executions.contains(execution_id)) {
                *err_out = make_error_json(
                    "E_NOT_FOUND",
                    "execution record not found",
                    json{{"execution_id", execution_id}}
                );
                return MemoryEntry{};
            }
            record = serialize_execution_record(g_executions.at(execution_id));
        }

        entry.topic = get_string_or(input_json, "topic", infer_topic_from_execution_record(record));
        entry.summary = get_string_or(input_json, "summary", summarize_execution_record(record));
        entry.evidence = build_execution_record_evidence(record);
        append_unique_evidence(&entry.evidence, input_json.value("evidence", json::array()));
        entry.source["input_type"] = "execution_record";
        entry.source["execution_id"] = get_string_or(record, "execution_id");
    } else {
        entry.topic = get_string_or(input_json, "topic");
        entry.summary = get_string_or(input_json, "summary");
        entry.evidence = input_json.value("evidence", json::array());
        if (!entry.evidence.is_array()) {
            *err_out = make_error_json("E_MEMORY_EVIDENCE", "evidence must be an array");
            return MemoryEntry{};
        }
        if (entry.evidence.empty()) {
            entry.evidence.push_back(json{{"kind", "source_type"}, {"value", "conclusion"}});
        }
        entry.source["input_type"] = "conclusion";
    }

    if (entry.topic.empty()) {
        *err_out = make_error_json("E_MEMORY_TOPIC", "topic is required or could not be inferred");
        return MemoryEntry{};
    }
    if (entry.summary.empty()) {
        *err_out = make_error_json("E_MEMORY_SUMMARY", "summary is required or could not be inferred");
        return MemoryEntry{};
    }

    return entry;
}

std::string find_equivalent_memory_id_locked(const MemoryEntry &entry) {
    std::string latest_id;
    std::string latest_updated_at;
    for (const auto &memory_id : g_memory_order) {
        if (!g_memory_entries.contains(memory_id)) {
            continue;
        }
        const MemoryEntry &existing = g_memory_entries.at(memory_id);
        if (existing.topic == entry.topic &&
            existing.kind == entry.kind &&
            existing.layer == entry.layer &&
            existing.scope == entry.scope &&
            existing.status == "active") {
            if (existing.updated_at >= latest_updated_at) {
                latest_updated_at = existing.updated_at;
                latest_id = memory_id;
            }
        }
    }
    return latest_id;
}

void mark_related_entries_locked(
    const std::vector<std::string> &memory_ids,
    const std::string &new_status
) {
    for (const auto &memory_id : memory_ids) {
        if (!g_memory_entries.contains(memory_id)) {
            continue;
        }
        MemoryEntry &entry = g_memory_entries.at(memory_id);
        entry.status = new_status;
        entry.updated_at = now_iso8601_utc();
    }
}

json build_query_explanation_payload(
    const MemoryQuery &query,
    std::size_t max_entries,
    std::size_t max_chars
) {
    return json{
        {"intent", query.intent},
        {"topic", query.topic},
        {"layers", query.layers},
        {"scope", query.scope},
        {"include_expired", query.include_expired},
        {"include_conflicted", query.include_conflicted},
        {"include_superseded", query.include_superseded},
        {"max_entries", max_entries},
        {"max_chars", max_chars}
    };
}

} // namespace

void reset_memory_state_locked() {
    g_memory_config = MemoryConfig{};
    g_memory_entries.clear();
    g_memory_order.clear();
    g_memory_loaded = false;
}

json serialize_memory_config(const MemoryConfig &config) {
    return json{
        {"store_path", config.store_path},
        {"max_injection_entries", config.max_injection_entries},
        {"max_injection_chars", config.max_injection_chars}
    };
}

json serialize_memory_entry(const MemoryEntry &entry) {
    return json{
        {"memory_id", entry.memory_id},
        {"topic", entry.topic},
        {"kind", entry.kind},
        {"layer", entry.layer},
        {"scope", entry.scope},
        {"summary", entry.summary},
        {"evidence", entry.evidence},
        {"confidence", entry.confidence},
        {"created_at", entry.created_at},
        {"updated_at", entry.updated_at},
        {"expires_at", entry.expires_at.empty() ? json(nullptr) : json(entry.expires_at)},
        {"status", entry.status},
        {"supersedes", entry.supersedes},
        {"conflicts_with", entry.conflicts_with},
        {"source", entry.source}
    };
}

MemoryEntry deserialize_memory_entry(const json &obj) {
    MemoryEntry entry;
    entry.memory_id = get_string_or(obj, "memory_id");
    entry.topic = get_string_or(obj, "topic");
    entry.kind = get_string_or(obj, "kind", "conclusion");
    entry.layer = get_string_or(obj, "layer", "task");
    entry.scope = get_json_or(obj, "scope", json::object());
    entry.summary = get_string_or(obj, "summary");
    entry.evidence = get_json_or(obj, "evidence", json::array());
    entry.confidence = obj.contains("confidence") && obj.at("confidence").is_number()
        ? obj.at("confidence").get<double>()
        : 0.5;
    entry.created_at = get_string_or(obj, "created_at");
    entry.updated_at = get_string_or(obj, "updated_at");
    entry.expires_at = obj.contains("expires_at") && obj.at("expires_at").is_string()
        ? obj.at("expires_at").get<std::string>()
        : "";
    entry.status = get_string_or(obj, "status", "active");
    entry.supersedes = json_array_to_strings(obj.value("supersedes", json::array()));
    entry.conflicts_with = json_array_to_strings(obj.value("conflicts_with", json::array()));
    entry.source = get_json_or(obj, "source", json::object());
    return entry;
}

json serialize_memory_store_snapshot_locked() {
    ensure_memory_defaults_locked();
    json entries = json::array();
    for (const auto &memory_id : g_memory_order) {
        if (!g_memory_entries.contains(memory_id)) {
            continue;
        }
        entries.push_back(serialize_memory_entry(g_memory_entries.at(memory_id)));
    }
    return json{
        {"version", 1},
        {"config", serialize_memory_config(g_memory_config)},
        {"entries", entries}
    };
}

bool ensure_memory_store_loaded_locked(json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    ensure_memory_defaults_locked();
    if (g_memory_loaded) {
        return true;
    }

    g_memory_entries.clear();
    g_memory_order.clear();

    const fs::path store_path(g_memory_config.store_path);
    if (!fs::exists(store_path)) {
        g_memory_loaded = true;
        return true;
    }

    try {
        std::ifstream in(store_path);
        std::ostringstream buffer;
        buffer << in.rdbuf();
        const json document = json::parse(buffer.str());
        const json entries = document.value("entries", json::array());
        if (!entries.is_array()) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_STORE_PARSE", "memory store entries must be an array");
            }
            return false;
        }
        for (const auto &entry_json : entries) {
            if (!entry_json.is_object()) {
                continue;
            }
            MemoryEntry entry = deserialize_memory_entry(entry_json);
            if (entry.memory_id.empty()) {
                entry.memory_id = next_id("memory");
            }
            g_memory_entries[entry.memory_id] = entry;
            g_memory_order.push_back(entry.memory_id);
        }
        g_memory_loaded = true;
        return true;
    } catch (const std::exception &e) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_MEMORY_STORE_PARSE",
                "failed to load memory store",
                e.what()
            );
        }
        return false;
    }
}

bool persist_memory_store_locked(json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    ensure_memory_defaults_locked();
    try {
        const fs::path store_path(g_memory_config.store_path);
        if (!store_path.parent_path().empty()) {
            fs::create_directories(store_path.parent_path());
        }
        std::ofstream out(store_path);
        out << serialize_memory_store_snapshot_locked().dump(2);
        return true;
    } catch (const std::exception &e) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_MEMORY_STORE_WRITE",
                "failed to persist memory store",
                e.what()
            );
        }
        return false;
    }
}

json configure_memory_locked(const json &config_json, json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }

    ensure_memory_defaults_locked();
    const std::string previous_store_path = g_memory_config.store_path;
    if (config_json.contains("store_path")) {
        if (!config_json.at("store_path").is_string()) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_CONFIG", "store_path must be a string");
            }
            return json::object();
        }
        g_memory_config.store_path = config_json.at("store_path").get<std::string>();
    }
    if (config_json.contains("max_injection_entries")) {
        if (!config_json.at("max_injection_entries").is_number_integer()) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_CONFIG", "max_injection_entries must be an integer");
            }
            return json::object();
        }
        const auto value = config_json.at("max_injection_entries").get<long long>();
        if (value <= 0) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_CONFIG", "max_injection_entries must be positive");
            }
            return json::object();
        }
        g_memory_config.max_injection_entries = static_cast<std::size_t>(value);
    }
    if (config_json.contains("max_injection_chars")) {
        if (!config_json.at("max_injection_chars").is_number_integer()) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_CONFIG", "max_injection_chars must be an integer");
            }
            return json::object();
        }
        const auto value = config_json.at("max_injection_chars").get<long long>();
        if (value <= 0) {
            if (err_out != nullptr) {
                *err_out = make_error_json("E_MEMORY_CONFIG", "max_injection_chars must be positive");
            }
            return json::object();
        }
        g_memory_config.max_injection_chars = static_cast<std::size_t>(value);
    }

    if (g_memory_config.store_path != previous_store_path) {
        g_memory_entries.clear();
        g_memory_order.clear();
        g_memory_loaded = false;
    }

    if (!ensure_memory_store_loaded_locked(err_out)) {
        return json::object();
    }

    return make_memory_response(
        "success",
        json{
            {"config", serialize_memory_config(g_memory_config)},
            {"loaded_count", g_memory_entries.size()}
        }
    );
}

json ingest_memory_locked(const json &input_json, json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    if (!ensure_memory_store_loaded_locked(err_out)) {
        return json::object();
    }

    MemoryEntry candidate = build_memory_entry_from_input(input_json, err_out);
    if (err_out != nullptr && !err_out->is_null()) {
        return json::object();
    }

    const std::string equivalent_id = find_equivalent_memory_id_locked(candidate);
    std::string action = "created";

    if (!equivalent_id.empty() && g_memory_entries.contains(equivalent_id)) {
        MemoryEntry &existing = g_memory_entries.at(equivalent_id);
        if (existing.summary == candidate.summary) {
            append_unique_evidence(&existing.evidence, candidate.evidence);
            existing.updated_at = now_iso8601_utc();
            existing.confidence = std::max(existing.confidence, candidate.confidence);
            if (!candidate.expires_at.empty()) {
                existing.expires_at = candidate.expires_at;
            }
            existing.source["last_ingest"] = candidate.source;
            candidate = existing;
            action = "updated";
        } else {
            const bool mark_conflict = input_json.value("mark_conflict", false);
            existing.status = mark_conflict ? "conflicted" : "superseded";
            existing.updated_at = now_iso8601_utc();
            if (mark_conflict) {
                merge_unique_strings(&candidate.conflicts_with, std::vector<std::string>{existing.memory_id});
                action = "created_conflict";
            } else {
                merge_unique_strings(&candidate.supersedes, std::vector<std::string>{existing.memory_id});
                action = "created_superseding";
            }
            g_memory_entries[candidate.memory_id] = candidate;
            g_memory_order.push_back(candidate.memory_id);
        }
    } else {
        g_memory_entries[candidate.memory_id] = candidate;
        g_memory_order.push_back(candidate.memory_id);
    }

    if (!candidate.supersedes.empty()) {
        mark_related_entries_locked(candidate.supersedes, "superseded");
    }
    if (!candidate.conflicts_with.empty()) {
        mark_related_entries_locked(candidate.conflicts_with, "conflicted");
    }

    if (!persist_memory_store_locked(err_out)) {
        return json::object();
    }

    const MemoryEntry &stored = g_memory_entries.at(candidate.memory_id);
    return make_memory_response(
        "success",
        json{
            {"action", action},
            {"memory", serialize_memory_entry(stored)},
            {"store", json{
                {"path", g_memory_config.store_path},
                {"entry_count", g_memory_entries.size()}
            }}
        }
    );
}

json query_memory_locked(const json &query_json, json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    if (!ensure_memory_store_loaded_locked(err_out)) {
        return json::object();
    }

    MemoryQuery query;
    query.intent = get_string_or(query_json, "intent");
    query.topic = get_string_or(query_json, "topic");
    query.layers = json_string_array_to_vector(query_json.value("layers", json::array()));
    query.scope = query_json.value("scope", json::object());
    query.include_expired = query_json.value("include_expired", false);
    query.include_conflicted = query_json.value("include_conflicted", false);
    query.include_superseded = query_json.value("include_superseded", false);

    if (!query.scope.is_object()) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_MEMORY_QUERY", "scope must be a JSON object");
        }
        return json::object();
    }

    const std::size_t max_entries = query_json.contains("max_entries") && query_json.at("max_entries").is_number_integer()
        ? static_cast<std::size_t>(std::max<long long>(1, query_json.at("max_entries").get<long long>()))
        : g_memory_config.max_injection_entries;
    const std::size_t max_chars = query_json.contains("max_chars") && query_json.at("max_chars").is_number_integer()
        ? static_cast<std::size_t>(std::max<long long>(1, query_json.at("max_chars").get<long long>()))
        : g_memory_config.max_injection_chars;

    std::vector<ScoredMemoryResult> candidates;
    for (const auto &memory_id : g_memory_order) {
        if (!g_memory_entries.contains(memory_id)) {
            continue;
        }
        const MemoryEntry &entry = g_memory_entries.at(memory_id);
        const bool expired = is_expired_memory(entry);
        const std::string normalized_status = normalize_memory_status_for_query(entry);
        if (expired && !query.include_expired) {
            continue;
        }
        if (entry.status == "conflicted" && !query.include_conflicted) {
            continue;
        }
        if (entry.status == "superseded" && !query.include_superseded) {
            continue;
        }
        if (!query_layer_matches(query.layers, entry.layer)) {
            continue;
        }
        if (!scope_matches_query(query.scope, entry.scope)) {
            continue;
        }

        ScoredMemoryResult scored{.entry = entry, .score = 0.0, .reasons = json::array(), .is_expired = expired};
        if (!query.topic.empty()) {
            if (entry.topic == query.topic) {
                scored.score += 100.0;
                scored.reasons.push_back("topic exact match");
            } else if (contains_case_insensitive(entry.topic, query.topic) ||
                contains_case_insensitive(entry.summary, query.topic)) {
                scored.score += 45.0;
                scored.reasons.push_back("topic fuzzy match");
            } else {
                continue;
            }
        }

        if (!query.intent.empty()) {
            if (contains_case_insensitive(entry.summary, query.intent) ||
                contains_case_insensitive(entry.topic, query.intent) ||
                contains_case_insensitive(json_to_compact_string(entry.scope), query.intent)) {
                scored.score += 35.0;
                scored.reasons.push_back("intent match");
            } else if (query.topic.empty()) {
                continue;
            }
        }

        if (!query.layers.empty()) {
            scored.score += 10.0;
            scored.reasons.push_back("layer matched");
        }
        if (query.scope.is_object() && !query.scope.empty()) {
            scored.score += 20.0;
            scored.reasons.push_back("scope matched");
        }
        if (!expired) {
            scored.score += 10.0;
            scored.reasons.push_back("entry is fresh");
        } else {
            scored.reasons.push_back("entry expired");
        }
        if (normalized_status == "conflicted") {
            scored.score -= 25.0;
            scored.reasons.push_back("conflicted entry");
        }
        scored.score += scored.entry.confidence * 20.0;
        scored.reasons.push_back("confidence=" + std::to_string(scored.entry.confidence));
        candidates.push_back(scored);
    }

    std::sort(candidates.begin(), candidates.end(), [](const ScoredMemoryResult &lhs, const ScoredMemoryResult &rhs) {
        if (lhs.score != rhs.score) {
            return lhs.score > rhs.score;
        }
        return lhs.entry.updated_at > rhs.entry.updated_at;
    });

    json results = json::array();
    json injection_entries = json::array();
    std::size_t used_chars = 0;
    std::size_t accepted = 0;
    bool truncated = false;

    for (const auto &candidate : candidates) {
        const std::size_t entry_chars = approximate_memory_chars(candidate.entry);
        if (accepted >= max_entries || used_chars + entry_chars > max_chars) {
            truncated = true;
            continue;
        }
        used_chars += entry_chars;
        ++accepted;
        results.push_back(json{
            {"memory", serialize_memory_entry(candidate.entry)},
            {"score", candidate.score},
            {"reasons", candidate.reasons},
            {"is_expired", candidate.is_expired}
        });
        injection_entries.push_back(serialize_memory_entry(candidate.entry));
    }

    return make_memory_response(
        "success",
        json{
            {"query", build_query_explanation_payload(query, max_entries, max_chars)},
            {"total_matches", candidates.size()},
            {"returned_matches", results.size()},
            {"results", results},
            {"injection", json{
                {"entries", injection_entries},
                {"truncated", truncated},
                {"entry_limit", max_entries},
                {"char_limit", max_chars},
                {"used_chars", used_chars},
                {"omitted_count", candidates.size() >= accepted ? candidates.size() - accepted : 0}
            }}
        }
    );
}

json get_memory_locked(const std::string &memory_id, json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    if (!ensure_memory_store_loaded_locked(err_out)) {
        return json::object();
    }
    if (memory_id.empty()) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_INPUT", "memory_id is empty");
        }
        return json::object();
    }
    if (!g_memory_entries.contains(memory_id)) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_NOT_FOUND",
                "memory entry not found",
                json{{"memory_id", memory_id}}
            );
        }
        return json::object();
    }
    const MemoryEntry &entry = g_memory_entries.at(memory_id);
    return make_memory_response(
        "success",
        json{
            {"memory", serialize_memory_entry(entry)},
            {"is_expired", is_expired_memory(entry)}
        }
    );
}

json reset_memory_store_locked(json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }
    if (!ensure_memory_store_loaded_locked(err_out)) {
        return json::object();
    }

    const std::size_t cleared_count = g_memory_entries.size();
    g_memory_entries.clear();
    g_memory_order.clear();
    g_memory_loaded = true;

    if (!persist_memory_store_locked(err_out)) {
        return json::object();
    }

    return make_memory_response(
        "success",
        json{
            {"cleared_count", cleared_count},
            {"config", serialize_memory_config(g_memory_config)}
        }
    );
}

} // namespace better_agent::core_internal
