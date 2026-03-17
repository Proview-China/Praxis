import type { KernelEvent, KernelEventType } from "../types/kernel-events.js";
import type { JournalCursor, RunId } from "../types/kernel-session.js";

export class JournalIndex {
  readonly #byRun = new Map<RunId, JournalCursor[]>();
  readonly #byCorrelation = new Map<string, JournalCursor[]>();
  readonly #byType = new Map<KernelEventType, JournalCursor[]>();

  append(event: KernelEvent, cursor: JournalCursor): void {
    this.#append(this.#byRun, event.runId, cursor);
    this.#append(this.#byType, event.type, cursor);
    if (event.correlationId) {
      this.#append(this.#byCorrelation, event.correlationId, cursor);
    }
  }

  readRun(runId: RunId): readonly JournalCursor[] {
    return this.#byRun.get(runId) ?? [];
  }

  readCorrelation(correlationId: string): readonly JournalCursor[] {
    return this.#byCorrelation.get(correlationId) ?? [];
  }

  readType(type: KernelEventType): readonly JournalCursor[] {
    return this.#byType.get(type) ?? [];
  }

  #append<TKey>(index: Map<TKey, JournalCursor[]>, key: TKey, cursor: JournalCursor): void {
    const current = index.get(key);
    if (current) {
      current.push(cursor);
      return;
    }

    index.set(key, [cursor]);
  }
}
