#include <string>

#include "agent_core.h"
#include "test_helpers.hpp"

namespace {

bool evidence_has_hook_entry(const nlohmann::json &evidence, const std::string &phase, const std::string &hook_name) {
    if (!evidence.is_array()) {
        return false;
    }
    for (const auto &entry : evidence) {
        if (!entry.is_object()) {
            continue;
        }
        if (entry.value("kind", "") == "hook" &&
            entry.value("phase", "") == phase &&
            entry.value("hook_name", "") == hook_name) {
            return true;
        }
    }
    return false;
}

bool evidence_has_kind(const nlohmann::json &evidence, const std::string &kind) {
    if (!evidence.is_array()) {
        return false;
    }
    for (const auto &entry : evidence) {
        if (entry.is_object() && entry.value("kind", "") == kind) {
            return true;
        }
    }
    return false;
}

} // namespace

int main() {
    using better_agent::tests::expect;
    using better_agent::tests::expect_execution_record_contract;
    using better_agent::tests::parse_json;

    expect(agent_core_init() == 0, "agent_core_init should succeed");

    const char *target_tool = R"({
      "name":"main_action",
      "description":"primary action tool",
      "parameters":{
        "type":"object",
        "properties":{"value":{"type":"string"}},
        "required":["value"],
        "additionalProperties":false
      },
      "constraints":{
        "tool_kind":"function",
        "executor_kind":"builtin",
        "executor_target":"builtin.echo"
      }
    })";
    expect(agent_core_register_tool(target_tool) == 0, "target tool registration should succeed");

    const char *continue_hook = R"({
      "name":"before_continue_hook",
      "description":"before hook continue",
      "parameters":{
        "type":"object",
        "properties":{
          "phase":{"type":"string"},
          "target_tool":{"type":"string"},
          "target_tool_kind":{"type":"string"},
          "request":{"type":"object"}
        },
        "required":["phase","target_tool"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"hooks",
        "executor_kind":"builtin",
        "executor_target":"builtin.hook.echo",
        "default_decision":"continue"
      }
    })";
    expect(agent_core_register_tool(continue_hook) == 0, "continue hook registration should succeed");

    const char *block_hook = R"({
      "name":"before_block_hook",
      "description":"before hook block",
      "parameters":{
        "type":"object",
        "properties":{
          "phase":{"type":"string"},
          "target_tool":{"type":"string"},
          "target_tool_kind":{"type":"string"},
          "request":{"type":"object"}
        },
        "required":["phase","target_tool"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"hooks",
        "executor_kind":"builtin",
        "executor_target":"builtin.hook.echo",
        "default_decision":"block",
        "default_reason":"policy gate"
      }
    })";
    expect(agent_core_register_tool(block_hook) == 0, "block hook registration should succeed");

    const char *after_fail_hook = R"({
      "name":"after_fail_hook",
      "description":"after hook fail",
      "parameters":{
        "type":"object",
        "properties":{
          "phase":{"type":"string"},
          "target_tool":{"type":"string"},
          "target_tool_kind":{"type":"string"},
          "request":{"type":"object"},
          "result":{"type":"object"}
        },
        "required":["phase","target_tool"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"hooks",
        "executor_kind":"builtin",
        "executor_target":"builtin.hook.fail"
      }
    })";
    expect(agent_core_register_tool(after_fail_hook) == 0, "after fail hook registration should succeed");

    const char *hook_target = R"({
      "name":"direct_hook_tool",
      "description":"direct hook tool",
      "parameters":{
        "type":"object",
        "properties":{
          "decision":{"type":"string"},
          "reason":{"type":"string"}
        },
        "additionalProperties":false
      },
      "constraints":{
        "tool_kind":"hooks",
        "executor_kind":"builtin",
        "executor_target":"builtin.hook.echo",
        "default_decision":"continue"
      }
    })";
    expect(agent_core_register_tool(hook_target) == 0, "direct hook tool registration should succeed");

    auto success_with_hooks = parse_json(agent_core_execute_function_call(
        R"({"tool":"main_action","arguments":{"value":"ok"}})",
        R"({"allow_tools":["main_action","before_continue_hook","after_fail_hook"],"before_tool_hooks":["before_continue_hook"],"after_tool_hooks":["after_fail_hook"]})"
    ));
    expect_execution_record_contract(success_with_hooks);
    expect(success_with_hooks.at("status") == "success", "after hook failure should not change main success");
    expect(evidence_has_hook_entry(success_with_hooks.at("evidence"), "before_tool", "before_continue_hook"), "before hook evidence missing");
    expect(evidence_has_hook_entry(success_with_hooks.at("evidence"), "after_tool", "after_fail_hook"), "after hook evidence missing");

    auto blocked_by_hook = parse_json(agent_core_execute_function_call(
        R"({"tool":"main_action","arguments":{"value":"blocked"}})",
        R"({"allow_tools":["main_action","before_block_hook"],"before_tool_hooks":["before_block_hook"]})"
    ));
    expect_execution_record_contract(blocked_by_hook);
    expect(blocked_by_hook.at("status") == "blocked", "before hook block should block main execution");
    expect(blocked_by_hook.at("error").at("error_code") == "E_HOOK_BLOCKED", "hook block error mismatch");
    expect(evidence_has_hook_entry(blocked_by_hook.at("evidence"), "before_tool", "before_block_hook"), "blocked hook evidence missing");

    auto direct_hook_record = parse_json(agent_core_execute_function_call(
        R"({"tool":"direct_hook_tool","arguments":{"decision":"continue","reason":"direct"}})",
        R"({"allow_tools":["direct_hook_tool","before_continue_hook","after_fail_hook"],"before_tool_hooks":["before_continue_hook"],"after_tool_hooks":["after_fail_hook"]})"
    ));
    expect_execution_record_contract(direct_hook_record);
    expect(direct_hook_record.at("tool_kind") == "hooks", "direct hook tool_kind mismatch");
    expect(direct_hook_record.at("status") == "success", "direct hook execution should succeed");
    expect(evidence_has_kind(direct_hook_record.at("evidence"), "hook_recursion_guard"), "direct hook should emit recursion guard evidence");

    agent_core_shutdown();
    std::cout << "hook_lifecycle_test: PASS\n";
    return 0;
}
