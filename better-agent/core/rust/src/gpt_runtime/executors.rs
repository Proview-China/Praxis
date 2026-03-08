use serde_json::{json, Value};

pub fn resolve_executor_target(tool: &Value) -> String {
    if let Some(target) = tool.get("executor_target").and_then(Value::as_str) {
        if !target.is_empty() {
            return target.to_string();
        }
    }
    tool.get("name")
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
}

pub fn builtin_executor_missing(executor_target: &str) -> Value {
    json!({
        "status": "failed",
        "result": {},
        "error": {
            "error_code": "E_EXECUTOR_NOT_FOUND",
            "message": "builtin executor is not registered",
            "detail": { "executor_target": executor_target }
        },
        "evidence": [
            { "kind": "executor_kind", "value": "builtin" },
            { "kind": "executor_target", "value": executor_target }
        ],
        "handoff": "manual_takeover"
    })
}

pub fn native_executor_unavailable(executor_target: &str) -> Value {
    json!({
        "status": "blocked",
        "result": {},
        "error": {
            "error_code": "E_NATIVE_EXECUTOR_UNAVAILABLE",
            "message": "native executor is not available in this build",
            "detail": { "executor_target": executor_target }
        },
        "evidence": [
            { "kind": "executor_kind", "value": "native" },
            { "kind": "executor_target", "value": executor_target }
        ],
        "handoff": "manual_takeover"
    })
}
