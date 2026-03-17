import type { JournalCursor } from "../types/kernel-session.js";
import type { JournalFlushSignal } from "./journal-types.js";

export interface JournalFlushTriggerOptions {
  threshold?: number;
}

type FlushListener = (signal: JournalFlushSignal) => void;

export class JournalFlushTrigger {
  readonly #threshold: number;
  readonly #listeners = new Set<FlushListener>();
  #pendingEvents = 0;
  #lastCursor?: JournalCursor;
  #scheduledSignal?: JournalFlushSignal;

  constructor(options: JournalFlushTriggerOptions = {}) {
    this.#threshold = options.threshold ?? 128;
  }

  markAppend(cursor: JournalCursor): void {
    this.#pendingEvents += 1;
    this.#lastCursor = cursor;

    if (this.#pendingEvents >= this.#threshold) {
      this.requestFlush("threshold");
    }
  }

  markSegmentRotation(cursor: JournalCursor): void {
    this.#lastCursor = cursor;
    this.requestFlush("segment-rotated");
  }

  requestFlush(reason: JournalFlushSignal["reason"] = "manual"): void {
    if (!this.#lastCursor) {
      return;
    }

    const nextSignal: JournalFlushSignal = {
      reason,
      uptoCursor: this.#lastCursor,
      pendingEvents: this.#pendingEvents
    };

    if (this.#scheduledSignal) {
      this.#scheduledSignal = {
        reason: this.#scheduledSignal.reason === "threshold" ? this.#scheduledSignal.reason : nextSignal.reason,
        uptoCursor: nextSignal.uptoCursor,
        pendingEvents: Math.max(this.#scheduledSignal.pendingEvents, nextSignal.pendingEvents)
      };
      return;
    }

    this.#scheduledSignal = nextSignal;
    queueMicrotask(() => {
      const signal = this.#scheduledSignal;
      this.#scheduledSignal = undefined;
      if (!signal) {
        return;
      }

      for (const listener of this.#listeners) {
        listener(signal);
      }

      this.#pendingEvents = 0;
    });
  }

  onFlushRequested(listener: FlushListener): () => void {
    this.#listeners.add(listener);
    return () => {
      this.#listeners.delete(listener);
    };
  }
}
