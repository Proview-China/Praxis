import type { RunId, SessionId } from "./kernel-session.js";

export const CHECKPOINT_TIERS = [
  "fast",
  "durable"
] as const;
export type CheckpointTier = (typeof CHECKPOINT_TIERS)[number];

export const CHECKPOINT_REASONS = [
  "manual",
  "pause",
  "before_capability",
  "after_capability",
  "failure",
  "completion",
  "recovery"
] as const;
export type CheckpointReason = (typeof CHECKPOINT_REASONS)[number];

export interface CheckpointRecord {
  checkpointId: string;
  sessionId: SessionId;
  runId: RunId;
  tier: CheckpointTier;
  reason: CheckpointReason;
  createdAt: string;
  basedOnEventId?: string;
  journalCursor?: string;
  pendingIntentId?: string;
  inputAssemblyHash?: string;
  snapshotRef?: string;
  metadata?: Record<string, unknown>;
}
