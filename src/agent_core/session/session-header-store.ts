import type { SessionHeader, SessionId } from "../types/index.js";

function cloneHeader(header: SessionHeader): SessionHeader {
  return structuredClone(header);
}

export class SessionHeaderStore {
  readonly #headers = new Map<SessionId, SessionHeader>();

  set(header: SessionHeader): SessionHeader {
    const cloned = cloneHeader(header);
    this.#headers.set(cloned.sessionId, cloned);
    return cloneHeader(cloned);
  }

  get(sessionId: SessionId): SessionHeader | undefined {
    const header = this.#headers.get(sessionId);
    return header ? cloneHeader(header) : undefined;
  }

  has(sessionId: SessionId): boolean {
    return this.#headers.has(sessionId);
  }

  delete(sessionId: SessionId): boolean {
    return this.#headers.delete(sessionId);
  }

  list(): SessionHeader[] {
    return [...this.#headers.values()].map((header) => cloneHeader(header));
  }
}
