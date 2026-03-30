import { executeTapAgentStructuredOutput, type TapAgentModelRoute } from "../integrations/tap-agent-model.js";
import type { ModelInferenceExecutionResult } from "../integrations/model-inference.js";
import {
  createDefaultProvisionerWorkerOutput,
  type ProvisionerWorkerBridge,
  type ProvisionerWorkerBridgeInput,
  type ProvisionerWorkerOutput,
} from "./provisioner-worker-bridge.js";

export interface ProvisionerWorkerModelAdvice {
  buildSummary: string;
  replayRecommendationReason: string;
  metadata?: Record<string, unknown>;
}

type ModelExecutor = (params: { intent: import("../types/index.js").ModelInferenceIntent }) => Promise<ModelInferenceExecutionResult>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseAdvice(value: unknown): ProvisionerWorkerModelAdvice {
  if (!isRecord(value)) {
    throw new Error("Provisioner model output must be a plain object.");
  }
  if (typeof value.buildSummary !== "string" || !value.buildSummary.trim()) {
    throw new Error("Provisioner model output requires a non-empty buildSummary.");
  }
  if (
    typeof value.replayRecommendationReason !== "string"
    || !value.replayRecommendationReason.trim()
  ) {
    throw new Error("Provisioner model output requires a non-empty replayRecommendationReason.");
  }
  return {
    buildSummary: value.buildSummary.trim(),
    replayRecommendationReason: value.replayRecommendationReason.trim(),
    metadata: isRecord(value.metadata) ? value.metadata : undefined,
  };
}

export function createModelBackedProvisionerWorkerBridge(options: {
  executor: ModelExecutor;
  route?: Partial<TapAgentModelRoute>;
}): ProvisionerWorkerBridge {
  return async (input: ProvisionerWorkerBridgeInput): Promise<ProvisionerWorkerOutput> => {
    const defaultOutput = createDefaultProvisionerWorkerOutput(input);
    const advice = await executeTapAgentStructuredOutput({
      executor: options.executor,
      sessionId: `tma-model:${input.request.provisionId}`,
      runId: `tma-model:${input.request.provisionId}`,
      workerKind: "tap-tma",
      route: options.route,
      systemPrompt: [
        "You are the TAP TMA builder agent.",
        "Stay inside capability_build_only boundaries.",
        "Do not execute the blocked user task, do not approve activation, and do not widen side effects.",
        "Return one JSON object with buildSummary, replayRecommendationReason, and optional metadata.",
      ].join(" "),
      userPrompt: [
        "Refine the package-building summary and replay rationale for this provision job.",
        "Do not invent artifacts, ids, policies, or activation changes.",
        "",
        "Prompt pack:",
        JSON.stringify(input.promptPack, null, 2),
        "",
        "Worker envelope:",
        JSON.stringify(input.envelope, null, 2),
        "",
        "Current deterministic output:",
        JSON.stringify(defaultOutput, null, 2),
      ].join("\n"),
      parse: parseAdvice,
    });

    return {
      ...defaultOutput,
      buildSummary: advice.buildSummary,
      replayRecommendation: {
        ...defaultOutput.replayRecommendation,
        reason: advice.replayRecommendationReason,
      },
      metadata: {
        ...(defaultOutput.metadata ?? {}),
        ...(advice.metadata ? { provisionerModelMetadata: advice.metadata } : {}),
        modelBacked: true,
      },
    };
  };
}
