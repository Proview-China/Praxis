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

AGENT_CORE_API const char *agent_core_sandbox_probe(const char *request_json);

/* Last normalized error:
 * { "error_code": "...", "message": "...", "detail": ... }
 */
AGENT_CORE_API const char *agent_core_last_error(void);

/* ── Memory Module (M0) ──────────────────────────────────────────────────── */
/* Configure or inspect memory runtime:
 * {
 *   "store_path": "...optional...",
 *   "max_injection_entries": 5,
 *   "max_injection_chars": 2000
 * }
 */
AGENT_CORE_API const char *agent_core_memory_configure(const char *config_json);

/* Ingest memory from execution records or conclusions:
 * {
 *   "input_type": "execution_record|conclusion",
 *   "execution_id": "...optional...",
 *   "record": { ...optional execution record... },
 *   "topic": "...",
 *   "summary": "...optional if execution_record can infer...",
 *   "layer": "short_term|task|strategy",
 *   "scope": { ...optional... },
 *   "confidence": 0.0,
 *   "ttl_seconds": 3600,
 *   "evidence": [ ...optional... ],
 *   "source": { ...optional... }
 * }
 */
AGENT_CORE_API const char *agent_core_memory_ingest(const char *memory_input_json);

/* Query ranked and truncated memory candidates:
 * {
 *   "intent": "...optional...",
 *   "topic": "...optional...",
 *   "layers": ["task","strategy"],
 *   "scope": { ...optional... },
 *   "max_entries": 5,
 *   "max_chars": 2000,
 *   "include_expired": false,
 *   "include_conflicted": false,
 *   "include_superseded": false
 * }
 */
AGENT_CORE_API const char *agent_core_memory_query(const char *query_json);

/* Fetch one stored memory entry by id as JSON. */
AGENT_CORE_API const char *agent_core_memory_get(const char *memory_id);

/* Clear current memory store contents while preserving config. */
AGENT_CORE_API const char *agent_core_memory_reset(void);

/* ── GPT Runtime Builder (Rust-backed, experimental) ─────────────────────── */
AGENT_CORE_API const char *agent_core_build_gpt_responses_request(const char *request_json);
AGENT_CORE_API const char *agent_core_build_gpt_toolset(const char *request_json);
AGENT_CORE_API const char *agent_core_build_gpt_basic_abilities(const char *request_json);
AGENT_CORE_API const char *agent_core_build_after_tool_use_hook_payload(const char *request_json);
AGENT_CORE_API const char *agent_core_render_skills_section(const char *request_json);
AGENT_CORE_API const char *agent_core_rust_runtime_version(void);

/* ── Unified runtime contract normalizer ─────────────────────────────────── */
/* Input: raw event JSON from upstream runtimes (codex/claude/others). */
/* Output: normalized execution record JSON following internal contract. */
AGENT_CORE_API const char *agent_core_normalize_runtime_event(const char *raw_event_json);
#ifdef __cplusplus
}
#endif

#endif /* AGENT_CORE_H */
