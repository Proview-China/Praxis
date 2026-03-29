import {
  getModePolicyEntry,
  getModeRiskPolicyEntry,
  type ModePolicyEntry,
  type ModeRiskPolicyEntry,
} from "./mode-policy.js";
import {
  createAgentCapabilityProfile,
  toCanonicalTaPoolMode,
  TA_CAPABILITY_TIERS,
  TA_POOL_MODES,
  type AgentCapabilityProfile,
  type CanonicalTaPoolMode,
  type TaCapabilityTier,
  type TaPoolMode,
} from "../ta-pool-types/ta-pool-profile.js";
import { TA_POOL_RISK_LEVELS, type TaPoolRiskLevel } from "../ta-pool-types/ta-pool-review.js";

export const TAP_AUTOMATION_DEPTHS = [
  "default",
  "prefer_auto",
  "prefer_human",
] as const;
export type TapAutomationDepth = (typeof TAP_AUTOMATION_DEPTHS)[number];

export const TAP_USER_EXPLANATION_STYLES = [
  "default",
  "plain_language",
] as const;
export type TapUserExplanationStyle =
  (typeof TAP_USER_EXPLANATION_STYLES)[number];

export const TA_GOVERNANCE_AGENT_ROLES = [
  "reviewer",
  "tool_reviewer",
  "tma",
] as const;
export type TaGovernanceAgentRole = (typeof TA_GOVERNANCE_AGENT_ROLES)[number];

export const TA_GOVERNANCE_AUTOMATION_LEVELS = TAP_AUTOMATION_DEPTHS;
export type TaGovernanceAutomationLevel = TapAutomationDepth;

export interface TapToolPolicyOverride {
  capabilitySelector: string;
  policy: "allow" | "review_only" | "deny" | "human_gate";
  reason?: string;
}

export interface TaUserOverrideContract {
  requestedMode?: TaPoolMode;
  automationDepth?: TapAutomationDepth;
  requireHumanOnRiskLevels?: TaPoolRiskLevel[];
  toolPolicyOverrides?: TapToolPolicyOverride[];
  explanationStyle?: TapUserExplanationStyle;
}

export type TapUserOverrideContract = TaUserOverrideContract;

export interface TapWorkspaceGovernancePolicy {
  workspaceMode: TaPoolMode;
  canonicalWorkspaceMode: CanonicalTaPoolMode;
  defaultAutomationDepth: TapAutomationDepth;
  defaultExplanationStyle: TapUserExplanationStyle;
}

export interface TapTaskGovernancePolicy {
  taskMode: TaPoolMode;
  canonicalTaskMode: CanonicalTaPoolMode;
  effectiveMode: CanonicalTaPoolMode;
  automationDepth: TapAutomationDepth;
  explanationStyle: TapUserExplanationStyle;
  requireHumanOnRiskLevels: TaPoolRiskLevel[];
  toolPolicyOverrides: TapToolPolicyOverride[];
}

export interface TapShared15ViewCell {
  mode: CanonicalTaPoolMode;
  riskLevel: TaPoolRiskLevel;
  reviewerDecision: ModeRiskPolicyEntry["decision"];
  reviewerStrategy: ModePolicyEntry["decision"];
  toolReviewerAuthority: "none" | "limited" | "standard" | "strict";
  tmaLane: "none" | "bootstrap" | "extended";
  autoContinue: boolean;
  requiresHumanGate: boolean;
}

export interface TapTierGovernanceSnapshot {
  tier: TaCapabilityTier;
  entry: ModePolicyEntry;
}

export interface TapGovernanceUserSurface {
  visibleMode: CanonicalTaPoolMode;
  automationDepth: TapAutomationDepth;
  explanationStyle: TapUserExplanationStyle;
  canToggleMode: boolean;
  canToggleAutomationDepth: boolean;
  canOverrideToolPolicy: boolean;
  requiresHumanOnRiskLevels: TaPoolRiskLevel[];
}

export interface TapGovernanceObject {
  objectId: string;
  poolName: "tap";
  workspacePolicy: TapWorkspaceGovernancePolicy;
  taskPolicy: TapTaskGovernancePolicy;
  profileSnapshot: AgentCapabilityProfile;
  shared15ViewMatrix: TapShared15ViewCell[];
  tierSnapshots: TapTierGovernanceSnapshot[];
  userSurface: TapGovernanceUserSurface;
}

export type TaGovernanceMatrixEntry = TapShared15ViewCell;
export type TaGovernanceTaskInstantiation = TapTaskGovernancePolicy;
export type TaPoolGovernanceWorkspacePolicy = TapWorkspaceGovernancePolicy;
export type TaPoolGovernanceObject = TapGovernanceObject;

export interface CreateTapGovernanceObjectInput {
  objectId?: string;
  profile?: AgentCapabilityProfile;
  workspaceMode?: TaPoolMode;
  taskMode?: TaPoolMode;
  userOverride?: TapUserOverrideContract;
}

function uniqueRiskLevels(values?: TaPoolRiskLevel[]): TaPoolRiskLevel[] {
  if (!values || values.length === 0) {
    return [];
  }
  return [...new Set(values)];
}

function resolveToolReviewerAuthority(
  mode: CanonicalTaPoolMode,
  riskLevel: TaPoolRiskLevel,
): TapShared15ViewCell["toolReviewerAuthority"] {
  if (mode === "bapr") {
    return "none";
  }
  if (mode === "restricted" || riskLevel === "dangerous") {
    return "strict";
  }
  if (mode === "standard") {
    return "standard";
  }
  return "limited";
}

function resolveTmaLane(
  mode: CanonicalTaPoolMode,
  riskLevel: TaPoolRiskLevel,
): TapShared15ViewCell["tmaLane"] {
  if (mode === "bapr") {
    return "extended";
  }
  if (riskLevel === "dangerous") {
    return "none";
  }
  if (riskLevel === "risky" || mode === "standard" || mode === "restricted") {
    return "extended";
  }
  return "bootstrap";
}

function createShared15ViewMatrix(): TapShared15ViewCell[] {
  const cells: TapShared15ViewCell[] = [];
  for (const mode of TA_POOL_MODES) {
    for (const riskLevel of TA_POOL_RISK_LEVELS) {
      const reviewerDecision = getModeRiskPolicyEntry(mode, riskLevel);
      const reviewerStrategy = getModePolicyEntry(mode, riskLevel === "normal" ? "B1" : riskLevel === "risky" ? "B2" : "B3");
      cells.push({
        mode,
        riskLevel,
        reviewerDecision: reviewerDecision.decision,
        reviewerStrategy: reviewerStrategy.decision,
        toolReviewerAuthority: resolveToolReviewerAuthority(mode, riskLevel),
        tmaLane: resolveTmaLane(mode, riskLevel),
        autoContinue: reviewerDecision.decision === "allow" && mode !== "restricted",
        requiresHumanGate: reviewerDecision.decision === "human_gate",
      });
    }
  }
  return cells;
}

export function createTapGovernanceObject(
  input: CreateTapGovernanceObjectInput = {},
): TapGovernanceObject {
  const profile = input.profile ?? createAgentCapabilityProfile({
    profileId: "tap-governance:default",
    agentClass: "tap-governance",
  });
  const workspaceMode = input.workspaceMode ?? profile.defaultMode;
  const canonicalWorkspaceMode = toCanonicalTaPoolMode(workspaceMode);
  const taskMode = input.taskMode ?? input.userOverride?.requestedMode ?? workspaceMode;
  const canonicalTaskMode = toCanonicalTaPoolMode(taskMode);
  const effectiveMode = input.userOverride?.requestedMode
    ? toCanonicalTaPoolMode(input.userOverride.requestedMode)
    : canonicalTaskMode;
  const automationDepth = input.userOverride?.automationDepth ?? "default";
  const explanationStyle = input.userOverride?.explanationStyle ?? "default";
  const requireHumanOnRiskLevels = uniqueRiskLevels(input.userOverride?.requireHumanOnRiskLevels);
  const toolPolicyOverrides = input.userOverride?.toolPolicyOverrides ?? [];

  return {
    objectId: input.objectId ?? `tap-governance:${profile.profileId}:${effectiveMode}`,
    poolName: "tap",
    workspacePolicy: {
      workspaceMode,
      canonicalWorkspaceMode,
      defaultAutomationDepth: "default",
      defaultExplanationStyle: "default",
    },
    taskPolicy: {
      taskMode,
      canonicalTaskMode,
      effectiveMode,
      automationDepth,
      explanationStyle,
      requireHumanOnRiskLevels,
      toolPolicyOverrides,
    },
    profileSnapshot: profile,
    shared15ViewMatrix: createShared15ViewMatrix(),
    tierSnapshots: TA_CAPABILITY_TIERS.map((tier) => ({
      tier,
      entry: getModePolicyEntry(effectiveMode, tier),
    })),
    userSurface: {
      visibleMode: effectiveMode,
      automationDepth,
      explanationStyle,
      canToggleMode: true,
      canToggleAutomationDepth: true,
      canOverrideToolPolicy: true,
      requiresHumanOnRiskLevels: requireHumanOnRiskLevels,
    },
  };
}

export function instantiateTapGovernanceObject(input: {
  governance: TapGovernanceObject;
  taskId: string;
  requestedMode?: TaPoolMode;
  userOverride?: TapUserOverrideContract;
}) {
  const effectiveMode = input.userOverride?.requestedMode
    ? toCanonicalTaPoolMode(input.userOverride.requestedMode)
    : input.requestedMode
      ? toCanonicalTaPoolMode(input.requestedMode)
      : input.governance.taskPolicy.effectiveMode;
  return createTapGovernanceObject({
    objectId: `${input.governance.objectId}:${input.taskId}`,
    profile: input.governance.profileSnapshot,
    workspaceMode: input.governance.workspacePolicy.workspaceMode,
    taskMode: effectiveMode,
    userOverride: input.userOverride ?? {
      requestedMode: effectiveMode,
      automationDepth: input.governance.taskPolicy.automationDepth,
      requireHumanOnRiskLevels: input.governance.taskPolicy.requireHumanOnRiskLevels,
      toolPolicyOverrides: input.governance.taskPolicy.toolPolicyOverrides,
      explanationStyle: input.governance.taskPolicy.explanationStyle,
    },
  });
}

export function listShared15ViewMatrix(): TapShared15ViewCell[] {
  return createShared15ViewMatrix();
}

export function createDefaultTaPoolGovernanceObject(
  input: CreateTapGovernanceObjectInput = {},
): TaPoolGovernanceObject {
  return createTapGovernanceObject(input);
}

export function instantiateTaGovernanceForTask(input: {
  governance: TaPoolGovernanceObject;
  taskId: string;
  requestedMode?: TaPoolMode;
  userOverride?: TaUserOverrideContract;
}): TaPoolGovernanceObject {
  return instantiateTapGovernanceObject({
    governance: input.governance,
    taskId: input.taskId,
    requestedMode: input.requestedMode,
    userOverride: input.userOverride,
  });
}
