#include "agent_core.h"
#include "test_helpers.hpp"

int main() {
    using better_agent::tests::expect;
    using better_agent::tests::expect_execution_record_contract;
    using better_agent::tests::parse_json;

    expect(agent_core_init() == 0, "agent_core_init should succeed");

    const char *function_tool = R"({
      "name":"sum_numbers",
      "description":"sum two integers",
      "parameters":{
        "type":"object",
        "properties":{"a":{"type":"integer"},"b":{"type":"integer"}},
        "required":["a","b"],
        "additionalProperties":false
      },
      "mock_result":{"sum":3}
    })";
    expect(agent_core_register_tool(function_tool) == 0, "function tool registration should succeed");

    const char *custom_tool = R"({
      "name":"custom_lookup",
      "description":"custom lookup tool",
      "parameters":{
        "type":"object",
        "properties":{"uid":{"type":"string"}},
        "required":["uid"],
        "additionalProperties":false
      },
      "mock_result":{"name":"Alice"}
    })";
    expect(agent_core_register_tool(custom_tool) == 0, "custom tool registration should succeed");

    auto openai = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"sum_numbers","intent":"math_request","call_id":"fc_norm_1","arguments":"{\"a\":1,\"b\":2}"})",
        R"({"allow_tools":["sum_numbers"]})"
    ));
    expect_execution_record_contract(openai);
    expect(openai.at("provider_kind") == "openai", "openai provider_kind mismatch");
    expect(openai.at("intent") == "math_request", "openai intent mismatch");
    expect(openai.at("provider_call_id") == "fc_norm_1", "openai provider_call_id mismatch");
    expect(openai.at("input_normalized").at("a") == 1, "openai normalized arg a mismatch");
    expect(openai.at("input_normalized").at("b") == 2, "openai normalized arg b mismatch");

    auto claude = parse_json(agent_core_execute_function_call(
        R"({"type":"tool_use","id":"toolu_norm_1","name":"sum_numbers","intent":"tool_math","input":{"a":3,"b":4}})",
        R"({"allow_tools":["sum_numbers"]})"
    ));
    expect_execution_record_contract(claude);
    expect(claude.at("provider_kind") == "claude", "claude provider_kind mismatch");
    expect(claude.at("intent") == "tool_math", "claude intent mismatch");
    expect(claude.at("provider_call_id") == "toolu_norm_1", "claude provider_call_id mismatch");
    expect(claude.at("input_normalized").at("a") == 3, "claude normalized arg a mismatch");
    expect(claude.at("input_normalized").at("b") == 4, "claude normalized arg b mismatch");

    auto custom = parse_json(agent_core_execute_function_call(
        R"({"tool":"custom_lookup","intent":"directory_lookup","call_id":"custom_norm_1","arguments":{"uid":"u-1"}})",
        R"({"allow_tools":["custom_lookup"]})"
    ));
    expect_execution_record_contract(custom);
    expect(custom.at("provider_kind") == "custom", "custom provider_kind mismatch");
    expect(custom.at("intent") == "directory_lookup", "custom intent mismatch");
    expect(custom.at("provider_call_id") == "custom_norm_1", "custom provider_call_id mismatch");
    expect(custom.at("input_normalized").at("uid") == "u-1", "custom normalized arg mismatch");

    auto empty_name = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"","arguments":"{}"})",
        R"({"allow_tools":["sum_numbers"]})"
    ));
    expect(empty_name.at("status") == "failed", "empty tool name should fail");
    expect(empty_name.at("error").at("error_code") == "E_PARSE", "empty tool name error mismatch");

    auto invalid_openai_args = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"sum_numbers","arguments":"{"})",
        R"({"allow_tools":["sum_numbers"]})"
    ));
    expect(invalid_openai_args.at("status") == "failed", "invalid openai args should fail");
    expect(invalid_openai_args.at("error").at("error_code") == "E_PARSE", "invalid openai args error mismatch");

    auto unsupported_payload = parse_json(agent_core_execute_function_call(
        R"({"kind":"unknown"})",
        R"({"allow_tools":["sum_numbers"]})"
    ));
    expect(unsupported_payload.at("status") == "failed", "unsupported payload should fail");
    expect(unsupported_payload.at("error").at("error_code") == "E_PARSE", "unsupported payload error mismatch");

    agent_core_shutdown();
    std::cout << "function_call_normalization_test: PASS\n";
    return 0;
}
