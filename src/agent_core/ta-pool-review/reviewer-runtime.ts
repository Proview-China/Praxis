import type {
  AccessRequest,
  AgentCapabilityProfile,
  ReviewDecision,
} from "../ta-pool-types/index.js";
import type { ReviewContextApertureSnapshot } from "../ta-pool-context/context-aperture.js";
import {
  createReviewContextApertureSnapshot,
} from "../ta-pool-context/context-aperture.js";
import { formatPlainLanguageRisk } from "../ta-pool-context/plain-language-risk.js";
import type { ReviewRoutingResult } from "./review-routing.js";
import { routeAccessRequest } from "./review-routing.js";
import type {
  EvaluateReviewDecisionInput,
  ReviewDecisionEngineInventory,
} from "./review-decision-engine.js";
import { evaluateReviewDecision } from "./review-decision-engine.js";
import {
  compileReviewerWorkerVote,
  createReviewerWorkerEnvelope,
  createReviewerWorkerPromptPack,
  type ReviewerWorkerVoteOutput,
} from "./reviewer-worker-bridge.js";

export interface ReviewerRuntimeSubmitInput {
  request: AccessRequest;
  profile: AgentCapabilityProfile;
  inventory?: ReviewDecisionEngineInventory;
  reviewContext?: ReviewContextApertureSnapshot;
}

export interface ReviewerRuntimeHookInput {
  request: AccessRequest;
  profile: AgentCapabilityProfile;
  inventory?: ReviewDecisionEngineInventory;
  reviewContext: ReviewContextApertureSnapshot;
  routed: ReviewRoutingResult;
  fallback: EvaluateReviewDecisionInput;
  promptPack: ReturnType<typeof createReviewerWorkerPromptPack>;
  workerEnvelope: ReturnType<typeof createReviewerWorkerEnvelope>;
}

export type ReviewerRuntimeLlmHook = (
  input: ReviewerRuntimeHookInput,
) => Promise<ReviewerWorkerVoteOutput | undefined>;

export interface ReviewerRuntimeOptions {
  llmReviewerHook?: ReviewerRuntimeLlmHook;
}

function normalizeStringArray(values?: string[]): string[] {
  if (!values) {
    return [];
  }

  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function inventoryTracksCapabilityLifecycle(
  inventory: ReviewDecisionEngineInventory | undefined,
  capabilityKey: string,
): boolean {
  return [
    ...(inventory?.availableCapabilityKeys ?? []),
    ...(inventory?.pendingProvisionKeys ?? []),
    ...(inventory?.readyProvisionAssetKeys ?? []),
    ...(inventory?.activatingProvisionAssetKeys ?? []),
    ...(inventory?.activeProvisionAssetKeys ?? []),
  ].includes(capabilityKey);
}

export class ReviewerRuntime {
  readonly #llmReviewerHook?: ReviewerRuntimeLlmHook;

  constructor(options: ReviewerRuntimeOptions = {}) {
    this.#llmReviewerHook = options.llmReviewerHook;
  }

  hasLlmReviewerHook(): boolean {
    return this.#llmReviewerHook !== undefined;
  }

  async submit(input: ReviewerRuntimeSubmitInput): Promise<ReviewDecision> {
    const requestedAction = input.request.requestedAction
      ?? `request capability ${input.request.requestedCapabilityKey}`;
    const plainLanguageRisk = input.request.plainLanguageRisk
      ?? formatPlainLanguageRisk({
        requestedAction,
        capabilityKey: input.request.requestedCapabilityKey,
        riskLevel: input.request.riskLevel ?? "normal",
      });
    const reviewContext = input.reviewContext ?? createReviewContextApertureSnapshot({
      projectSummary: {
        summary: "Project summary is still placeholder-only in Wave 1 reviewer runtime.",
        status: "placeholder",
        source: "reviewer-runtime-default",
      },
      runSummary: {
        summary: `${input.request.sessionId}/${input.request.runId}`,
        status: "ready",
        source: "reviewer-runtime-default",
      },
      profileSnapshot: input.profile,
      inventorySnapshot: {
        totalCapabilities: normalizeStringArray([
          ...(input.inventory?.availableCapabilityKeys ?? []),
          ...(input.inventory?.readyProvisionAssetKeys ?? []),
          ...(input.inventory?.activatingProvisionAssetKeys ?? []),
          ...(input.inventory?.activeProvisionAssetKeys ?? []),
        ]).length,
        availableCapabilityKeys: input.inventory?.availableCapabilityKeys ?? [],
        pendingProvisionKeys: input.inventory?.pendingProvisionKeys,
        metadata: {
          readyProvisionAssetKeys: input.inventory?.readyProvisionAssetKeys ?? [],
          activatingProvisionAssetKeys: input.inventory?.activatingProvisionAssetKeys ?? [],
          activeProvisionAssetKeys: input.inventory?.activeProvisionAssetKeys ?? [],
        },
      },
      memorySummaryPlaceholder: {
        summary: "Memory summary is still placeholder-only in Wave 1 reviewer runtime.",
        status: "placeholder",
        source: "reviewer-runtime-default",
      },
      userIntentSummary: {
        summary: input.request.reason,
        status: "ready",
        source: "access-request",
      },
      riskSummary: {
        riskLevel: input.request.riskLevel ?? plainLanguageRisk.riskLevel,
        requestedAction,
        plainLanguageRisk,
        source: input.request.plainLanguageRisk ? "request" : "generated",
      },
      modeSnapshot: input.request.mode,
      metadata: {
        requestedCapabilityKey: input.request.requestedCapabilityKey,
      },
    });

    const routed = routeAccessRequest({
      profile: input.profile,
      request: input.request,
      capabilityAvailable: inventoryTracksCapabilityLifecycle(
        input.inventory,
        input.request.requestedCapabilityKey,
      ),
    });

    if (routed.outcome !== "review_required") {
      return routed.decision;
    }

    const fallback: EvaluateReviewDecisionInput = {
      request: input.request,
      profile: input.profile,
      inventory: input.inventory,
    };

    if (this.#llmReviewerHook) {
      const promptPack = createReviewerWorkerPromptPack();
      const workerEnvelope = createReviewerWorkerEnvelope({
        request: input.request,
        profile: input.profile,
        inventory: input.inventory,
        reviewContext,
        routed,
      });
      const hookDecision = await this.#llmReviewerHook({
        request: input.request,
        profile: input.profile,
        inventory: input.inventory,
        reviewContext,
        routed,
        fallback,
        promptPack,
        workerEnvelope,
      });
      if (hookDecision) {
        return compileReviewerWorkerVote({
          request: input.request,
          promptPack,
          output: hookDecision,
        });
      }
    }

    return evaluateReviewDecision(fallback);
  }
}

export function createReviewerRuntime(options: ReviewerRuntimeOptions = {}): ReviewerRuntime {
  return new ReviewerRuntime(options);
}
