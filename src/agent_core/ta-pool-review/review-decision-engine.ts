import {
  createReviewDecision,
  isCapabilityDeniedByProfile,
  type AccessRequest,
  type AgentCapabilityProfile,
  type ReviewDecision,
} from "../ta-pool-types/index.js";
import { getModePolicyEntry } from "../ta-pool-model/mode-policy.js";
import { resolveBaselineCapability } from "../ta-pool-model/profile-baseline.js";

export interface ReviewDecisionEngineInventory {
  availableCapabilityKeys?: string[];
  pendingProvisionKeys?: string[];
  readyProvisionAssetKeys?: string[];
  activatingProvisionAssetKeys?: string[];
  activeProvisionAssetKeys?: string[];
}

export interface EvaluateReviewDecisionInput {
  request: AccessRequest;
  profile: AgentCapabilityProfile;
  inventory?: ReviewDecisionEngineInventory;
  decisionId?: string;
  reviewerId?: string;
  createdAt?: string;
  defaultEscalationTarget?: string;
}

export type ReviewDecisionEngineInput = EvaluateReviewDecisionInput;

function normalizeStringArray(values?: string[]): string[] {
  if (!values) {
    return [];
  }
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function hasCapability(inventory: ReviewDecisionEngineInventory | undefined, capabilityKey: string): boolean {
  return normalizeStringArray(inventory?.availableCapabilityKeys).includes(capabilityKey);
}

function isPendingProvision(inventory: ReviewDecisionEngineInventory | undefined, capabilityKey: string): boolean {
  return normalizeStringArray(inventory?.pendingProvisionKeys).includes(capabilityKey);
}

function getProvisionAssetState(
  inventory: ReviewDecisionEngineInventory | undefined,
  capabilityKey: string,
): "ready_for_review" | "activating" | "active" | undefined {
  if (normalizeStringArray(inventory?.readyProvisionAssetKeys).includes(capabilityKey)) {
    return "ready_for_review";
  }

  if (normalizeStringArray(inventory?.activatingProvisionAssetKeys).includes(capabilityKey)) {
    return "activating";
  }

  if (normalizeStringArray(inventory?.activeProvisionAssetKeys).includes(capabilityKey)) {
    return "active";
  }

  return undefined;
}

export function evaluateReviewDecision(input: EvaluateReviewDecisionInput): ReviewDecision {
  const {
    request,
    profile,
    inventory,
    decisionId = `${request.requestId}:decision`,
    reviewerId,
    createdAt = request.createdAt,
    defaultEscalationTarget = "human-review",
  } = input;

  if (isCapabilityDeniedByProfile({
    profile,
    capabilityKey: request.requestedCapabilityKey,
  })) {
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      decision: "denied",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} is denied by the active profile.`,
      createdAt,
    });
  }

  const baselineResolution = resolveBaselineCapability({
    profile,
    capabilityKey: request.requestedCapabilityKey,
    requestedTier: request.requestedTier,
  });
  if (baselineResolution.status === "baseline_allowed") {
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      vote: "allow",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} is in the baseline set.`,
      grantCompilerDirective: {
        grantedTier: request.requestedTier,
        grantedScope: request.requestedScope,
        constraints: {
          source: "baseline-fast-path",
        },
      },
      createdAt,
    });
  }

  if (isPendingProvision(inventory, request.requestedCapabilityKey)) {
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      decision: "deferred",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} is already provisioning.`,
      deferredReason: "Awaiting provision artifact bundle completion.",
      createdAt,
    });
  }

  const provisionAssetState = getProvisionAssetState(inventory, request.requestedCapabilityKey);
  if (provisionAssetState) {
    const deferredReason = provisionAssetState === "ready_for_review"
      ? "Provision asset is ready for review/activation; replay stays pending in this wave."
      : provisionAssetState === "activating"
        ? "Provision asset is currently in activation handoff."
        : "Provision asset is indexed as active but is not mounted into the capability pool yet.";
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      decision: "deferred",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} already has a ${provisionAssetState} provision asset.`,
      deferredReason,
      createdAt,
    });
  }

  if (!hasCapability(inventory, request.requestedCapabilityKey)) {
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      decision: "redirected_to_provisioning",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} is not currently available.`,
      provisionCapabilityKey: request.requestedCapabilityKey,
      createdAt,
    });
  }

  const policy = getModePolicyEntry(request.mode, request.requestedTier);
  if (policy.requiresHuman) {
    return createReviewDecision({
      decisionId,
      requestId: request.requestId,
      decision: "escalated_to_human",
      reviewerId,
      mode: request.mode,
      reason: `Capability ${request.requestedCapabilityKey} at tier ${request.requestedTier} requires human review in ${request.mode} mode.`,
      escalationTarget: defaultEscalationTarget,
      createdAt,
    });
  }

  return createReviewDecision({
    decisionId,
    requestId: request.requestId,
    vote: "allow",
    reviewerId,
    mode: request.mode,
    reason: `Capability ${request.requestedCapabilityKey} is available and allowed under ${request.mode} mode.`,
    grantCompilerDirective: {
      grantedTier: request.requestedTier,
      grantedScope: request.requestedScope,
      constraints: {
        source: policy.allowsAutoGrant ? "mode-auto-grant" : "review-approved",
        modeDecision: policy.decision,
      },
    },
    createdAt,
  });
}
