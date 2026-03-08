use serde_json::{json, Value};

pub fn resolve_mock_result(mock_result: &Value, args: &Value) -> Value {
    if let Some(obj) = mock_result.as_object() {
        if !obj.is_empty() {
            return mock_result.clone();
        }
    }
    json!({
        "ok": true,
        "echo": args
    })
}

pub fn build_mock_execution_result(mock_result: &Value, args: &Value) -> Value {
    json!({
        "status": "success",
        "result": resolve_mock_result(mock_result, args),
        "error": Value::Null,
        "evidence": [],
        "handoff": "continue"
    })
}
