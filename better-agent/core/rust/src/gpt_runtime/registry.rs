use serde::Deserialize;
use serde_json::{json, Value};

#[derive(Debug, Deserialize)]
struct ToolDefinitionInput {
    name: String,
    #[serde(default)]
    description: String,
    #[serde(default)]
    parameters: Value,
    #[serde(default)]
    constraints: Value,
    #[serde(default)]
    mock_result: Value,
}

fn infer_tool_kind_from_executor_target(executor_target: &str) -> &'static str {
    if executor_target.contains(".shell.") {
        "shell"
    } else if executor_target.contains(".web.") {
        "web"
    } else if executor_target.contains(".code.") {
        "code"
    } else if executor_target.contains(".computer.") {
        "computer"
    } else if executor_target.contains(".hook.") {
        "hooks"
    } else if executor_target.contains(".skills.") {
        "skills"
    } else if executor_target.contains(".mcp.") {
        "mcp"
    } else {
        "function"
    }
}

fn supported_tool_kind(tool_kind: &str) -> bool {
    matches!(
        tool_kind,
        "function" | "web" | "code" | "computer" | "shell" | "hooks" | "skills" | "mcp"
    )
}

pub fn parse_tool_definition(input: Value) -> Result<Value, Value> {
    let parsed: ToolDefinitionInput = serde_json::from_value(input).map_err(|err| {
        json!({
            "error_code": "E_TOOL_DEF",
            "message": "invalid tool definition JSON",
            "detail": err.to_string()
        })
    })?;

    if parsed.name.trim().is_empty() {
        return Err(json!({
            "error_code": "E_TOOL_DEF",
            "message": "tool definition requires non-empty name"
        }));
    }

    let constraints = parsed.constraints;
    let mut executor_kind = "mock".to_string();
    let mut executor_target = String::new();
    let mut tool_kind = "function".to_string();

    if let Some(kind) = constraints.get("executor_kind").and_then(Value::as_str) {
        match kind {
            "mock" | "builtin" | "native" => executor_kind = kind.to_string(),
            _ => {
                return Err(json!({
                    "error_code": "E_TOOL_DEF",
                    "message": "unsupported executor_kind",
                    "detail": { "executor_kind": kind }
                }))
            }
        }
    } else if constraints.get("executor_kind").is_some() {
        return Err(json!({
            "error_code": "E_TOOL_DEF",
            "message": "constraints.executor_kind must be a string"
        }));
    }

    if let Some(target) = constraints.get("executor_target").and_then(Value::as_str) {
        executor_target = target.to_string();
    } else if constraints.get("executor_target").is_some() {
        return Err(json!({
            "error_code": "E_TOOL_DEF",
            "message": "constraints.executor_target must be a string"
        }));
    }

    if let Some(kind) = constraints.get("tool_kind").and_then(Value::as_str) {
        tool_kind = kind.to_string();
    } else if constraints.get("tool_kind").is_some() {
        return Err(json!({
            "error_code": "E_TOOL_DEF",
            "message": "constraints.tool_kind must be a string"
        }));
    } else if !executor_target.is_empty() {
        tool_kind = infer_tool_kind_from_executor_target(&executor_target).to_string();
    }

    if !supported_tool_kind(&tool_kind) {
        return Err(json!({
            "error_code": "E_TOOL_DEF",
            "message": "unsupported tool_kind",
            "detail": { "tool_kind": tool_kind }
        }));
    }

    Ok(json!({
        "spec": {
            "name": parsed.name,
            "description": parsed.description,
            "parameters": parsed.parameters,
            "constraints": constraints
        },
        "tool_kind": tool_kind,
        "executor_kind": executor_kind,
        "executor_target": executor_target,
        "mock_result": parsed.mock_result
    }))
}
