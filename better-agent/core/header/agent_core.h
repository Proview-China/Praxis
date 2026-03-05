#ifndef AGENT_CORE_H
#define AGENT_CORE_H

/* ── Export macro ─────────────────────────────────────────────────────────── */
#ifdef AGENT_CORE_EXPORTS
    #define AGENT_CORE_API __attribute__((visibility("default")))
#else
    #define AGENT_CORE_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ── Lifecycle ───────────────────────────────────────────────────────────── */
AGENT_CORE_API int agent_core_init(void);
AGENT_CORE_API void agent_core_shutdown(void);

/* ── Version info ────────────────────────────────────────────────────────── */
AGENT_CORE_API const char *agent_core_version(void);

/* ── Function Calling / Custom Tools (M0 vertical slice) ────────────────── */
/* Register a tool from JSON definition:
 * {
 *   "name": "tool_name",
 *   "description": "...",
 *   "parameters": { ...JSON Schema... },
 *   "constraints": { ...optional... },
 *   "mock_result": { ...optional... }
 * }
 */
AGENT_CORE_API int agent_core_register_tool(const char *tool_definition_json);

/* Execute one function/custom tool call and return a JSON envelope:
 * {
 *   "execution_id": "...",
 *   "status": "success|failed|blocked|partial",
 *   "tool_name": "...",
 *   ...
 * }
 */
AGENT_CORE_API const char *agent_core_execute_function_call(
    const char *model_output_json,
    const char *policy_json
);

/* Provider-specific execute helpers (same runtime, different input semantics). */
AGENT_CORE_API const char *agent_core_execute_openai_function_call(
    const char *openai_function_call_json,
    const char *policy_json
);
AGENT_CORE_API const char *agent_core_execute_claude_tool_use(
    const char *claude_tool_use_json,
    const char *policy_json
);

/* Fetch a previously stored normalized execution record by id as JSON. */
AGENT_CORE_API const char *agent_core_get_execution(const char *execution_id);

/* Provider-specific output builders from a stored execution record. */
AGENT_CORE_API const char *agent_core_build_openai_function_call_output(
    const char *execution_id,
    const char *call_id_override
);
AGENT_CORE_API const char *agent_core_build_claude_tool_result(
    const char *execution_id,
    const char *tool_use_id_override
);

/* Last normalized error:
 * { "error_code": "...", "message": "...", "detail": ... }
 */
AGENT_CORE_API const char *agent_core_last_error(void);

/* ── Unified runtime contract normalizer ─────────────────────────────────── */
/* Input: raw event JSON from upstream runtimes (codex/claude/others). */
/* Output: normalized execution record JSON following internal contract. */
AGENT_CORE_API const char *agent_core_normalize_runtime_event(const char *raw_event_json);
#ifdef __cplusplus
}
#endif

#endif /* AGENT_CORE_H */
