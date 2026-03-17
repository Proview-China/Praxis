import type { KernelEvent, KernelEventType } from "../types/kernel-events.js";
import type { JournalCursor, RunId } from "../types/kernel-session.js";
import { decodeJournalCursor, encodeJournalCursor } from "./journal-cursor.js";
import { JournalFlushTrigger, type JournalFlushTriggerOptions } from "./journal-flush-trigger.js";
import { JournalIndex } from "./journal-index.js";
import type {
  EventJournalLike,
  JournalAppendResult,
  JournalFlushSignal,
  JournalQueryOptions,
  JournalReadResult,
  JournalSegmentInfo,
} from "./journal-types.js";

export interface AppendOnlyEventJournalOptions extends JournalFlushTriggerOptions {
  segmentSize?: number;
}

export class AppendOnlyEventJournal implements EventJournalLike {
  readonly #segmentSize: number;
  readonly #segments: KernelEvent[][] = [[]];
  readonly #index = new JournalIndex();
  readonly #flushTrigger: JournalFlushTrigger;
  readonly #latestByRun = new Map<RunId, JournalCursor>();
  #sequence = 0;

  constructor(options: AppendOnlyEventJournalOptions = {}) {
    this.#segmentSize = options.segmentSize ?? 256;
    this.#flushTrigger = new JournalFlushTrigger({
      threshold: options.threshold
    });
  }

  appendEvent(event: KernelEvent): JournalAppendResult {
    const segmentId = this.#segments.length - 1;
    const segment = this.#segments[segmentId]!;
    const offset = segment.length;

    segment.push(event);
    this.#sequence += 1;

    const cursor = encodeJournalCursor(segmentId, offset);
    this.#index.append(event, cursor);
    this.#latestByRun.set(event.runId, cursor);
    this.#flushTrigger.markAppend(cursor);

    if (segment.length >= this.#segmentSize) {
      this.#segments.push([]);
      this.#flushTrigger.markSegmentRotation(cursor);
    }

    return {
      cursor,
      segmentId,
      offset,
      sequence: this.#sequence
    };
  }

  readFromCursor(cursor?: JournalCursor, limit = Number.POSITIVE_INFINITY): JournalReadResult[] {
    const results: JournalReadResult[] = [];
    const start = cursor ? this.#nextPosition(cursor) : { segmentId: 0, offset: 0 };

    for (let segmentId = start.segmentId; segmentId < this.#segments.length; segmentId += 1) {
      const segment = this.#segments[segmentId]!;
      const offsetStart = segmentId === start.segmentId ? start.offset : 0;
      for (let offset = offsetStart; offset < segment.length; offset += 1) {
        const entry = segment[offset]!;
        results.push({
          cursor: encodeJournalCursor(segmentId, offset),
          event: entry
        });
        if (results.length >= limit) {
          return results;
        }
      }
    }

    return results;
  }

  readRunEvents(runId: RunId, options: JournalQueryOptions = {}): JournalReadResult[] {
    return this.#readIndexed(this.#index.readRun(runId), options);
  }

  readCorrelationEvents(correlationId: string, options: JournalQueryOptions = {}): JournalReadResult[] {
    return this.#readIndexed(this.#index.readCorrelation(correlationId), options);
  }

  queryByType(type: KernelEventType, options: JournalQueryOptions = {}): JournalReadResult[] {
    return this.#readIndexed(this.#index.readType(type), options);
  }

  getLatestEvent(runId: RunId): JournalReadResult | undefined {
    const cursor = this.#latestByRun.get(runId);
    if (!cursor) {
      return undefined;
    }
    const event = this.#eventAt(cursor);
    return {
      cursor,
      event
    };
  }

  listSegments(): JournalSegmentInfo[] {
    return this.#segments.map((segment, segmentId) => {
      const info: JournalSegmentInfo = {
        segmentId,
        size: segment.length
      };

      if (segment.length > 0) {
        info.startCursor = encodeJournalCursor(segmentId, 0);
        info.endCursor = encodeJournalCursor(segmentId, segment.length - 1);
      }

      return info;
    });
  }

  requestFlush(reason: JournalFlushSignal["reason"] = "manual"): void {
    this.#flushTrigger.requestFlush(reason);
  }

  onFlushRequested(listener: (signal: JournalFlushSignal) => void): () => void {
    return this.#flushTrigger.onFlushRequested(listener);
  }

  #readIndexed(indexedCursors: readonly JournalCursor[], options: JournalQueryOptions): JournalReadResult[] {
    const afterCursor = options.afterCursor;
    const limit = options.limit ?? Number.POSITIVE_INFINITY;
    const results: JournalReadResult[] = [];

    let started = afterCursor === undefined;
    for (const cursor of indexedCursors) {
      if (!started) {
        if (cursor === afterCursor) {
          started = true;
        }
        continue;
      }

      if (cursor === afterCursor) {
        continue;
      }

      results.push({
        cursor,
        event: this.#eventAt(cursor)
      });

      if (results.length >= limit) {
        break;
      }
    }

    return results;
  }

  #nextPosition(cursor: JournalCursor): { segmentId: number; offset: number } {
    const { segmentId, offset } = decodeJournalCursor(cursor);
    const segment = this.#segments[segmentId];
    if (!segment) {
      throw new Error(`Unknown journal segment for cursor ${cursor}.`);
    }

    return {
      segmentId,
      offset: offset + 1
    };
  }

  #eventAt(cursor: JournalCursor): KernelEvent {
    const { segmentId, offset } = decodeJournalCursor(cursor);
    const segment = this.#segments[segmentId];
    if (!segment) {
      throw new Error(`Unknown journal segment for cursor ${cursor}.`);
    }

    const event = segment[offset];
    if (!event) {
      throw new Error(`Unknown journal offset for cursor ${cursor}.`);
    }

    return event;
  }
}
