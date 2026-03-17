import type { EventJournalLike, JournalReadResult } from "../journal/index.js";
import type { CheckpointRecord } from "../types/kernel-checkpoint.js";
import type { RunRecord } from "../types/kernel-run.js";
import type { AgentState } from "../types/kernel-state.js";
import type { JournalCursor, RunId, SessionHeader } from "../types/kernel-session.js";

export interface CheckpointSnapshotData {
  run: RunRecord;
  state: AgentState;
  sessionHeader?: SessionHeader;
}

export interface StoredCheckpoint {
  record: CheckpointRecord;
  snapshot?: CheckpointSnapshotData;
}

export interface CheckpointWriteInput {
  record: CheckpointRecord;
  snapshot?: CheckpointSnapshotData;
}

export interface CheckpointRecoveryResult {
  checkpoint: StoredCheckpoint | undefined;
  state: AgentState;
  run?: RunRecord;
  replayedEvents: JournalReadResult[];
  resumeCursor?: JournalCursor;
}

export interface CheckpointRecoveryInput {
  runId: RunId;
  journal: EventJournalLike;
  checkpointId?: string;
}

export interface FastCheckpointStoreLike {
  write(input: CheckpointWriteInput): StoredCheckpoint;
  readLatest(runId: RunId): StoredCheckpoint | undefined;
  read(checkpointId: string): StoredCheckpoint | undefined;
}

export interface DurableCheckpointStoreLike {
  write(input: CheckpointWriteInput): Promise<StoredCheckpoint>;
  readLatest(runId: RunId): Promise<StoredCheckpoint | undefined>;
  read(checkpointId: string): Promise<StoredCheckpoint | undefined>;
}
