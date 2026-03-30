import { executeTapAgentStructuredOutput, type TapAgentModelRoute } from "../integrations/tap-agent-model.js";
import type { ModelInferenceExecutionResult } from "../integrations/model-inference.js";
import type {
  ToolReviewGovernanceInputShell,
  ToolReviewGovernanceOutputShell,
} from "./tool-review-contract.js";

export interface ToolReviewerLlmAdvice {
  summary: string;
  metadata?: Record<string, unknown>;
}

export interface ToolReviewerRuntimeLlmHookInput {
  sessionId: string;
  governanceAction: ToolReviewGovernanceInputShell;
  defaultOutput: ToolReviewGovernanceOutputShell;
}

export type ToolReviewerRuntimeLlmHook = (
  input: ToolReviewerRuntimeLlmHookInput,
) => Promise<ToolReviewerLlmAdvice | undefined>;

type ModelExecutor = (params: { intent: import("../types/index.js").ModelInferenceIntent }) => Promise<ModelInferenceExecutionResult>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseAdvice(value: unknown): ToolReviewerLlmAdvice {
  if (!isRecord(value)) {
    throw new Error("Tool reviewer model output must be a plain object.");
  }
  if (typeof value.summary !== "string" || !value.summary.trim()) {
    throw new Error("Tool reviewer model output requires a non-empty summary.");
  }
  return {
    summary: value.summary.trim(),
    metadata: isRecord(value.metadata) ? value.metadata : undefined,
  };
}

export function createDefaultToolReviewerLlmHook(options: {
  executor: ModelExecutor;
  route?: Partial<TapAgentModelRoute>;
}): ToolReviewerRuntimeLlmHook {
  return async (input) => {
    return executeTapAgentStructuredOutput({
      executor: options.executor,
      sessionId: input.sessionId,
      runId: input.governanceAction.trace.request?.runId ?? `${input.sessionId}:tool-review`,
      workerKind: "tap-tool-reviewer",
      route: options.route,
      systemPrompt: [
        "You are the TAP tool reviewer.",
        "Stay in governance-only mode.",
        "Do not execute the blocked task, do not mutate files, and do not bypass runtime controls.",
        "Return one JSON object with a non-empty summary and optional metadata.",
      ].join(" "),
      userPrompt: [
        "Summarize the current governance action for a human-readable but runtime-safe tool reviewer output.",
        "Do not change the action status, ids, or capability keys.",
        "",
        "Governance action:",
        JSON.stringify(input.governanceAction, null, 2),
        "",
        "Current deterministic output:",
        JSON.stringify(input.defaultOutput, null, 2),
      ].join("\n"),
      parse: parseAdvice,
    });
  };
}
