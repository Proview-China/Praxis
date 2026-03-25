import type {
  AccessRequest,
  ProvisionArtifactBundle,
  ReplayPolicy,
} from "../ta-pool-types/index.js";

export const TA_REPLAY_STATUSES = [
  "pending",
  "skipped",
] as const;
export type TaReplayStatus = (typeof TA_REPLAY_STATUSES)[number];

export const TA_REPLAY_NEXT_ACTIONS = [
  "none",
  "manual",
  "verify_then_auto",
  "re_review_then_dispatch",
] as const;
export type TaReplayNextAction = (typeof TA_REPLAY_NEXT_ACTIONS)[number];

export const TA_REPLAY_TRIGGERS = [
  "manual.resume",
  "human_gate.approved",
  "verification.passed",
  "re_review.completed",
] as const;
export type TaReplayTrigger = (typeof TA_REPLAY_TRIGGERS)[number];

export interface TaPendingReplay {
  replayId: string;
  policy: ReplayPolicy;
  status: TaReplayStatus;
  nextAction: TaReplayNextAction;
  requestId: string;
  provisionId: string;
  capabilityKey: string;
  reason: string;
  createdAt: string;
  updatedAt: string;
  acceptedTriggers: TaReplayTrigger[];
  metadata?: Record<string, unknown>;
}

export interface CreateTaPendingReplayInput {
  replayId: string;
  request: Pick<AccessRequest, "requestId" | "requestedCapabilityKey">;
  provisionBundle: Pick<ProvisionArtifactBundle, "provisionId" | "replayPolicy">;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export function replayPolicyToNextAction(
  policy: ReplayPolicy,
): TaReplayNextAction {
  switch (policy) {
    case "none":
      return "none";
    case "manual":
      return "manual";
    case "auto_after_verify":
      return "verify_then_auto";
    case "re_review_then_dispatch":
      return "re_review_then_dispatch";
  }
}

export function describeReplayPolicy(policy: ReplayPolicy): string {
  switch (policy) {
    case "none":
      return "Replay is disabled for this provision result.";
    case "manual":
      return "Replay is staged and can continue only after an explicit manual resume or approved human handoff.";
    case "auto_after_verify":
      return "Replay is staged for automatic continue after verification succeeds.";
    case "re_review_then_dispatch":
      return "Replay is staged for re-review before dispatch once activation is ready.";
  }
}

export function replayNextActionToTriggers(
  nextAction: TaReplayNextAction,
): TaReplayTrigger[] {
  switch (nextAction) {
    case "none":
      return [];
    case "manual":
      return ["manual.resume", "human_gate.approved"];
    case "verify_then_auto":
      return ["verification.passed"];
    case "re_review_then_dispatch":
      return ["re_review.completed"];
  }
}

export function replayPolicyToTriggers(
  policy: ReplayPolicy,
): TaReplayTrigger[] {
  return replayNextActionToTriggers(replayPolicyToNextAction(policy));
}

export function canReplayProceedFromTrigger(params: {
  replay: Pick<TaPendingReplay, "status" | "acceptedTriggers">;
  trigger: TaReplayTrigger;
}): boolean {
  return params.replay.status === "pending" && params.replay.acceptedTriggers.includes(params.trigger);
}

export function createTaPendingReplay(
  input: CreateTaPendingReplayInput,
): TaPendingReplay {
  const policy = input.provisionBundle.replayPolicy ?? "re_review_then_dispatch";
  const nextAction = replayPolicyToNextAction(policy);
  const status: TaReplayStatus = nextAction === "none" ? "skipped" : "pending";

  return {
    replayId: assertNonEmpty(input.replayId, "Replay replayId"),
    policy,
    status,
    nextAction,
    requestId: assertNonEmpty(input.request.requestId, "Replay requestId"),
    provisionId: assertNonEmpty(input.provisionBundle.provisionId, "Replay provisionId"),
    capabilityKey: assertNonEmpty(input.request.requestedCapabilityKey, "Replay capabilityKey"),
    reason: describeReplayPolicy(policy),
    createdAt: input.createdAt,
    updatedAt: input.createdAt,
    acceptedTriggers: replayPolicyToTriggers(policy),
    metadata: input.metadata,
  };
}
