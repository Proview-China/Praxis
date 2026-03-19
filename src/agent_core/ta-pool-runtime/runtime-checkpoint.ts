import type {
  CheckpointSnapshotData,
  StoredCheckpoint,
} from "../checkpoint/index.js";
import type { TaActivationAttemptRecord } from "./activation-types.js";
import type { TaHumanGateEvent, TaHumanGateState } from "./human-gate.js";
import type { TaPendingReplay } from "./replay-policy.js";
import type {
  PoolRuntimeSnapshots,
  TapPoolRuntimeSnapshot,
  TaResumeEnvelope,
} from "./runtime-snapshot.js";
import {
  createPoolRuntimeSnapshots,
  createTapPoolRuntimeSnapshot,
} from "./runtime-snapshot.js";

function isStoredCheckpoint(
  source: CheckpointSnapshotData | StoredCheckpoint,
): source is StoredCheckpoint {
  return "record" in source;
}

export interface TapRuntimeSnapshotStateInput {
  humanGates: Iterable<TaHumanGateState>;
  humanGateEvents: Iterable<TaHumanGateEvent> | Map<string, readonly TaHumanGateEvent[]>;
  pendingReplays: Iterable<TaPendingReplay>;
  activationAttempts: Iterable<TaActivationAttemptRecord>;
  resumeEnvelopes: Iterable<TaResumeEnvelope>;
  metadata?: Record<string, unknown>;
}

function flattenHumanGateEvents(
  input: TapRuntimeSnapshotStateInput["humanGateEvents"],
): TaHumanGateEvent[] {
  if (input instanceof Map) {
    return [...input.values()].flatMap((events) => [...events]);
  }
  return [...input];
}

export function createTapRuntimeSnapshotFromState(
  input: TapRuntimeSnapshotStateInput,
): TapPoolRuntimeSnapshot {
  return createTapPoolRuntimeSnapshot({
    humanGates: [...input.humanGates],
    humanGateEvents: flattenHumanGateEvents(input.humanGateEvents),
    pendingReplays: [...input.pendingReplays],
    activationAttempts: [...input.activationAttempts],
    resumeEnvelopes: [...input.resumeEnvelopes],
    metadata: input.metadata,
  });
}

export function mergeTapRuntimeSnapshotIntoCheckpoint(
  snapshot: CheckpointSnapshotData,
  tap: TapPoolRuntimeSnapshot,
): CheckpointSnapshotData {
  return {
    ...snapshot,
    poolRuntimeSnapshots: createPoolRuntimeSnapshots({
      ...(snapshot.poolRuntimeSnapshots ?? {}),
      tap,
    }),
  };
}

export function readTapRuntimeSnapshotFromCheckpoint(
  source: CheckpointSnapshotData | StoredCheckpoint | undefined,
): TapPoolRuntimeSnapshot | undefined {
  if (!source) {
    return undefined;
  }

  const snapshot = isStoredCheckpoint(source) ? source.snapshot : source;
  return snapshot?.poolRuntimeSnapshots?.tap
    ? createTapPoolRuntimeSnapshot(snapshot.poolRuntimeSnapshots.tap)
    : undefined;
}

export function readPoolRuntimeSnapshotsFromCheckpoint(
  source: CheckpointSnapshotData | StoredCheckpoint | undefined,
): PoolRuntimeSnapshots | undefined {
  if (!source) {
    return undefined;
  }

  const snapshot = isStoredCheckpoint(source) ? source.snapshot : source;
  return snapshot?.poolRuntimeSnapshots
    ? createPoolRuntimeSnapshots(snapshot.poolRuntimeSnapshots)
    : undefined;
}
