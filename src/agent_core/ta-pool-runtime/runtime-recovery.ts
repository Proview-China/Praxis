import type { TaActivationAttemptRecord } from "./activation-types.js";
import type { TaHumanGateEvent, TaHumanGateState } from "./human-gate.js";
import type { TaPendingReplay } from "./replay-policy.js";
import {
  createPoolRuntimeSnapshots,
  createTapPoolRuntimeSnapshot,
  type PoolRuntimeSnapshots,
  type TapPoolRuntimeSnapshot,
  type TaResumeEnvelope,
} from "./runtime-snapshot.js";

export interface TapRuntimeHydratedState {
  humanGates: Map<string, TaHumanGateState>;
  humanGateEvents: Map<string, TaHumanGateEvent[]>;
  pendingReplays: Map<string, TaPendingReplay>;
  activationAttempts: Map<string, TaActivationAttemptRecord>;
  resumeEnvelopes: Map<string, TaResumeEnvelope>;
}

function assertUniqueKey(kind: string, key: string, seen: Set<string>): void {
  if (seen.has(key)) {
    throw new Error(`Duplicate ${kind} key detected during TAP runtime recovery: ${key}.`);
  }
  seen.add(key);
}

function cloneTapSnapshot(snapshot?: Partial<TapPoolRuntimeSnapshot>): TapPoolRuntimeSnapshot {
  return createTapPoolRuntimeSnapshot(snapshot);
}

export function serializeTapRuntimeSnapshot(
  input: Partial<TapPoolRuntimeSnapshot> = {},
): TapPoolRuntimeSnapshot {
  return cloneTapSnapshot(input);
}

export function serializePoolRuntimeSnapshots(
  input: Partial<PoolRuntimeSnapshots> = {},
): PoolRuntimeSnapshots {
  return createPoolRuntimeSnapshots(input);
}

export function hydrateTapRuntimeSnapshot(
  snapshot?: TapPoolRuntimeSnapshot,
): TapRuntimeHydratedState {
  const normalized = cloneTapSnapshot(snapshot);
  const humanGates = new Map<string, TaHumanGateState>();
  const humanGateEvents = new Map<string, TaHumanGateEvent[]>();
  const pendingReplays = new Map<string, TaPendingReplay>();
  const activationAttempts = new Map<string, TaActivationAttemptRecord>();
  const resumeEnvelopes = new Map<string, TaResumeEnvelope>();

  const seenGateIds = new Set<string>();
  for (const gate of normalized.humanGates) {
    assertUniqueKey("human gate", gate.gateId, seenGateIds);
    humanGates.set(gate.gateId, gate);
  }

  for (const event of normalized.humanGateEvents) {
    const history = humanGateEvents.get(event.gateId) ?? [];
    history.push(event);
    humanGateEvents.set(event.gateId, history);
  }
  for (const [gateId, history] of humanGateEvents) {
    history.sort((left, right) => Date.parse(left.createdAt) - Date.parse(right.createdAt));
    humanGateEvents.set(gateId, history);
  }

  const seenReplayIds = new Set<string>();
  for (const replay of normalized.pendingReplays) {
    assertUniqueKey("pending replay", replay.replayId, seenReplayIds);
    pendingReplays.set(replay.replayId, replay);
  }

  const seenAttemptIds = new Set<string>();
  for (const attempt of normalized.activationAttempts) {
    assertUniqueKey("activation attempt", attempt.attemptId, seenAttemptIds);
    activationAttempts.set(attempt.attemptId, attempt);
  }

  const seenResumeEnvelopeIds = new Set<string>();
  for (const envelope of normalized.resumeEnvelopes) {
    assertUniqueKey("resume envelope", envelope.envelopeId, seenResumeEnvelopeIds);
    resumeEnvelopes.set(envelope.envelopeId, envelope);
  }

  return {
    humanGates,
    humanGateEvents,
    pendingReplays,
    activationAttempts,
    resumeEnvelopes,
  };
}

export function hydratePoolRuntimeSnapshots(
  snapshots?: PoolRuntimeSnapshots,
): { tap: TapRuntimeHydratedState } {
  const normalized = createPoolRuntimeSnapshots(snapshots);
  return {
    tap: hydrateTapRuntimeSnapshot(normalized.tap),
  };
}
