use serde_json::{json, Value};

use crate::gpt_runtime::payload_normalization::normalize_tool_payload;
use crate::gpt_runtime::policy::{build_policy_view, parse_policy_json};

pub fn prepare_function_call_request(
    model_output_json: &str,
    policy_json: Option<&str>,
) -> Result<Value, Value> {
    let raw = crate::gpt_runtime::parsing::parse_json_object_text(model_output_json, "model_output_json")?;
    let policy_raw = parse_policy_json(policy_json)?;
    let policy_view = build_policy_view(&policy_raw);
    let normalized = normalize_tool_payload(&raw)?;

    if normalized.get("tool_name").and_then(Value::as_str).unwrap_or("").is_empty() {
        return Err(json!({
            "error_code": "E_PARSE",
            "message": "normalized tool_name is empty"
        }));
    }

    Ok(json!({
        "policy": policy_view,
        "normalized": normalized
    }))
}
