import { randomUUID } from "node:crypto";

import type { SessionHeader, SessionId, SessionStatus } from "../types/index.js";
import { SessionHeaderStore } from "./session-header-store.js";
import { applyColdRef, SessionColdLogStore, toEvictionResult } from "./session-eviction.js";
import type {
  AttachRunInput,
  CreateSessionInput,
  MarkCheckpointInput,
  SessionHeaderPatch,
  SessionManagerClock,
  SessionManagerIdFactory,
  SessionEvictionResult
} from "./session-types.js";

const DEFAULT_CLOCK: SessionManagerClock = {
  now: () => new Date()
};

const DEFAULT_ID_FACTORY: SessionManagerIdFactory = {
  createSessionId: () => randomUUID(),
  createColdLogRef: (sessionId) => `cold:${sessionId}:${randomUUID()}`
};

function cloneHeader(header: SessionHeader): SessionHeader {
  return structuredClone(header);
}

function mergeMetadata(
  base: Record<string, unknown> | undefined,
  patch: Record<string, unknown> | undefined
): Record<string, unknown> | undefined {
  if (!base && !patch) {
    return undefined;
  }

  return {
    ...(base ?? {}),
    ...(patch ?? {})
  };
}

export class SessionManager {
  readonly #headers: SessionHeaderStore;
  readonly #coldLogs: SessionColdLogStore;
  readonly #clock: SessionManagerClock;
  readonly #idFactory: SessionManagerIdFactory;

  constructor(options: {
    headers?: SessionHeaderStore;
    coldLogs?: SessionColdLogStore;
    clock?: SessionManagerClock;
    idFactory?: SessionManagerIdFactory;
  } = {}) {
    this.#headers = options.headers ?? new SessionHeaderStore();
    this.#coldLogs = options.coldLogs ?? new SessionColdLogStore();
    this.#clock = options.clock ?? DEFAULT_CLOCK;
    this.#idFactory = options.idFactory ?? DEFAULT_ID_FACTORY;
  }

  createSession(input: CreateSessionInput = {}): SessionHeader {
    const now = this.#clock.now().toISOString();
    const sessionId = input.sessionId ?? this.#idFactory.createSessionId();
    const header: SessionHeader = {
      sessionId,
      status: input.status ?? this.#deriveInitialStatus(input),
      activeRunId: input.activeRunId,
      runIds: [...(input.runIds ?? [])],
      lastCheckpointRef: input.lastCheckpointRef,
      lastJournalCursor: input.lastJournalCursor,
      version: 1,
      createdAt: now,
      updatedAt: now,
      coldLogRef: input.coldLogRef,
      metadata: input.metadata ? { ...input.metadata } : undefined
    };

    return this.#headers.set(header);
  }

  loadSessionHeader(sessionId: SessionId): SessionHeader | undefined {
    const hot = this.#headers.get(sessionId);
    if (hot) {
      return hot;
    }

    const cold = this.#coldLogs.read(sessionId);
    if (!cold) {
      return undefined;
    }

    const restored: SessionHeader = {
      ...cloneHeader(cold.header),
      updatedAt: this.#clock.now().toISOString()
    };
    this.#headers.set(restored);
    return restored;
  }

  listSessionHeaders(): SessionHeader[] {
    return this.#headers.list();
  }

  updateSessionHeader(sessionId: SessionId, patch: SessionHeaderPatch): SessionHeader {
    const current = this.#requireHeader(sessionId);
    const next: SessionHeader = {
      ...current,
      status: patch.status ?? current.status,
      activeRunId: patch.activeRunId === undefined ? current.activeRunId : patch.activeRunId,
      lastCheckpointRef: patch.lastCheckpointRef === undefined ? current.lastCheckpointRef : patch.lastCheckpointRef,
      lastJournalCursor: patch.lastJournalCursor === undefined ? current.lastJournalCursor : patch.lastJournalCursor,
      coldLogRef: patch.coldLogRef === undefined ? current.coldLogRef : patch.coldLogRef,
      metadata: mergeMetadata(current.metadata, patch.metadata),
      version: current.version + 1,
      updatedAt: this.#clock.now().toISOString()
    };

    return this.#headers.set(next);
  }

  attachRun(input: AttachRunInput): SessionHeader {
    const current = this.#requireHeader(input.sessionId);
    const runIds = current.runIds.includes(input.runId)
      ? [...current.runIds]
      : [...current.runIds, input.runId];

    const nextStatus = input.makeActive
      ? "active"
      : current.status === "archived"
        ? "idle"
        : current.status;

    return this.#headers.set({
      ...current,
      runIds,
      activeRunId: input.makeActive ? input.runId : current.activeRunId,
      status: nextStatus,
      version: current.version + 1,
      updatedAt: this.#clock.now().toISOString()
    });
  }

  setActiveRun(sessionId: SessionId, runId: string | undefined): SessionHeader {
    const current = this.#requireHeader(sessionId);
    const runIds = runId && !current.runIds.includes(runId)
      ? [...current.runIds, runId]
      : [...current.runIds];

    const status = this.#deriveStatusForActiveRun(current.status, runId);

    return this.#headers.set({
      ...current,
      runIds,
      activeRunId: runId,
      status,
      version: current.version + 1,
      updatedAt: this.#clock.now().toISOString()
    });
  }

  markCheckpoint(input: MarkCheckpointInput): SessionHeader {
    const current = this.#requireHeader(input.sessionId);
    return this.#headers.set({
      ...current,
      lastCheckpointRef: input.checkpointId,
      lastJournalCursor: input.journalCursor ?? current.lastJournalCursor,
      version: current.version + 1,
      updatedAt: this.#clock.now().toISOString()
    });
  }

  markJournalCursor(sessionId: SessionId, journalCursor: string): SessionHeader {
    const current = this.#requireHeader(sessionId);
    return this.#headers.set({
      ...current,
      lastJournalCursor: journalCursor,
      version: current.version + 1,
      updatedAt: this.#clock.now().toISOString()
    });
  }

  evictSession(sessionId: SessionId): SessionEvictionResult {
    const current = this.#requireHeader(sessionId);
    const archivedAt = this.#clock.now().toISOString();
    const coldLogRef = current.coldLogRef ?? this.#idFactory.createColdLogRef(sessionId);
    const record = applyColdRef(
      {
        ...current,
        status: "archived",
        activeRunId: undefined,
        version: current.version + 1
      },
      coldLogRef,
      archivedAt
    );

    this.#coldLogs.write(record);
    this.#headers.delete(sessionId);

    return toEvictionResult(record);
  }

  hasHotSession(sessionId: SessionId): boolean {
    return this.#headers.has(sessionId);
  }

  hasColdSession(sessionId: SessionId): boolean {
    return this.#coldLogs.has(sessionId);
  }

  readColdLog(sessionId: SessionId) {
    return this.#coldLogs.read(sessionId);
  }

  #requireHeader(sessionId: SessionId): SessionHeader {
    const header = this.loadSessionHeader(sessionId);
    if (!header) {
      throw new Error(`Session ${sessionId} was not found.`);
    }
    return header;
  }

  #deriveInitialStatus(input: CreateSessionInput): SessionStatus {
    if (input.activeRunId) {
      return "active";
    }
    return "idle";
  }

  #deriveStatusForActiveRun(current: SessionStatus, runId: string | undefined): SessionStatus {
    if (runId) {
      return "active";
    }
    if (current === "archived") {
      return "idle";
    }
    return current === "active" ? "idle" : current;
  }
}
