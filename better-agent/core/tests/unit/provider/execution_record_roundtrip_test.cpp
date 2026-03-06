#include "agent_core.h"
#include "test_helpers.hpp"

int main() {
    using better_agent::tests::expect;
    using better_agent::tests::expect_execution_record_contract;
    using better_agent::tests::parse_json;

    expect(agent_core_init() == 0, "agent_core_init should succeed");

    const char *tool = R"({
      "name":"lookup_profile",
      "description":"lookup profile",
      "parameters":{
        "type":"object",
        "properties":{"uid":{"type":"string"}},
        "required":["uid"],
        "additionalProperties":false
      },
      "mock_result":{"name":"Alice","tier":"pro"}
    })";
    expect(agent_core_register_tool(tool) == 0, "tool registration should succeed");

    auto first = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"lookup_profile","arguments":"{\"uid\":\"u-1\"}"})",
        R"({"allow_tools":["lookup_profile"],"idempotency_key":"roundtrip-1"})"
    ));
    expect_execution_record_contract(first);

    const auto execution_id = first.at("execution_id").get<std::string>();
    auto loaded = parse_json(agent_core_get_execution(execution_id.c_str()));
    expect_execution_record_contract(loaded);
    expect(loaded == first, "stored execution should match direct execution result");

    auto replay = parse_json(agent_core_execute_function_call(
        R"({"type":"function_call","name":"lookup_profile","arguments":"{\"uid\":\"u-1\"}"})",
        R"({"allow_tools":["lookup_profile"],"idempotency_key":"roundtrip-1"})"
    ));
    expect_execution_record_contract(replay);
    expect(replay.at("handoff") == "idempotency-hit: reuse previous execution", "replay handoff mismatch");
    replay["handoff"] = "continue";
    expect(replay == first, "idempotent replay should match original execution except handoff");

    auto openai_wrapper = parse_json(agent_core_execute_openai_function_call(
        R"({"type":"function_call","name":"lookup_profile","call_id":"call_roundtrip_1","arguments":"{\"uid\":\"u-1\"}"})",
        R"({"allow_tools":["lookup_profile"]})"
    ));
    const auto openai_exec_id = openai_wrapper.at("execution").at("execution_id").get<std::string>();
    auto openai_payload = parse_json(agent_core_build_openai_function_call_output(openai_exec_id.c_str(), nullptr));
    expect(openai_payload == openai_wrapper.at("provider_payload"), "openai provider payload roundtrip mismatch");

    auto claude_wrapper = parse_json(agent_core_execute_claude_tool_use(
        R"({"type":"tool_use","id":"toolu_roundtrip_1","name":"lookup_profile","input":{"uid":"u-1"}})",
        R"({"allow_tools":["lookup_profile"]})"
    ));
    const auto claude_exec_id = claude_wrapper.at("execution").at("execution_id").get<std::string>();
    auto claude_payload = parse_json(agent_core_build_claude_tool_result(claude_exec_id.c_str(), nullptr));
    expect(claude_payload == claude_wrapper.at("provider_payload"), "claude provider payload roundtrip mismatch");

    agent_core_shutdown();
    std::cout << "execution_record_roundtrip_test: PASS\n";
    return 0;
}
