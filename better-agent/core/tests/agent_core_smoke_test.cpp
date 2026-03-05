#include <cstdlib>
#include <iostream>
#include <string>

#include "agent_core.h"
#include "nlohmann/json.hpp"

using json = nlohmann::json;

namespace {

json parse_json(const char *text) {
    if (text == nullptr) {
        throw std::runtime_error("received null json text");
    }
    return json::parse(text);
}

void expect(bool cond, const std::string &msg) {
    if (!cond) {
        std::cerr << "[FAIL] " << msg << "\n";
        std::exit(1);
    }
}

} // namespace

int main() {
    expect(agent_core_init() == 0, "agent_core_init should return 0");

    const char *tool_def = R"({
        "name":"sum_numbers",
        "description":"sum two integers",
        "parameters":{
            "type":"object",
            "properties":{
                "a":{"type":"integer"},
                "b":{"type":"integer"}
            },
            "required":["a","b"],
            "additionalProperties":false
        },
        "mock_result":{"sum":3}
    })";

    expect(agent_core_register_tool(tool_def) == 0, "register tool should succeed");

    const char *openai_call = R"({
        "type":"function_call",
        "name":"sum_numbers",
        "call_id":"call_oai_1",
        "arguments":"{\"a\":1,\"b\":2}"
    })";

    const char *claude_call = R"({
        "type":"tool_use",
        "id":"toolu_1",
        "name":"sum_numbers",
        "input":{"a":1,"b":2}
    })";

    json openai_out = parse_json(agent_core_execute_openai_function_call(
        openai_call,
        R"({"allow_tools":["sum_numbers"],"idempotency_key":"idem-oai"})"
    ));
    expect(openai_out.at("execution").at("status") == "success", "openai execution status should be success");
    expect(openai_out.at("execution").at("provider_kind") == "openai", "openai provider_kind should be openai");
    expect(openai_out.at("provider_payload").at("type") == "function_call_output", "openai payload type mismatch");
    expect(openai_out.at("provider_payload").at("call_id") == "call_oai_1", "openai call_id mismatch");

    json claude_out = parse_json(agent_core_execute_claude_tool_use(
        claude_call,
        R"({"allow_tools":["sum_numbers"],"idempotency_key":"idem-claude"})"
    ));
    expect(claude_out.at("execution").at("status") == "success", "claude execution status should be success");
    expect(claude_out.at("execution").at("provider_kind") == "claude", "claude provider_kind should be claude");
    expect(claude_out.at("provider_payload").at("type") == "tool_result", "claude payload type mismatch");
    expect(claude_out.at("provider_payload").at("tool_use_id") == "toolu_1", "claude tool_use_id mismatch");

    json idem_conflict = parse_json(agent_core_execute_claude_tool_use(
        claude_call,
        R"({"allow_tools":["sum_numbers"],"idempotency_key":"idem-oai"})"
    ));
    expect(idem_conflict.at("execution").at("status") == "failed", "idempotency conflict should fail execution");
    expect(idem_conflict.at("execution").at("error").at("error_code") == "E_IDEMPOTENCY_CONFLICT", "idempotency error code mismatch");

    json invalid_policy = parse_json(agent_core_execute_function_call(
        openai_call,
        "{"
    ));
    expect(invalid_policy.at("status") == "failed", "invalid policy must fail");
    expect(invalid_policy.at("error").at("error_code") == "E_POLICY_PARSE", "invalid policy error code mismatch");

    const std::string exec_id = openai_out.at("execution").at("execution_id").get<std::string>();
    json loaded = parse_json(agent_core_get_execution(exec_id.c_str()));
    expect(loaded.at("execution_id") == exec_id, "get_execution should return stored record");

    agent_core_shutdown();
    std::cout << "agent_core_smoke_test: PASS\n";
    return 0;
}
