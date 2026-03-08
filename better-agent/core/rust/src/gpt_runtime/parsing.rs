use serde_json::{json, Value};

pub fn parse_json_object_text(raw: &str, field_name: &str) -> Result<Value, Value> {
    match serde_json::from_str::<Value>(raw) {
        Ok(value) => Ok(value),
        Err(err) => Err(json!({
            "error_code": "E_PARSE",
            "message": format!("invalid {field_name}"),
            "detail": err.to_string()
        })),
    }
}
