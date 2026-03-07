#include <filesystem>
#include <fstream>
#include <string>

#include "agent_core.h"
#include "test_helpers.hpp"

namespace {

bool evidence_contains_kind_value(const nlohmann::json &evidence, const std::string &kind, const std::string &value) {
    if (!evidence.is_array()) {
        return false;
    }
    for (const auto &entry : evidence) {
        if (!entry.is_object()) {
            continue;
        }
        if (entry.value("kind", "") == kind && entry.value("value", "") == value) {
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

    namespace fs = std::filesystem;

    expect(agent_core_init() == 0, "agent_core_init should succeed");

    const char *shell_tool = R"({
      "name":"shell_echo",
      "description":"posix shell echo",
      "parameters":{
        "type":"object",
        "properties":{
          "command":{"type":"string"},
          "cwd":{"type":"string"},
          "shell":{"type":"string"}
        },
        "required":["command"],
        "additionalProperties":false
      },
      "constraints":{
        "tool_kind":"shell",
        "executor_kind":"builtin",
        "executor_target":"builtin.shell.posix"
      }
    })";
    expect(agent_core_register_tool(shell_tool) == 0, "shell tool registration should succeed");

    const char *code_tool = R"({
      "name":"run_code",
      "description":"posix code runner",
      "parameters":{
        "type":"object",
        "properties":{
          "source":{"type":"string"},
          "runtime":{"type":"string"},
          "cwd":{"type":"string"}
        },
        "required":["source"],
        "additionalProperties":false
      },
      "constraints":{
        "tool_kind":"code",
        "executor_kind":"builtin",
        "executor_target":"builtin.code.posix"
      }
    })";
    expect(agent_core_register_tool(code_tool) == 0, "code tool registration should succeed");

    const char *web_tool = R"({
      "name":"web_lookup",
      "description":"fixture web search",
      "parameters":{
        "type":"object",
        "properties":{
          "query":{"type":"string"},
          "fixture_results":{"type":"array"}
        },
        "required":["query"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"web",
        "executor_kind":"builtin",
        "executor_target":"builtin.web.fixture"
      }
    })";
    expect(agent_core_register_tool(web_tool) == 0, "web tool registration should succeed");

    const char *computer_tool = R"({
      "name":"computer_plan",
      "description":"fixture computer use",
      "parameters":{
        "type":"object",
        "properties":{
          "goal":{"type":"string"},
          "fixture_result":{"type":"object"}
        },
        "required":["goal"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"computer",
        "executor_kind":"builtin",
        "executor_target":"builtin.computer.fixture"
      }
    })";
    expect(agent_core_register_tool(computer_tool) == 0, "computer tool registration should succeed");

    const char *skills_tool = R"({
      "name":"load_skill",
      "description":"fixture skills loader",
      "parameters":{
        "type":"object",
        "properties":{
          "skill_path":{"type":"string"}
        },
        "required":["skill_path"],
        "additionalProperties":false
      },
      "constraints":{
        "tool_kind":"skills",
        "executor_kind":"builtin",
        "executor_target":"builtin.skills.fixture"
      }
    })";
    expect(agent_core_register_tool(skills_tool) == 0, "skills tool registration should succeed");

    const char *mcp_tool = R"({
      "name":"call_remote_tool",
      "description":"fixture mcp caller",
      "parameters":{
        "type":"object",
        "properties":{
          "server":{"type":"string"},
          "remote_tool":{"type":"string"},
          "fixture_response":{"type":"object"}
        },
        "required":["server","remote_tool"],
        "additionalProperties":true
      },
      "constraints":{
        "tool_kind":"mcp",
        "executor_kind":"builtin",
        "executor_target":"builtin.mcp.fixture"
      }
    })";
    expect(agent_core_register_tool(mcp_tool) == 0, "mcp tool registration should succeed");

    const fs::path skill_root = fs::temp_directory_path() / "agent-core-skill-fixture";
    fs::create_directories(skill_root);
    const fs::path skill_file = skill_root / "fixture-skill.md";
    std::ofstream skill_out(skill_file);
    skill_out << "# Fixture Skill\n\nThis is a fixture skill body.\n";
    skill_out.close();

    const std::string cwd = fs::current_path().string();
    const std::string allow_cwds_json = std::string("[\"") + cwd + "\"]";
    const std::string skill_roots_json = std::string("[\"") + skill_root.string() + "\"]";
    const std::string shell_call_json =
        std::string(R"({"tool":"shell_echo","arguments":{"command":"printf 'hello-shell'","cwd":")") + cwd +
        R"(","shell":"sh"}})";
    const std::string shell_policy_json =
        std::string(R"({"allow_tools":["shell_echo"],"allowed_commands":["printf"],"allowed_cwds":)") + allow_cwds_json + "}";
    const std::string shell_openai_json =
        std::string(R"({"type":"function_call","name":"shell_echo","call_id":"shell_call_1","arguments":"{\"command\":\"printf 'openai-shell'\",\"cwd\":\")") +
        cwd + R"(\"}"})";
    const std::string shell_denied_json =
        std::string(R"({"tool":"shell_echo","arguments":{"command":"printf 'blocked'","cwd":")") + cwd + R"("}})";
    const std::string shell_denied_policy_json =
        std::string(R"({"allow_tools":["shell_echo"],"allowed_commands":["echo"],"allowed_cwds":)") + allow_cwds_json + "}";
    const std::string code_call_json =
        std::string(R"({"tool":"run_code","arguments":{"source":"printf 'hello-code'","runtime":"sh","cwd":")") + cwd + R"("}})";
    const std::string code_policy_json =
        std::string(R"({"allow_tools":["run_code"],"allowed_runtimes":["sh"],"allowed_cwds":)") + allow_cwds_json + "}";
    const std::string skill_call_json =
        std::string(R"({"tool":"load_skill","arguments":{"skill_path":")") + skill_file.string() + R"("}})";
    const std::string skill_policy_json =
        std::string(R"({"allow_tools":["load_skill"],"allowed_skill_roots":)") + skill_roots_json + "}";

    auto shell_record = parse_json(agent_core_execute_function_call(
        shell_call_json.c_str(),
        shell_policy_json.c_str()
    ));
    expect_execution_record_contract(shell_record);
    expect(shell_record.at("tool_kind") == "shell", "shell tool_kind mismatch");
    expect(shell_record.at("status") == "success", "shell builtin should succeed");
    expect(shell_record.at("result").at("stdout") == "hello-shell", "shell stdout mismatch");
    expect(evidence_contains_kind_value(shell_record.at("evidence"), "tool_kind", "shell"), "shell evidence should preserve tool_kind");

    const auto shell_exec_id = shell_record.at("execution_id").get<std::string>();
    auto shell_loaded = parse_json(agent_core_get_execution(shell_exec_id.c_str()));
    expect(shell_loaded.at("tool_kind") == "shell", "stored shell execution should preserve tool_kind");

    auto shell_wrapper = parse_json(agent_core_execute_openai_function_call(
        shell_openai_json.c_str(),
        shell_policy_json.c_str()
    ));
    expect(shell_wrapper.at("execution").at("tool_kind") == "shell", "provider wrapper should preserve shell tool_kind");

    auto shell_unsupported = parse_json(agent_core_execute_function_call(
        R"({"tool":"shell_echo","arguments":{"command":"printf 'x'","cwd":"."}})",
        R"({"allow_tools":["shell_echo"],"allowed_commands":["printf"],"allowed_cwds":["."],"platform_override":"windows"})"
    ));
    expect(shell_unsupported.at("status") == "blocked", "unsupported platform should block shell executor");
    expect(shell_unsupported.at("error").at("error_code") == "E_PLATFORM_UNSUPPORTED", "unsupported platform error mismatch");

    auto shell_denied = parse_json(agent_core_execute_function_call(
        shell_denied_json.c_str(),
        shell_denied_policy_json.c_str()
    ));
    expect(shell_denied.at("status") == "blocked", "shell policy deny should block");
    expect(shell_denied.at("error").at("error_code") == "E_POLICY_DENY", "shell policy deny error mismatch");

    auto code_record = parse_json(agent_core_execute_function_call(
        code_call_json.c_str(),
        code_policy_json.c_str()
    ));
    expect_execution_record_contract(code_record);
    expect(code_record.at("tool_kind") == "code", "code tool_kind mismatch");
    expect(code_record.at("status") == "success", "code executor should succeed");
    expect(code_record.at("result").at("stdout") == "hello-code", "code stdout mismatch");
    expect(code_record.at("result").at("artifacts").is_array(), "code artifacts should be returned");

    auto web_record = parse_json(agent_core_execute_function_call(
        R"({"tool":"web_lookup","arguments":{"query":"better-agent","fixture_results":[{"title":"Doc","url":"https://example.test/doc","source":"fixture"}]}})",
        R"({"allow_tools":["web_lookup"]})"
    ));
    expect_execution_record_contract(web_record);
    expect(web_record.at("tool_kind") == "web", "web tool_kind mismatch");
    expect(web_record.at("status") == "success", "web fixture should succeed");
    expect(web_record.at("result").at("items").size() == 1, "web result size mismatch");

    auto computer_record = parse_json(agent_core_execute_function_call(
        R"({"tool":"computer_plan","arguments":{"goal":"open settings","fixture_result":{"final_status":"success","actions":[{"type":"click","target":"settings"}]}}})",
        R"({"allow_tools":["computer_plan"]})"
    ));
    expect_execution_record_contract(computer_record);
    expect(computer_record.at("tool_kind") == "computer", "computer tool_kind mismatch");
    expect(computer_record.at("status") == "success", "computer fixture should succeed");

    auto skill_record = parse_json(agent_core_execute_function_call(
        skill_call_json.c_str(),
        skill_policy_json.c_str()
    ));
    expect_execution_record_contract(skill_record);
    expect(skill_record.at("tool_kind") == "skills", "skills tool_kind mismatch");
    expect(skill_record.at("status") == "success", "skills fixture should succeed");
    expect(skill_record.at("result").at("skill_path") == skill_file.string(), "skills path mismatch");

    auto mcp_record = parse_json(agent_core_execute_function_call(
        R"({"tool":"call_remote_tool","arguments":{"server":"fixture-server","remote_tool":"lookup","fixture_response":{"ok":true,"rows":2}}})",
        R"({"allow_tools":["call_remote_tool"]})"
    ));
    expect_execution_record_contract(mcp_record);
    expect(mcp_record.at("tool_kind") == "mcp", "mcp tool_kind mismatch");
    expect(mcp_record.at("status") == "success", "mcp fixture should succeed");
    expect(mcp_record.at("result").at("response").at("rows") == 2, "mcp response mismatch");

    agent_core_shutdown();
    std::cout << "tool_kind_builtin_paths_test: PASS\n";
    return 0;
}
