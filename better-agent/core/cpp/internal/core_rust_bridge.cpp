#include "core_rust_bridge.hpp"
#include "agent_core_internal.hpp"

extern "C" {
const char *better_agent_rs_version();
const char *better_agent_rs_last_error();
const char *better_agent_rs_parse_policy_json(const char *policy_json);
const char *better_agent_rs_prepare_function_call_request(const char *request_json);
const char *better_agent_rs_build_policy_view(const char *request_json);
const char *better_agent_rs_normalize_runtime_event(const char *request_json);
const char *better_agent_rs_parse_tool_definition(const char *request_json);
const char *better_agent_rs_normalize_tool_payload(const char *request_json);
const char *better_agent_rs_schema_validate_args(const char *request_json);
const char *better_agent_rs_validate_tool_call_policy(const char *request_json);
const char *better_agent_rs_build_tool_execution_request(const char *request_json);
const char *better_agent_rs_build_execution_record(const char *request_json);
const char *better_agent_rs_resolve_mock_result(const char *request_json);
const char *better_agent_rs_build_mock_execution_result(const char *request_json);
const char *better_agent_rs_resolve_executor_target(const char *request_json);
const char *better_agent_rs_builtin_executor_missing(const char *request_json);
const char *better_agent_rs_native_executor_unavailable(const char *request_json);
const char *better_agent_rs_extract_provider_call_id(const char *request_json);
const char *better_agent_rs_extract_tool_name(const char *request_json);
const char *better_agent_rs_build_gpt_responses_request(const char *request_json);
const char *better_agent_rs_build_gpt_toolset(const char *request_json);
const char *better_agent_rs_build_gpt_basic_abilities(const char *request_json);
const char *better_agent_rs_build_after_tool_use_hook_payload(const char *request_json);
const char *better_agent_rs_render_skills_section(const char *request_json);
const char *better_agent_rs_build_openai_function_call_output_payload(const char *request_json);
const char *better_agent_rs_build_openai_bridge_outputs(const char *request_json);
const char *better_agent_rs_build_claude_tool_result_payload(const char *request_json);
const char *better_agent_rs_build_provider_execution_wrapper(const char *request_json);
const char *better_agent_rs_build_openai_request_from_execution(const char *request_json);
}

namespace better_agent::core_internal {

std::string rust_runtime_version() {
    const char *version = better_agent_rs_version();
    return version == nullptr ? std::string{} : std::string(version);
}

json parse_tool_definition_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_parse_tool_definition(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        const json parsed = json::parse(output);
        if (parsed.is_object() && parsed.value("status", "") == "failed") {
            if (err_out != nullptr) {
                *err_out = parsed.value("error", make_error_json("E_RUST_RUNTIME", "rust runtime failed"));
            }
            return json();
        }
        return parsed;
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json parse_policy_json_via_rust(const char *policy_json, json *err_out) {
    const char *output = better_agent_rs_parse_policy_json(policy_json);
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        const json parsed = json::parse(output);
        if (parsed.is_object() && parsed.value("status", "") == "failed") {
            if (err_out != nullptr) {
                *err_out = parsed.value("error", make_error_json("E_POLICY_PARSE", "rust policy parser failed"));
            }
            return json::object();
        }
        return parsed;
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json::object();
    }
}

json prepare_function_call_request_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_prepare_function_call_request(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json::object();
    }
    try {
        const json parsed = json::parse(output);
        if (parsed.is_object() && parsed.value("status", "") == "failed") {
            if (err_out != nullptr) {
                *err_out = parsed.value("error", make_error_json("E_PARSE", "prepare function call request failed"));
            }
            return json::object();
        }
        return parsed;
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json::object();
    }
}

json build_policy_view_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_build_policy_view(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json::object();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json::object();
    }
}

json normalize_runtime_event_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_normalize_runtime_event(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json::object();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json::object();
    }
}

json schema_validate_args_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_schema_validate_args(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json validate_tool_call_policy_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_validate_tool_call_policy(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json build_tool_execution_request_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_build_tool_execution_request(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json build_execution_record_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_build_execution_record(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json resolve_mock_result_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_resolve_mock_result(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json build_mock_execution_result_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_build_mock_execution_result(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

std::string resolve_executor_target_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_resolve_executor_target(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return {};
    }
    try {
        const json parsed = json::parse(output);
        return parsed.value("value", std::string{});
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return {};
    }
}

json builtin_executor_missing_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_builtin_executor_missing(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

json native_executor_unavailable_via_rust(const json &request_json, json *err_out) {
    const char *output = better_agent_rs_native_executor_unavailable(request_json.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return json();
    }
}

std::string extract_provider_call_id_via_rust(const json &record, json *err_out) {
    const char *output = better_agent_rs_extract_provider_call_id(json{{"record", record}}.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return {};
    }
    try {
        const json parsed = json::parse(output);
        return parsed.value("value", std::string{});
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return {};
    }
}

std::string extract_tool_name_from_record_via_rust(const json &record, json *err_out) {
    const char *output = better_agent_rs_extract_tool_name(json{{"record", record}}.dump().c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return {};
    }
    try {
        const json parsed = json::parse(output);
        return parsed.value("value", std::string{});
    } catch (const std::exception &) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
        }
        return {};
    }
}

json build_gpt_responses_request_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_gpt_responses_request(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_RUST_RUNTIME",
                "rust runtime returned null output"
            );
        }
        return json();
    }

    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json(
                        "E_RUST_RUNTIME_PARSE",
                        "failed to parse rust runtime error"
                    );
                }
            } else {
                *err_out = make_error_json(
                    "E_RUST_RUNTIME_PARSE",
                    "failed to parse rust runtime output"
                );
            }
        }
        return json();
    }
}

json build_gpt_toolset_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_gpt_toolset(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_RUST_RUNTIME",
                "rust runtime returned null output"
            );
        }
        return json();
    }

    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json(
                        "E_RUST_RUNTIME_PARSE",
                        "failed to parse rust runtime error"
                    );
                }
            } else {
                *err_out = make_error_json(
                    "E_RUST_RUNTIME_PARSE",
                    "failed to parse rust runtime output"
                );
            }
        }
        return json();
    }
}

json build_gpt_basic_abilities_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_gpt_basic_abilities(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_RUST_RUNTIME",
                "rust runtime returned null output"
            );
        }
        return json();
    }

    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json(
                        "E_RUST_RUNTIME_PARSE",
                        "failed to parse rust runtime error"
                    );
                }
            } else {
                *err_out = make_error_json(
                    "E_RUST_RUNTIME_PARSE",
                    "failed to parse rust runtime output"
                );
            }
        }
        return json();
    }
}

json build_after_tool_use_hook_payload_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_after_tool_use_hook_payload(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json render_skills_section_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_render_skills_section(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json build_openai_function_call_output_payload_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_openai_function_call_output_payload(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json build_openai_bridge_outputs_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_openai_bridge_outputs(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json build_claude_tool_result_payload_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_claude_tool_result_payload(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json build_provider_execution_wrapper_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_provider_execution_wrapper(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json("E_RUST_RUNTIME", "rust runtime returned null output");
        }
        return json();
    }
    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime error");
                }
            } else {
                *err_out = make_error_json("E_RUST_RUNTIME_PARSE", "failed to parse rust runtime output");
            }
        }
        return json();
    }
}

json build_openai_request_from_execution_via_rust(const json &request_json, json *err_out) {
    const std::string request_text = request_json.dump();
    const char *output = better_agent_rs_build_openai_request_from_execution(request_text.c_str());
    if (output == nullptr) {
        if (err_out != nullptr) {
            *err_out = make_error_json(
                "E_RUST_RUNTIME",
                "rust runtime returned null output"
            );
        }
        return json();
    }

    try {
        return json::parse(output);
    } catch (const std::exception &) {
        const char *rust_error = better_agent_rs_last_error();
        if (err_out != nullptr) {
            if (rust_error != nullptr && rust_error[0] != '\0') {
                try {
                    *err_out = json::parse(rust_error);
                } catch (const std::exception &) {
                    *err_out = make_error_json(
                        "E_RUST_RUNTIME_PARSE",
                        "failed to parse rust runtime error"
                    );
                }
            } else {
                *err_out = make_error_json(
                    "E_RUST_RUNTIME_PARSE",
                    "failed to parse rust runtime output"
                );
            }
        }
        return json();
    }
}

} // namespace better_agent::core_internal
