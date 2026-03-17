import { tmpdir } from "node:os";
import path from "node:path";

import type { CheckpointReason, CheckpointRecord, JournalCursor, RunId } from "../types/index.js";
import { DurableCheckpointStore } from "./checkpoint-durable.js";
import { FastCheckpointStore } from "./checkpoint-fast.js";
import { recoverFromCheckpoint } from "./checkpoint-recovery.js";
import type {
  CheckpointRecoveryInput,
  CheckpointRecoveryResult,
  CheckpointSnapshotData,
  CheckpointWriteInput,
  DurableCheckpointStoreLike,
  FastCheckpointStoreLike,
  StoredCheckpoint
} from "./checkpoint-types.js";

export interface CheckpointStoreOptions {
  durable?: DurableCheckpointStoreLike;
  fast?: FastCheckpointStoreLike;
  durableDirectory?: string;
}

export interface CreateCheckpointInput {
  checkpointId: string;
  sessionId: string;
  runId: RunId;
  reason: CheckpointReason;
  createdAt: string;
  basedOnEventId?: string;
  journalCursor?: JournalCursor;
  pendingIntentId?: string;
  inputAssemblyHash?: string;
  snapshot?: CheckpointSnapshotData;
  metadata?: Record<string, unknown>;
}

export class CheckpointStore {
  readonly #fast: FastCheckpointStoreLike;
  readonly #durable: DurableCheckpointStoreLike;

  constructor(options: CheckpointStoreOptions = {}) {
    this.#fast = options.fast ?? new FastCheckpointStore();
    this.#durable = options.durable ?? new DurableCheckpointStore({
      directory: options.durableDirectory ?? path.join(tmpdir(), "praxis-agent-core-checkpoints")
    });
  }

  writeFastCheckpoint(input: CreateCheckpointInput): StoredCheckpoint {
    return this.#fast.write(this.#toWriteInput("fast", input));
  }

  async writeDurableCheckpoint(input: CreateCheckpointInput): Promise<StoredCheckpoint> {
    return this.#durable.write(this.#toWriteInput("durable", input));
  }

  loadFastCheckpoint(checkpointId: string): StoredCheckpoint | undefined {
    return this.#fast.read(checkpointId);
  }

  async loadDurableCheckpoint(checkpointId: string): Promise<StoredCheckpoint | undefined> {
    return this.#durable.read(checkpointId);
  }

  async loadLatestCheckpoint(runId: RunId): Promise<StoredCheckpoint | undefined> {
    const fast = this.#fast.readLatest(runId);
    if (fast) {
      return fast;
    }
    return this.#durable.readLatest(runId);
  }

  async recoverRun(input: CheckpointRecoveryInput): Promise<CheckpointRecoveryResult> {
    const checkpoint = input.checkpointId
      ? this.#fast.read(input.checkpointId) ?? await this.#durable.read(input.checkpointId)
      : await this.loadLatestCheckpoint(input.runId);

    return recoverFromCheckpoint({
      ...input,
      checkpoint
    });
  }

  #toWriteInput(
    tier: CheckpointRecord["tier"],
    input: CreateCheckpointInput
  ): CheckpointWriteInput {
    return {
      record: {
        checkpointId: input.checkpointId,
        sessionId: input.sessionId,
        runId: input.runId,
        tier,
        reason: input.reason,
        createdAt: input.createdAt,
        basedOnEventId: input.basedOnEventId,
        journalCursor: input.journalCursor,
        pendingIntentId: input.pendingIntentId,
        inputAssemblyHash: input.inputAssemblyHash,
        snapshotRef: input.snapshot ? `${tier}:${input.checkpointId}` : undefined,
        metadata: input.metadata
      },
      snapshot: input.snapshot
    };
  }
}
