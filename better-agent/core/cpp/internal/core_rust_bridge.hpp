#ifndef BETTER_AGENT_CORE_RUST_BRIDGE_HPP
#define BETTER_AGENT_CORE_RUST_BRIDGE_HPP

#include <string>

#include "nlohmann/json.hpp"

namespace better_agent::core_internal {

using json = nlohmann::json;

std::string rust_runtime_version();
json parse_tool_definition_via_rust(const json &request_json, json *err_out);
json parse_policy_json_via_rust(const char *policy_json, json *err_out);
json prepare_function_call_request_via_rust(const json &request_json, json *err_out);
json build_policy_view_via_rust(const json &request_json, json *err_out);
json normalize_runtime_event_via_rust(const json &request_json, json *err_out);
json schema_validate_args_via_rust(const json &request_json, json *err_out);
json validate_tool_call_policy_via_rust(const json &request_json, json *err_out);
json build_tool_execution_request_via_rust(const json &request_json, json *err_out);
json build_execution_record_via_rust(const json &request_json, json *err_out);
json resolve_mock_result_via_rust(const json &request_json, json *err_out);
json build_mock_execution_result_via_rust(const json &request_json, json *err_out);
std::string resolve_executor_target_via_rust(const json &request_json, json *err_out);
json builtin_executor_missing_via_rust(const json &request_json, json *err_out);
json native_executor_unavailable_via_rust(const json &request_json, json *err_out);
std::string extract_provider_call_id_via_rust(const json &record, json *err_out);
std::string extract_tool_name_from_record_via_rust(const json &record, json *err_out);
json build_gpt_responses_request_via_rust(const json &request_json, json *err_out);
json build_gpt_toolset_via_rust(const json &request_json, json *err_out);
json build_gpt_basic_abilities_via_rust(const json &request_json, json *err_out);
json build_after_tool_use_hook_payload_via_rust(const json &request_json, json *err_out);
json render_skills_section_via_rust(const json &request_json, json *err_out);
json build_openai_function_call_output_payload_via_rust(const json &request_json, json *err_out);
json build_openai_bridge_outputs_via_rust(const json &request_json, json *err_out);
json build_claude_tool_result_payload_via_rust(const json &request_json, json *err_out);
json build_provider_execution_wrapper_via_rust(const json &request_json, json *err_out);
json build_openai_request_from_execution_via_rust(const json &request_json, json *err_out);

} // namespace better_agent::core_internal

#endif // BETTER_AGENT_CORE_RUST_BRIDGE_HPP
