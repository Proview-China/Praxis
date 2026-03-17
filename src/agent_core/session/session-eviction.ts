import type { SessionHeader, SessionId } from "../types/index.js";
import type { SessionColdLogRecord, SessionEvictionResult } from "./session-types.js";

function cloneRecord(record: SessionColdLogRecord): SessionColdLogRecord {
  return structuredClone(record);
}

export class SessionColdLogStore {
  readonly #records = new Map<SessionId, SessionColdLogRecord>();

  write(record: SessionColdLogRecord): SessionColdLogRecord {
    const cloned = cloneRecord(record);
    this.#records.set(cloned.sessionId, cloned);
    return cloneRecord(cloned);
  }

  read(sessionId: SessionId): SessionColdLogRecord | undefined {
    const record = this.#records.get(sessionId);
    return record ? cloneRecord(record) : undefined;
  }

  has(sessionId: SessionId): boolean {
    return this.#records.has(sessionId);
  }

  delete(sessionId: SessionId): boolean {
    return this.#records.delete(sessionId);
  }

  list(): SessionColdLogRecord[] {
    return [...this.#records.values()].map((record) => cloneRecord(record));
  }
}

export function toEvictionResult(record: SessionColdLogRecord): SessionEvictionResult {
  return {
    sessionId: record.sessionId,
    coldLogRef: record.coldLogRef,
    archivedAt: record.archivedAt
  };
}

export function applyColdRef(header: SessionHeader, coldLogRef: string, archivedAt: string): SessionColdLogRecord {
  const nextHeader: SessionHeader = {
    ...structuredClone(header),
    coldLogRef,
    updatedAt: archivedAt
  };

  return {
    sessionId: header.sessionId,
    coldLogRef,
    header: nextHeader,
    archivedAt
  };
}
