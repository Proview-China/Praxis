import type {
  CheckpointSnapshotData,
  StoredCheckpoint,
} from "./checkpoint-types.js";
import {
  createTapGovernanceSnapshot,
  hasPendingTapGovernanceWork,
  type TapGovernanceSnapshot,
} from "../ta-pool-runtime/governance-snapshot.js";
import { readTapRuntimeSnapshotFromCheckpoint } from "../ta-pool-runtime/runtime-checkpoint.js";

export function readTapGovernanceSnapshotFromCheckpoint(
  source: CheckpointSnapshotData | StoredCheckpoint | undefined,
): TapGovernanceSnapshot | undefined {
  const tap = readTapRuntimeSnapshotFromCheckpoint(source);
  return tap ? createTapGovernanceSnapshot(tap) : undefined;
}

export function checkpointHasPendingTapGovernanceWork(
  source: CheckpointSnapshotData | StoredCheckpoint | undefined,
): boolean {
  return hasPendingTapGovernanceWork(readTapGovernanceSnapshotFromCheckpoint(source));
}
