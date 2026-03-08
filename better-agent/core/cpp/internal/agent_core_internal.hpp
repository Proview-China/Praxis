#ifndef BETTER_AGENT_CORE_INTERNAL_HPP
#define BETTER_AGENT_CORE_INTERNAL_HPP

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "nlohmann/json.hpp"

namespace better_agent::core_internal {

using json = nlohmann::json;

struct ToolSpec {
    std::string name;
    std::string description;
    json parameters;
    json constraints;
};

enum class ExecutorKind {
    Mock,
    Builtin,
    Native,
};

struct ToolRegistration {
    ToolSpec spec;
    std::string tool_kind = "function";
    ExecutorKind executor_kind = ExecutorKind::Mock;
    std::string executor_target;
    json mock_result;
};

struct NormalizedCall {
    std::string provider_kind = "custom";
    std::string tool_name;
    std::string intent;
    std::string provider_call_id;
    json input_raw = json::object();
    json input_normalized = json::object();
};

struct PolicyView {
    json raw_json = json::object();
    std::vector<std::string> allow_tools;
    std::vector<std::string> deny_tools;
    std::string execution_id;
    std::uint64_t timeout_ms = 0;
    bool network_access = false;
    std::size_t max_stdout_bytes = 0;
    std::size_t max_stderr_bytes = 0;
    std::size_t max_artifacts = 0;
    bool require_network = false;
    json cpu_limit = nullptr;
    json memory_limit = nullptr;
};

struct ToolExecutionRequest {
    std::string execution_id;
    std::string tool_name;
    std::string tool_kind = "function";
    std::string provider_kind;
    std::string intent;
    std::string provider_call_id;
    json args = json::object();
    json policy = json::object();
};

struct ToolExecutionResult {
    std::string status = "success";
    json result = json::object();
    json error = nullptr;
    json evidence = json::array();
    std::string handoff = "continue";
};

struct ExecutionRecord {
    std::string execution_id;
    std::string tool_kind = "function";
    std::string provider_kind = "custom";
    std::string intent;
    std::string provider_call_id;
    json input_raw = json::object();
    json input_normalized = json::object();
    json policy_snapshot = json::object();
    std::string status = "failed";
    json evidence = json::array();
    json error = nullptr;
    std::string handoff;
    std::string timestamp;
    json result = json::object();
};

struct RuntimeEventRecord {
    std::string execution_id;
    std::string source = "unknown";
    std::string event_type = "unknown";
    std::string tool_kind = "function";
    json intent = nullptr;
    json input_raw = json::object();
    json input_normalized = json::object();
    json policy_snapshot = json::object();
    std::string status = "partial";
    json evidence = json::array();
    json error = nullptr;
    std::string handoff = "continue_observing";
    std::string timestamp;
};

struct MemoryConfig {
    std::string store_path;
    std::size_t max_injection_entries = 5;
    std::size_t max_injection_chars = 2000;
};

struct MemoryEntry {
    std::string memory_id;
    std::string topic;
    std::string kind = "conclusion";
    std::string layer = "task";
    json scope = json::object();
    std::string summary;
    json evidence = json::array();
    double confidence = 0.5;
    std::string created_at;
    std::string updated_at;
    std::string expires_at;
    std::string status = "active";
    std::vector<std::string> supersedes;
    std::vector<std::string> conflicts_with;
    json source = json::object();
};

struct MemoryQuery {
    std::string intent;
    std::string topic;
    std::vector<std::string> layers;
    json scope = json::object();
    bool include_expired = false;
    bool include_conflicted = false;
    bool include_superseded = false;
    std::size_t max_entries = 0;
    std::size_t max_chars = 0;
};

extern std::atomic<unsigned long long> g_seq;
extern thread_local std::string g_last_error;
extern thread_local std::string g_last_output;
extern std::mutex g_tools_mu;
extern std::mutex g_memory_mu;
extern std::mutex g_sandbox_mu;
extern std::unordered_map<std::string, ToolRegistration> g_tools;
extern std::unordered_map<std::string, ExecutionRecord> g_executions;
extern json g_sandbox_capability_cache;
extern bool g_sandbox_capability_cache_valid;
extern MemoryConfig g_memory_config;
extern std::unordered_map<std::string, MemoryEntry> g_memory_entries;
extern std::vector<std::string> g_memory_order;
extern bool g_memory_loaded;

std::string now_iso8601_utc();
std::string next_id(const std::string &prefix);

std::string get_string_or(const json &obj, const char *key, const std::string &fallback = "");
json get_json_or(const json &obj, const char *key, const json &fallback = json());
std::vector<std::string> json_string_array_to_vector(const json &value);
PolicyView build_policy_view(const json &policy);

json serialize_normalized_call(const NormalizedCall &call);
json serialize_execution_record(const ExecutionRecord &record);
ExecutionRecord deserialize_execution_record(const json &obj);
json serialize_runtime_event_record(const RuntimeEventRecord &record);

std::string default_handoff(const std::string &status);
bool fail_function_call(const json &err, const std::string &status = "failed", const std::string &tool_name = "");
json parse_optional_object_json(const char *json_text);

bool parse_tool_registration_json(const char *tool_definition_json, ToolRegistration *tool_out);

json make_error_json(
    const std::string &error_code,
    const std::string &message,
    const json &detail = nullptr
);
json get_sandbox_capabilities_locked(const json &request_json, json *err_out);

void reset_memory_state_locked();
json serialize_memory_config(const MemoryConfig &config);
json serialize_memory_entry(const MemoryEntry &entry);
MemoryEntry deserialize_memory_entry(const json &obj);
json serialize_memory_store_snapshot_locked();
bool ensure_memory_store_loaded_locked(json *err_out);
bool persist_memory_store_locked(json *err_out);
json configure_memory_locked(const json &config_json, json *err_out);
json ingest_memory_locked(const json &input_json, json *err_out);
json query_memory_locked(const json &query_json, json *err_out);
json get_memory_locked(const std::string &memory_id, json *err_out);
json reset_memory_store_locked(json *err_out);
std::string rust_runtime_version();
json build_gpt_responses_request_via_rust(const json &request_json, json *err_out);

} // namespace better_agent::core_internal

#endif // BETTER_AGENT_CORE_INTERNAL_HPP
