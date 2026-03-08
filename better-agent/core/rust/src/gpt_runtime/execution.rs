use serde_json::{json, Value};

pub fn build_tool_execution_request(
    tool: &Value,
    call: &Value,
    policy: &Value,
    execution_id: &str,
) -> Value {
    json!({
        "execution_id": execution_id,
        "tool_name": call.get("tool_name").and_then(Value::as_str).unwrap_or(""),
        "tool_kind": tool.get("tool_kind").and_then(Value::as_str).unwrap_or("function"),
        "provider_kind": call.get("provider_kind").and_then(Value::as_str).unwrap_or("custom"),
        "intent": call.get("intent").and_then(Value::as_str).unwrap_or(""),
        "provider_call_id": call.get("provider_call_id").and_then(Value::as_str).unwrap_or(""),
        "args": call.get("input_normalized").cloned().unwrap_or_else(|| json!({})),
        "policy": policy.get("raw_json").cloned().unwrap_or_else(|| json!({}))
    })
}

pub fn build_execution_record(
    tool: &Value,
    call: &Value,
    policy: &Value,
    execution_id: &str,
    execution: &Value,
    timestamp: &str,
) -> Value {
    let mut evidence = vec![
        json!({"kind": "runtime_event", "value": "tool_executed"}),
        json!({"kind": "provider_kind", "value": call.get("provider_kind").and_then(Value::as_str).unwrap_or("custom")}),
        json!({"kind": "provider_call_id", "value": call.get("provider_call_id").and_then(Value::as_str).unwrap_or("")}),
        json!({"kind": "timestamp", "value": timestamp}),
        json!({"kind": "tool_kind", "value": tool.get("tool_kind").and_then(Value::as_str).unwrap_or("function")}),
    ];
    if let Some(extra) = execution.get("evidence").and_then(Value::as_array) {
        evidence.extend(extra.iter().cloned());
    }

    json!({
        "execution_id": execution_id,
        "tool_kind": tool.get("tool_kind").and_then(Value::as_str).unwrap_or("function"),
        "provider_kind": call.get("provider_kind").and_then(Value::as_str).unwrap_or("custom"),
        "intent": call.get("intent").and_then(Value::as_str).unwrap_or(""),
        "provider_call_id": call.get("provider_call_id").and_then(Value::as_str).unwrap_or(""),
        "input_raw": call.get("input_raw").cloned().unwrap_or_else(|| json!({})),
        "input_normalized": call.get("input_normalized").cloned().unwrap_or_else(|| json!({})),
        "policy_snapshot": policy.get("raw_json").cloned().unwrap_or_else(|| json!({})),
        "status": execution.get("status").and_then(Value::as_str).unwrap_or("failed"),
        "evidence": evidence,
        "error": execution.get("error").cloned().unwrap_or(Value::Null),
        "handoff": execution.get("handoff").and_then(Value::as_str).unwrap_or("continue"),
        "timestamp": timestamp,
        "result": execution.get("result").cloned().unwrap_or_else(|| json!({}))
    })
}
