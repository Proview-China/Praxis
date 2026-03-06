#include "agent_core.h"
#include "test_helpers.hpp"

int main() {
    using better_agent::tests::expect;
    using better_agent::tests::parse_json;

    expect(agent_core_init() == 0, "agent_core_init should succeed");

    const char *tool = R"({
      "name":"lookup_weather",
      "description":"weather tool",
      "parameters":{
        "type":"object",
        "properties":{"city":{"type":"string"}},
        "required":["city"],
        "additionalProperties":false
      },
      "mock_result":{"temp_c":25}
    })";
    expect(agent_core_register_tool(tool) == 0, "tool registration should succeed");

    auto null_model = parse_json(agent_core_execute_function_call(nullptr, nullptr));
    expect(null_model.at("status") == "failed", "null model input should fail");
    expect(null_model.at("error").at("error_code") == "E_INPUT", "null model input error mismatch");

    auto invalid_policy = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"lookup_weather","arguments":"{\"city\":\"Shanghai\"}"})",
        R"([])"
    ));
    expect(invalid_policy.at("status") == "failed", "non-object policy should fail");
    expect(invalid_policy.at("error").at("error_code") == "E_POLICY_PARSE", "policy parse error mismatch");

    auto invalid_args_json = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"lookup_weather","arguments":"{"})",
        R"({"allow_tools":["lookup_weather"]})"
    ));
    expect(invalid_args_json.at("status") == "failed", "invalid arguments JSON should fail");
    expect(invalid_args_json.at("error").at("error_code") == "E_PARSE", "invalid arguments error mismatch");

    auto unsupported_payload = parse_json(agent_core_execute_function_call(
        R"({"name":"lookup_weather"})",
        R"({"allow_tools":["lookup_weather"]})"
    ));
    expect(unsupported_payload.at("status") == "failed", "unsupported payload should fail");
    expect(unsupported_payload.at("error").at("error_code") == "E_PARSE", "unsupported payload error mismatch");

    auto allow_blocked = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"lookup_weather","arguments":"{\"city\":\"Shanghai\"}"})",
        R"({"allow_tools":["other_tool"]})"
    ));
    expect(allow_blocked.at("status") == "blocked", "allow_tools mismatch should block");
    expect(allow_blocked.at("error").at("error_code") == "E_POLICY_DENY", "allow_tools mismatch error mismatch");

    auto missing_execution = parse_json(agent_core_get_execution("missing-exec"));
    expect(missing_execution.at("status") == "failed", "missing execution lookup should fail");
    expect(missing_execution.at("error").at("error_code") == "E_NOT_FOUND", "missing execution error mismatch");

    auto missing_openai_payload = parse_json(agent_core_build_openai_function_call_output("missing-exec", nullptr));
    expect(missing_openai_payload.at("status") == "failed", "missing openai payload lookup should fail");
    expect(missing_openai_payload.at("error").at("error_code") == "E_NOT_FOUND", "missing openai payload error mismatch");

    auto missing_claude_payload = parse_json(agent_core_build_claude_tool_result("missing-exec", nullptr));
    expect(missing_claude_payload.at("status") == "failed", "missing claude payload lookup should fail");
    expect(missing_claude_payload.at("error").at("error_code") == "E_NOT_FOUND", "missing claude payload error mismatch");

    agent_core_shutdown();
    std::cout << "execution_error_regressions_test: PASS\n";
    return 0;
}
