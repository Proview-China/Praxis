use serde_json::{json, Value};

pub fn parse_policy_json(raw: Option<&str>) -> Result<Value, Value> {
    let Some(text) = raw else {
        return Ok(json!({}));
    };

    match serde_json::from_str::<Value>(text) {
        Ok(Value::Object(map)) => Ok(Value::Object(map)),
        Ok(_) => Err(json!({
            "error_code": "E_POLICY_PARSE",
            "message": "policy_json must be a JSON object"
        })),
        Err(err) => Err(json!({
            "error_code": "E_POLICY_PARSE",
            "message": "invalid policy_json",
            "detail": err.to_string()
        })),
    }
}

pub fn build_policy_view(policy: &Value) -> Value {
    let allow_tools: Vec<String> = policy
        .get("allow_tools")
        .and_then(Value::as_array)
        .map(|items| items.iter().filter_map(Value::as_str).map(ToOwned::to_owned).collect())
        .unwrap_or_default();
    let deny_tools: Vec<String> = policy
        .get("deny_tools")
        .and_then(Value::as_array)
        .map(|items| items.iter().filter_map(Value::as_str).map(ToOwned::to_owned).collect())
        .unwrap_or_default();

    serde_json::json!({
        "raw_json": policy,
        "allow_tools": allow_tools,
        "deny_tools": deny_tools,
        "execution_id": policy.get("execution_id").and_then(Value::as_str).unwrap_or(""),
        "timeout_ms": policy.get("timeout_ms").and_then(Value::as_u64).unwrap_or(0),
        "network_access": policy.get("network_access").and_then(Value::as_bool).unwrap_or(false),
        "max_stdout_bytes": policy.get("max_stdout_bytes").and_then(Value::as_u64).unwrap_or(0),
        "max_stderr_bytes": policy.get("max_stderr_bytes").and_then(Value::as_u64).unwrap_or(0),
        "max_artifacts": policy.get("max_artifacts").and_then(Value::as_u64).unwrap_or(0),
        "require_network": policy.get("requires_network").and_then(Value::as_bool).unwrap_or(false),
        "cpu_limit": policy.get("cpu_limit").cloned().unwrap_or(Value::Null),
        "memory_limit": policy.get("memory_limit").cloned().unwrap_or(Value::Null)
    })
}
