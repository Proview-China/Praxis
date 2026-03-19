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
      return "Replay is staged but must be resumed manually in a later wave.";
    case "auto_after_verify":
      return "Replay is staged for auto-after-verify, but automatic re-dispatch is still a TODO in this wave.";
    case "re_review_then_dispatch":
      return "Replay is staged for re-review-then-dispatch, but the actual re-review loop is still a TODO in this wave.";
  }
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
    metadata: input.metadata,
  };
}
