import type {
  TaCapabilityTier,
  TaPoolMode,
} from "../ta-pool-types/index.js";
import type {
  TaActivationAttemptStatus,
} from "./activation-types.js";
import type {
  TaReplayNextAction,
  TaReplayStatus,
} from "./replay-policy.js";
import {
  createTapPoolRuntimeSnapshot,
  type TapPoolRuntimeSnapshot,
  type TaResumeEnvelope,
} from "./runtime-snapshot.js";

export const TAP_GOVERNANCE_CAPABILITY_STAGES = [
  "idle",
  "waiting_human",
  "activation_failed",
  "activation_pending",
  "replay_pending",
  "resume_pending",
  "settled",
] as const;
export type TapGovernanceCapabilityStage =
  (typeof TAP_GOVERNANCE_CAPABILITY_STAGES)[number];

export interface TapGovernanceCounts {
  humanGates: {
    total: number;
    waitingHuman: number;
    approved: number;
    rejected: number;
  };
  pendingReplays: {
    total: number;
    pending: number;
    skipped: number;
    manual: number;
    verifyThenAuto: number;
    reReviewThenDispatch: number;
    none: number;
  };
  activationAttempts: {
    total: number;
    pending: number;
    started: number;
    succeeded: number;
    failed: number;
    rolledBack: number;
    retryableFailures: number;
  };
  resumeEnvelopes: {
    total: number;
    humanGate: number;
    replay: number;
    activation: number;
  };
}

export interface TapCapabilityGovernanceSnapshot {
  capabilityKey: string;
  stage: TapGovernanceCapabilityStage;
  activeBlockers: Exclude<TapGovernanceCapabilityStage, "idle" | "settled">[];
  requestIds: string[];
  sessionIds: string[];
  runIds: string[];
  modes: TaPoolMode[];
  requestedTiers: TaCapabilityTier[];
  humanGates: TapGovernanceCounts["humanGates"];
  pendingReplays: TapGovernanceCounts["pendingReplays"];
  activationAttempts: TapGovernanceCounts["activationAttempts"] & {
    targetPools: string[];
  };
  resumeEnvelopes: TapGovernanceCounts["resumeEnvelopes"];
}

export interface TapGovernanceSnapshot {
  counts: TapGovernanceCounts;
  capabilities: TapCapabilityGovernanceSnapshot[];
  blockingCapabilityKeys: string[];
  metadata?: Record<string, unknown>;
}

interface CapabilityAccumulator {
  capabilityKey: string;
  requestIds: Set<string>;
  sessionIds: Set<string>;
  runIds: Set<string>;
  modes: Set<TaPoolMode>;
  requestedTiers: Set<TaCapabilityTier>;
  humanGates: TapGovernanceCounts["humanGates"];
  pendingReplays: TapGovernanceCounts["pendingReplays"];
  activationAttempts: TapGovernanceCounts["activationAttempts"] & {
    targetPools: Set<string>;
  };
  resumeEnvelopes: TapGovernanceCounts["resumeEnvelopes"];
}

const STAGE_PRIORITY: Record<TapGovernanceCapabilityStage, number> = {
  waiting_human: 0,
  activation_failed: 1,
  activation_pending: 2,
  replay_pending: 3,
  resume_pending: 4,
  settled: 5,
  idle: 6,
};

function createEmptyCounts(): TapGovernanceCounts {
  return {
    humanGates: {
      total: 0,
      waitingHuman: 0,
      approved: 0,
      rejected: 0,
    },
    pendingReplays: {
      total: 0,
      pending: 0,
      skipped: 0,
      manual: 0,
      verifyThenAuto: 0,
      reReviewThenDispatch: 0,
      none: 0,
    },
    activationAttempts: {
      total: 0,
      pending: 0,
      started: 0,
      succeeded: 0,
      failed: 0,
      rolledBack: 0,
      retryableFailures: 0,
    },
    resumeEnvelopes: {
      total: 0,
      humanGate: 0,
      replay: 0,
      activation: 0,
    },
  };
}

function createCapabilityAccumulator(capabilityKey: string): CapabilityAccumulator {
  return {
    capabilityKey,
    requestIds: new Set<string>(),
    sessionIds: new Set<string>(),
    runIds: new Set<string>(),
    modes: new Set<TaPoolMode>(),
    requestedTiers: new Set<TaCapabilityTier>(),
    humanGates: createEmptyCounts().humanGates,
    pendingReplays: createEmptyCounts().pendingReplays,
    activationAttempts: {
      ...createEmptyCounts().activationAttempts,
      targetPools: new Set<string>(),
    },
    resumeEnvelopes: createEmptyCounts().resumeEnvelopes,
  };
}

function getCapabilityAccumulator(
  byCapability: Map<string, CapabilityAccumulator>,
  capabilityKey: string,
): CapabilityAccumulator {
  const current = byCapability.get(capabilityKey);
  if (current) {
    return current;
  }

  const created = createCapabilityAccumulator(capabilityKey);
  byCapability.set(capabilityKey, created);
  return created;
}

function incrementReplayAction(
  target: TapGovernanceCounts["pendingReplays"],
  nextAction: TaReplayNextAction,
): void {
  switch (nextAction) {
    case "manual":
      target.manual += 1;
      return;
    case "verify_then_auto":
      target.verifyThenAuto += 1;
      return;
    case "re_review_then_dispatch":
      target.reReviewThenDispatch += 1;
      return;
    case "none":
      target.none += 1;
      return;
  }
}

function incrementReplayStatus(
  target: TapGovernanceCounts["pendingReplays"],
  status: TaReplayStatus,
): void {
  switch (status) {
    case "pending":
      target.pending += 1;
      return;
    case "skipped":
      target.skipped += 1;
      return;
  }
}

function incrementActivationStatus(
  target: TapGovernanceCounts["activationAttempts"],
  status: TaActivationAttemptStatus,
): void {
  switch (status) {
    case "pending":
      target.pending += 1;
      return;
    case "started":
      target.started += 1;
      return;
    case "succeeded":
      target.succeeded += 1;
      return;
    case "failed":
      target.failed += 1;
      return;
    case "rolled_back":
      target.rolledBack += 1;
      return;
  }
}

function incrementResumeSource(
  target: TapGovernanceCounts["resumeEnvelopes"],
  source: TaResumeEnvelope["source"],
): void {
  switch (source) {
    case "human_gate":
      target.humanGate += 1;
      return;
    case "replay":
      target.replay += 1;
      return;
    case "activation":
      target.activation += 1;
      return;
  }
}

function summarizeStage(
  summary: Pick<
    TapCapabilityGovernanceSnapshot,
    "humanGates" | "activationAttempts" | "pendingReplays" | "resumeEnvelopes"
  >,
): Exclude<TapGovernanceCapabilityStage, "idle"> {
  if (summary.humanGates.waitingHuman > 0) {
    return "waiting_human";
  }
  if (summary.activationAttempts.failed > 0) {
    return "activation_failed";
  }
  if (summary.activationAttempts.pending > 0 || summary.activationAttempts.started > 0) {
    return "activation_pending";
  }
  if (summary.pendingReplays.pending > 0) {
    return "replay_pending";
  }
  if (summary.resumeEnvelopes.total > 0) {
    return "resume_pending";
  }
  return "settled";
}

function toSortedArray<T extends string>(values: Set<T>): T[] {
  return [...values].sort((left, right) => left.localeCompare(right));
}

function toCapabilitySnapshot(
  accumulator: CapabilityAccumulator,
): TapCapabilityGovernanceSnapshot {
  const snapshot: TapCapabilityGovernanceSnapshot = {
    capabilityKey: accumulator.capabilityKey,
    stage: "settled",
    activeBlockers: [],
    requestIds: toSortedArray(accumulator.requestIds),
    sessionIds: toSortedArray(accumulator.sessionIds),
    runIds: toSortedArray(accumulator.runIds),
    modes: toSortedArray(accumulator.modes),
    requestedTiers: toSortedArray(accumulator.requestedTiers),
    humanGates: { ...accumulator.humanGates },
    pendingReplays: { ...accumulator.pendingReplays },
    activationAttempts: {
      ...accumulator.activationAttempts,
      targetPools: toSortedArray(accumulator.activationAttempts.targetPools),
    },
    resumeEnvelopes: { ...accumulator.resumeEnvelopes },
  };

  snapshot.stage = summarizeStage(snapshot);
  snapshot.activeBlockers =
    snapshot.stage === "settled"
      ? []
      : [snapshot.stage];
  return snapshot;
}

export function createTapGovernanceSnapshot(
  snapshot?: Partial<TapPoolRuntimeSnapshot>,
): TapGovernanceSnapshot {
  const normalized = createTapPoolRuntimeSnapshot(snapshot);
  const counts = createEmptyCounts();
  const byCapability = new Map<string, CapabilityAccumulator>();

  for (const gate of normalized.humanGates) {
    counts.humanGates.total += 1;
    const capability = getCapabilityAccumulator(byCapability, gate.capabilityKey);
    capability.requestIds.add(gate.requestId);
    capability.sessionIds.add(gate.sessionId);
    capability.runIds.add(gate.runId);
    capability.modes.add(gate.mode);
    capability.requestedTiers.add(gate.requestedTier);
    capability.humanGates.total += 1;

    switch (gate.status) {
      case "waiting_human":
        counts.humanGates.waitingHuman += 1;
        capability.humanGates.waitingHuman += 1;
        break;
      case "approved":
        counts.humanGates.approved += 1;
        capability.humanGates.approved += 1;
        break;
      case "rejected":
        counts.humanGates.rejected += 1;
        capability.humanGates.rejected += 1;
        break;
    }
  }

  for (const replay of normalized.pendingReplays) {
    counts.pendingReplays.total += 1;
    incrementReplayStatus(counts.pendingReplays, replay.status);
    incrementReplayAction(counts.pendingReplays, replay.nextAction);

    const capability = getCapabilityAccumulator(byCapability, replay.capabilityKey);
    capability.requestIds.add(replay.requestId);
    capability.pendingReplays.total += 1;
    incrementReplayStatus(capability.pendingReplays, replay.status);
    incrementReplayAction(capability.pendingReplays, replay.nextAction);
  }

  for (const attempt of normalized.activationAttempts) {
    counts.activationAttempts.total += 1;
    incrementActivationStatus(counts.activationAttempts, attempt.status);
    if (attempt.failure?.retryable) {
      counts.activationAttempts.retryableFailures += 1;
    }

    const capability = getCapabilityAccumulator(byCapability, attempt.capabilityKey);
    capability.activationAttempts.total += 1;
    capability.activationAttempts.targetPools.add(attempt.targetPool);
    incrementActivationStatus(capability.activationAttempts, attempt.status);
    if (attempt.failure?.retryable) {
      capability.activationAttempts.retryableFailures += 1;
    }
  }

  for (const envelope of normalized.resumeEnvelopes) {
    counts.resumeEnvelopes.total += 1;
    incrementResumeSource(counts.resumeEnvelopes, envelope.source);

    const capability = getCapabilityAccumulator(byCapability, envelope.capabilityKey);
    capability.requestIds.add(envelope.requestId);
    capability.sessionIds.add(envelope.sessionId);
    capability.runIds.add(envelope.runId);
    capability.modes.add(envelope.mode);
    capability.requestedTiers.add(envelope.requestedTier);
    capability.resumeEnvelopes.total += 1;
    incrementResumeSource(capability.resumeEnvelopes, envelope.source);
  }

  const capabilities = [...byCapability.values()]
    .map((entry) => toCapabilitySnapshot(entry))
    .sort((left, right) => {
      const stageDelta = STAGE_PRIORITY[left.stage] - STAGE_PRIORITY[right.stage];
      if (stageDelta !== 0) {
        return stageDelta;
      }
      return left.capabilityKey.localeCompare(right.capabilityKey);
    });

  return {
    counts,
    capabilities,
    blockingCapabilityKeys: capabilities
      .filter((capability) => capability.activeBlockers.length > 0)
      .map((capability) => capability.capabilityKey),
    metadata: normalized.metadata,
  };
}

export function hasPendingTapGovernanceWork(
  snapshot: Pick<TapGovernanceSnapshot, "blockingCapabilityKeys"> | undefined,
): boolean {
  return (snapshot?.blockingCapabilityKeys.length ?? 0) > 0;
}
