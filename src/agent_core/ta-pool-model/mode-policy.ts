import type {
  ReviewDecisionKind,
  ReviewVote,
  TaPoolRiskLevel,
} from "../ta-pool-types/ta-pool-review.js";
import {
  toCanonicalTaPoolMode,
  type CanonicalTaPoolMode,
  type TaCapabilityTier,
  type TaPoolMode,
} from "../ta-pool-types/ta-pool-profile.js";

export const TA_MODE_REVIEWER_STRATEGIES = [
  "skip",
  "fast",
  "normal",
  "strict",
  "interrupt_only",
  "human_gate",
] as const;
export type TaModeReviewerStrategy = (typeof TA_MODE_REVIEWER_STRATEGIES)[number];

export const TA_MODE_EXECUTION_PATHS = [
  "baseline_fast_path",
  "review_path",
  "guarded_execution",
  "human_gate",
] as const;
export type TaModeExecutionPath = (typeof TA_MODE_EXECUTION_PATHS)[number];

export const TA_MODE_REVIEW_REQUIREMENTS = [
  "none",
  "explicit_review",
  "strict_review",
  "human_escalation",
  "interruptible_execution",
] as const;
export type TaModeReviewRequirement = (typeof TA_MODE_REVIEW_REQUIREMENTS)[number];

export const TA_MODE_REQUEST_PATHS = [
  "baseline",
  "review",
  "guarded",
  "human",
] as const;
export type TaModeRequestPath = (typeof TA_MODE_REQUEST_PATHS)[number];

export interface TaModeTierPolicy {
  mode: CanonicalTaPoolMode;
  tier: TaCapabilityTier;
  executionPath: TaModeExecutionPath;
  reviewerStrategy: TaModeReviewerStrategy;
  reviewRequirement: TaModeReviewRequirement;
  autoApprove: boolean;
  allowProvisioningRedirect: boolean;
  allowEmergencyInterrupt: boolean;
  defaultDecisionHint: ReviewDecisionKind;
}

export interface TaModeReviewerSnapshot {
  mode: CanonicalTaPoolMode;
  tier: TaCapabilityTier;
  requestPath: TaModeRequestPath;
  executionPath: TaModeExecutionPath;
  reviewerStrategy: TaModeReviewerStrategy;
  reviewRequirement: TaModeReviewRequirement;
  autoApprove: boolean;
  shouldSkipReview: boolean;
  requiresHumanGate: boolean;
  allowProvisioningRedirect: boolean;
  allowEmergencyInterrupt: boolean;
  defaultDecisionHint: ReviewDecisionKind;
}

export interface TaModePolicy extends TaModeReviewerSnapshot {
  allowsAutoGrant: boolean;
  requiresReview: boolean;
  allowsDeferred: boolean;
  escalatesToHuman: boolean;
}

export interface ModePolicyEntry {
  mode: CanonicalTaPoolMode;
  tier: TaCapabilityTier;
  decision:
    | "allow"
    | "review"
    | "review_strict"
    | "interrupt"
    | "escalate_to_human";
  requiresReview: boolean;
  allowsAutoGrant: boolean;
  requiresHuman: boolean;
  actsAsSafetyAirbag: boolean;
}
export type ModePolicyDecision = ModePolicyEntry["decision"];

export interface TaModeRiskPolicy extends TaModePolicy {
  riskLevel: TaPoolRiskLevel;
  baselineFastPath: boolean;
  defaultVote: ReviewVote;
}

export interface ModeRiskPolicyEntry {
  mode: CanonicalTaPoolMode;
  riskLevel: TaPoolRiskLevel;
  decision: "allow" | "review" | "deny" | "human_gate";
  baselineFastPath: boolean;
  defaultVote: ReviewVote;
}
export type ModeRiskDecision = ModeRiskPolicyEntry["decision"];

type ModeMatrixEntry = Omit<TaModeTierPolicy, "mode" | "tier">;

const MODE_MATRIX: Record<CanonicalTaPoolMode, Record<TaCapabilityTier, ModeMatrixEntry>> = {
  bapr: {
    B0: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B1: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B2: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B3: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
  },
  yolo: {
    B0: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B1: { executionPath: "baseline_fast_path", reviewerStrategy: "interrupt_only", reviewRequirement: "interruptible_execution", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: "approved" },
    B2: { executionPath: "guarded_execution", reviewerStrategy: "interrupt_only", reviewRequirement: "interruptible_execution", autoApprove: true, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: "approved" },
    B3: { executionPath: "guarded_execution", reviewerStrategy: "interrupt_only", reviewRequirement: "interruptible_execution", autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: "denied" },
  },
  permissive: {
    B0: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B1: { executionPath: "review_path", reviewerStrategy: "fast", reviewRequirement: "explicit_review", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "deferred" },
    B2: { executionPath: "review_path", reviewerStrategy: "normal", reviewRequirement: "explicit_review", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: "deferred" },
    B3: { executionPath: "guarded_execution", reviewerStrategy: "strict", reviewRequirement: "strict_review", autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: "denied" },
  },
  standard: {
    B0: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B1: { executionPath: "review_path", reviewerStrategy: "normal", reviewRequirement: "explicit_review", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "deferred" },
    B2: { executionPath: "review_path", reviewerStrategy: "strict", reviewRequirement: "strict_review", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: "deferred" },
    B3: { executionPath: "human_gate", reviewerStrategy: "human_gate", reviewRequirement: "human_escalation", autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: "escalated_to_human" },
  },
  restricted: {
    B0: { executionPath: "baseline_fast_path", reviewerStrategy: "skip", reviewRequirement: "none", autoApprove: true, allowProvisioningRedirect: false, allowEmergencyInterrupt: false, defaultDecisionHint: "approved" },
    B1: { executionPath: "human_gate", reviewerStrategy: "human_gate", reviewRequirement: "human_escalation", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: false, defaultDecisionHint: "escalated_to_human" },
    B2: { executionPath: "human_gate", reviewerStrategy: "human_gate", reviewRequirement: "human_escalation", autoApprove: false, allowProvisioningRedirect: true, allowEmergencyInterrupt: true, defaultDecisionHint: "escalated_to_human" },
    B3: { executionPath: "human_gate", reviewerStrategy: "human_gate", reviewRequirement: "human_escalation", autoApprove: false, allowProvisioningRedirect: false, allowEmergencyInterrupt: true, defaultDecisionHint: "escalated_to_human" },
  },
};

export function classifyRequestPath(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): TaModeRequestPath {
  const canonicalMode = toCanonicalTaPoolMode(params.mode);
  const policy = MODE_MATRIX[canonicalMode][params.tier];
  switch (policy.executionPath) {
    case "baseline_fast_path":
      return "baseline";
    case "review_path":
      return "review";
    case "guarded_execution":
      return "guarded";
    case "human_gate":
      return "human";
  }
}

export function getModeTierPolicy(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): TaModeTierPolicy {
  const canonicalMode = toCanonicalTaPoolMode(params.mode);
  return {
    mode: canonicalMode,
    tier: params.tier,
    ...MODE_MATRIX[canonicalMode][params.tier],
  };
}

export function getModePolicySnapshot(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): TaModeReviewerSnapshot {
  const policy = getModeTierPolicy(params);
  return {
    mode: policy.mode,
    tier: policy.tier,
    requestPath: classifyRequestPath(params),
    executionPath: policy.executionPath,
    reviewerStrategy: policy.reviewerStrategy,
    reviewRequirement: policy.reviewRequirement,
    autoApprove: policy.autoApprove,
    shouldSkipReview: policy.reviewerStrategy === "skip",
    requiresHumanGate: policy.executionPath === "human_gate",
    allowProvisioningRedirect: policy.allowProvisioningRedirect,
    allowEmergencyInterrupt: policy.allowEmergencyInterrupt,
    defaultDecisionHint: policy.defaultDecisionHint,
  };
}

export function getTaModePolicy(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): TaModePolicy {
  const snapshot = getModePolicySnapshot(params);
  return {
    ...snapshot,
    allowsAutoGrant: snapshot.autoApprove,
    requiresReview:
      snapshot.reviewRequirement === "explicit_review" ||
      snapshot.reviewRequirement === "strict_review" ||
      (snapshot.reviewRequirement === "interruptible_execution" && !snapshot.autoApprove),
    allowsDeferred:
      snapshot.reviewRequirement === "explicit_review" ||
      snapshot.reviewRequirement === "strict_review",
    escalatesToHuman: snapshot.requiresHumanGate,
  };
}

export function getModePolicyEntry(
  mode: TaPoolMode,
  tier: TaCapabilityTier,
): ModePolicyEntry {
  const snapshot = getModePolicySnapshot({ mode, tier });

  let decision: ModePolicyEntry["decision"];
  if (snapshot.requiresHumanGate) {
    decision = "escalate_to_human";
  } else if (snapshot.executionPath === "guarded_execution") {
    decision = "interrupt";
  } else if (snapshot.reviewRequirement === "strict_review") {
    decision = "review_strict";
  } else if (snapshot.reviewRequirement === "explicit_review") {
    decision = "review";
  } else {
    decision = "allow";
  }

  return {
    mode: snapshot.mode,
    tier,
    decision,
    requiresReview:
      snapshot.reviewRequirement === "explicit_review" ||
      snapshot.reviewRequirement === "strict_review",
    allowsAutoGrant: snapshot.autoApprove,
    requiresHuman: snapshot.requiresHumanGate,
    actsAsSafetyAirbag: snapshot.allowEmergencyInterrupt && snapshot.mode === "yolo",
  };
}

export function getModeRiskPolicyEntry(
  mode: TaPoolMode,
  riskLevel: TaPoolRiskLevel,
): ModeRiskPolicyEntry {
  const canonicalMode = toCanonicalTaPoolMode(mode);

  switch (canonicalMode) {
    case "bapr":
      return { mode: canonicalMode, riskLevel, decision: "allow", baselineFastPath: true, defaultVote: "allow" };
    case "yolo":
      if (riskLevel === "dangerous") {
        return { mode: canonicalMode, riskLevel, decision: "deny", baselineFastPath: false, defaultVote: "deny" };
      }
      return { mode: canonicalMode, riskLevel, decision: "allow", baselineFastPath: true, defaultVote: "allow" };
    case "permissive":
      if (riskLevel === "normal") {
        return { mode: canonicalMode, riskLevel, decision: "allow", baselineFastPath: true, defaultVote: "allow" };
      }
      if (riskLevel === "risky") {
        return { mode: canonicalMode, riskLevel, decision: "review", baselineFastPath: false, defaultVote: "defer" };
      }
      return { mode: canonicalMode, riskLevel, decision: "human_gate", baselineFastPath: false, defaultVote: "escalate_to_human" };
    case "standard":
      if (riskLevel === "normal") {
        return { mode: canonicalMode, riskLevel, decision: "review", baselineFastPath: true, defaultVote: "defer" };
      }
      if (riskLevel === "risky") {
        return { mode: canonicalMode, riskLevel, decision: "review", baselineFastPath: false, defaultVote: "defer" };
      }
      return { mode: canonicalMode, riskLevel, decision: "human_gate", baselineFastPath: false, defaultVote: "escalate_to_human" };
    case "restricted":
      return { mode: canonicalMode, riskLevel, decision: "human_gate", baselineFastPath: riskLevel === "normal", defaultVote: "escalate_to_human" };
  }
}

export function getModeRiskPolicy(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
  riskLevel: TaPoolRiskLevel;
}): TaModeRiskPolicy {
  return {
    ...getTaModePolicy({ mode: params.mode, tier: params.tier }),
    ...getModeRiskPolicyEntry(params.mode, params.riskLevel),
  };
}

export function getModePolicyMatrix(): Record<TaPoolMode, Record<TaCapabilityTier, ModePolicyDecision>> {
  return {
    strict: {
      B0: getModePolicyEntry("standard", "B0").decision,
      B1: getModePolicyEntry("standard", "B1").decision,
      B2: getModePolicyEntry("standard", "B2").decision,
      B3: getModePolicyEntry("standard", "B3").decision,
    },
    balanced: {
      B0: getModePolicyEntry("permissive", "B0").decision,
      B1: getModePolicyEntry("permissive", "B1").decision,
      B2: getModePolicyEntry("permissive", "B2").decision,
      B3: getModePolicyEntry("permissive", "B3").decision,
    },
    yolo: {
      B0: getModePolicyEntry("yolo", "B0").decision,
      B1: getModePolicyEntry("yolo", "B1").decision,
      B2: getModePolicyEntry("yolo", "B2").decision,
      B3: getModePolicyEntry("yolo", "B3").decision,
    },
    bapr: {
      B0: getModePolicyEntry("bapr", "B0").decision,
      B1: getModePolicyEntry("bapr", "B1").decision,
      B2: getModePolicyEntry("bapr", "B2").decision,
      B3: getModePolicyEntry("bapr", "B3").decision,
    },
    permissive: {
      B0: getModePolicyEntry("permissive", "B0").decision,
      B1: getModePolicyEntry("permissive", "B1").decision,
      B2: getModePolicyEntry("permissive", "B2").decision,
      B3: getModePolicyEntry("permissive", "B3").decision,
    },
    standard: {
      B0: getModePolicyEntry("standard", "B0").decision,
      B1: getModePolicyEntry("standard", "B1").decision,
      B2: getModePolicyEntry("standard", "B2").decision,
      B3: getModePolicyEntry("standard", "B3").decision,
    },
    restricted: {
      B0: getModePolicyEntry("restricted", "B0").decision,
      B1: getModePolicyEntry("restricted", "B1").decision,
      B2: getModePolicyEntry("restricted", "B2").decision,
      B3: getModePolicyEntry("restricted", "B3").decision,
    },
  };
}

export function getModeRiskPolicyMatrix(): Record<CanonicalTaPoolMode, Record<TaPoolRiskLevel, ModeRiskDecision>> {
  const risks: TaPoolRiskLevel[] = ["normal", "risky", "dangerous"];
  const modes: CanonicalTaPoolMode[] = ["bapr", "yolo", "permissive", "standard", "restricted"];
  return Object.fromEntries(
    modes.map((mode) => [
      mode,
      Object.fromEntries(risks.map((risk) => [risk, getModeRiskPolicyEntry(mode, risk).decision])) as Record<TaPoolRiskLevel, ModeRiskDecision>,
    ]),
  ) as Record<CanonicalTaPoolMode, Record<TaPoolRiskLevel, ModeRiskDecision>>;
}

export function listModePolicyMatrix(): TaModeTierPolicy[] {
  return (Object.entries(MODE_MATRIX) as Array<[CanonicalTaPoolMode, Record<TaCapabilityTier, ModeMatrixEntry>]>)
    .flatMap(([mode, tiers]) =>
      (Object.entries(tiers) as Array<[TaCapabilityTier, ModeMatrixEntry]>).map(([tier, policy]) => ({
        mode,
        tier,
        ...policy,
      })),
    );
}

export function listModeRiskPolicyMatrix(): TaModeRiskPolicy[] {
  const risks: TaPoolRiskLevel[] = ["normal", "risky", "dangerous"];
  return listModePolicyMatrix().flatMap((entry) =>
    risks.map((riskLevel) => getModeRiskPolicy({ mode: entry.mode, tier: entry.tier, riskLevel })),
  );
}

export function shouldSkipReview(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getModePolicySnapshot(params).shouldSkipReview;
}

export function shouldReviewForTier(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getTaModePolicy(params).requiresReview;
}

export function allowsAutoGrantForTier(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getTaModePolicy(params).allowsAutoGrant;
}

export function requiresHumanGate(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getModePolicySnapshot(params).requiresHumanGate;
}

export function supportsProvisioningRedirect(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getModePolicySnapshot(params).allowProvisioningRedirect;
}

export function allowsEmergencyInterrupt(params: {
  mode: TaPoolMode;
  tier: TaCapabilityTier;
}): boolean {
  return getModePolicySnapshot(params).allowEmergencyInterrupt;
}
