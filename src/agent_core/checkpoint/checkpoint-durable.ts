import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";

import type { RunId } from "../types/index.js";
import type {
  CheckpointWriteInput,
  DurableCheckpointStoreLike,
  StoredCheckpoint
} from "./checkpoint-types.js";

interface DurableCheckpointEnvelope {
  stored: StoredCheckpoint;
}

function cloneStoredCheckpoint(input: CheckpointWriteInput | StoredCheckpoint): StoredCheckpoint {
  return structuredClone({
    record: input.record,
    snapshot: input.snapshot
  } satisfies StoredCheckpoint);
}

export interface DurableCheckpointStoreOptions {
  directory: string;
}

export class DurableCheckpointStore implements DurableCheckpointStoreLike {
  readonly #directory: string;

  constructor(options: DurableCheckpointStoreOptions) {
    this.#directory = options.directory;
  }

  async write(input: CheckpointWriteInput): Promise<StoredCheckpoint> {
    const entry = cloneStoredCheckpoint(input);
    await mkdir(this.#directory, { recursive: true });
    const target = this.#targetPath(entry.record.checkpointId);
    const envelope: DurableCheckpointEnvelope = { stored: entry };
    await writeFile(target, JSON.stringify(envelope), "utf8");
    return cloneStoredCheckpoint(entry);
  }

  async readLatest(runId: RunId): Promise<StoredCheckpoint | undefined> {
    const entries = await this.#loadAll();
    const filtered = entries
      .filter((entry) => entry.record.runId === runId)
      .sort((left, right) => {
        return left.record.createdAt.localeCompare(right.record.createdAt);
      });
    const latest = filtered.at(-1);
    return latest ? cloneStoredCheckpoint(latest) : undefined;
  }

  async read(checkpointId: string): Promise<StoredCheckpoint | undefined> {
    const target = this.#targetPath(checkpointId);
    try {
      const raw = await readFile(target, "utf8");
      const envelope = JSON.parse(raw) as DurableCheckpointEnvelope;
      return cloneStoredCheckpoint(envelope.stored);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return undefined;
      }
      throw error;
    }
  }

  async #loadAll(): Promise<StoredCheckpoint[]> {
    try {
      const files = await readdir(this.#directory);
      const results = await Promise.all(
        files
          .filter((name) => name.endsWith(".json"))
          .map(async (name) => {
            const raw = await readFile(path.join(this.#directory, name), "utf8");
            const envelope = JSON.parse(raw) as DurableCheckpointEnvelope;
            return cloneStoredCheckpoint(envelope.stored);
          })
      );
      return results;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return [];
      }
      throw error;
    }
  }

  #targetPath(checkpointId: string): string {
    return path.join(this.#directory, `${checkpointId}.json`);
  }
}
