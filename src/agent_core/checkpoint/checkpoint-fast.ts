import type { RunId } from "../types/index.js";
import type {
  CheckpointWriteInput,
  FastCheckpointStoreLike,
  StoredCheckpoint
} from "./checkpoint-types.js";

function cloneStoredCheckpoint(input: CheckpointWriteInput | StoredCheckpoint): StoredCheckpoint {
  return structuredClone({
    record: input.record,
    snapshot: input.snapshot
  } satisfies StoredCheckpoint);
}

export class FastCheckpointStore implements FastCheckpointStoreLike {
  readonly #byId = new Map<string, StoredCheckpoint>();
  readonly #latestByRun = new Map<RunId, string>();

  write(input: CheckpointWriteInput): StoredCheckpoint {
    const entry = cloneStoredCheckpoint(input);
    this.#byId.set(entry.record.checkpointId, entry);
    this.#latestByRun.set(entry.record.runId, entry.record.checkpointId);
    return cloneStoredCheckpoint(entry);
  }

  readLatest(runId: RunId): StoredCheckpoint | undefined {
    const checkpointId = this.#latestByRun.get(runId);
    if (!checkpointId) {
      return undefined;
    }
    return this.read(checkpointId);
  }

  read(checkpointId: string): StoredCheckpoint | undefined {
    const entry = this.#byId.get(checkpointId);
    if (!entry) {
      return undefined;
    }
    return cloneStoredCheckpoint(entry);
  }
}
