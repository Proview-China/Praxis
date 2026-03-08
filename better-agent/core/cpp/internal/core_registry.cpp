#include "agent_core_internal.hpp"
#include "core_rust_bridge.hpp"

namespace better_agent::core_internal {

bool parse_tool_registration_json(const char *tool_definition_json, ToolRegistration *tool_out) {
    json err;
    const json parsed = parse_tool_definition_via_rust(json::parse(tool_definition_json), &err);
    if (!err.is_null()) {
        g_last_error = err.dump();
        return false;
    }

    const std::string executor_kind_raw = parsed.value("executor_kind", "mock");
    ExecutorKind executor_kind = ExecutorKind::Mock;
    if (executor_kind_raw == "builtin") {
        executor_kind = ExecutorKind::Builtin;
    } else if (executor_kind_raw == "native") {
        executor_kind = ExecutorKind::Native;
    }

    const json spec = parsed.value("spec", json::object());
    *tool_out = ToolRegistration{
        .spec = ToolSpec{
            .name = get_string_or(spec, "name"),
            .description = get_string_or(spec, "description"),
            .parameters = spec.value("parameters", json::object()),
            .constraints = spec.value("constraints", json::object()),
        },
        .tool_kind = parsed.value("tool_kind", std::string("function")),
        .executor_kind = executor_kind,
        .executor_target = parsed.value("executor_target", std::string()),
        .mock_result = parsed.value("mock_result", json::object()),
    };
    return !tool_out->spec.name.empty();
}

} // namespace better_agent::core_internal
