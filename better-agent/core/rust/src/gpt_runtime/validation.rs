use serde_json::{json, Value};

fn validate_type(value: &Value, expected: &str) -> bool {
    match expected {
        "string" => value.is_string(),
        "number" => value.is_number(),
        "integer" => value.is_i64() || value.is_u64(),
        "boolean" => value.is_boolean(),
        "array" => value.is_array(),
        "object" => value.is_object(),
        _ => true,
    }
}

pub fn schema_validate_args(args: &Value, schema: &Value) -> Value {
    if !schema.is_object() {
        return json!({});
    }
    if !args.is_object() {
        return json!({
            "error_code": "E_SCHEMA",
            "message": "tool arguments must be a JSON object"
        });
    }

    let required = schema.get("required").and_then(Value::as_array).cloned().unwrap_or_default();
    let properties = schema.get("properties").and_then(Value::as_object).cloned().unwrap_or_default();
    let additional = schema.get("additionalProperties").and_then(Value::as_bool).unwrap_or(true);

    for entry in required {
        if let Some(key) = entry.as_str() {
            if !args.get(key).is_some() {
                return json!({
                    "error_code": "E_SCHEMA",
                    "message": "missing required argument",
                    "detail": { "missing": key }
                });
            }
        }
    }

    if let Some(args_obj) = args.as_object() {
        for (key, value) in args_obj {
            if !properties.contains_key(key) {
                if !additional {
                    return json!({
                        "error_code": "E_SCHEMA",
                        "message": "unknown argument is not allowed",
                        "detail": { "key": key }
                    });
                }
                continue;
            }

            let prop = &properties[key];
            let expected = prop.get("type").and_then(Value::as_str).unwrap_or("");
            if !expected.is_empty() && !validate_type(value, expected) {
                return json!({
                    "error_code": "E_SCHEMA",
                    "message": "argument type mismatch",
                    "detail": { "key": key, "expected": expected }
                });
            }
        }
    }

    json!({})
}

pub fn validate_tool_call_policy(tool_name: &str, allow_tools: &[String], deny_tools: &[String]) -> Value {
    if deny_tools.iter().any(|value| value == tool_name) {
        return json!({
            "error_code": "E_POLICY_DENY",
            "message": "tool denied by policy",
            "detail": { "tool": tool_name }
        });
    }
    if !allow_tools.is_empty() && !allow_tools.iter().any(|value| value == tool_name) {
        return json!({
            "error_code": "E_POLICY_DENY",
            "message": "tool not in allow_tools",
            "detail": { "tool": tool_name }
        });
    }
    json!({})
}
