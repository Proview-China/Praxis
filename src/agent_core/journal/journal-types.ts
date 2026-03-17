import type { KernelEvent, KernelEventType } from "../types/kernel-events.js";
import type { JournalCursor, RunId } from "../types/kernel-session.js";

export interface JournalAppendResult {
  cursor: JournalCursor;
  segmentId: number;
  offset: number;
  sequence: number;
}

export interface JournalFlushSignal {
  reason: "threshold" | "segment-rotated" | "manual";
  uptoCursor: JournalCursor;
  pendingEvents: number;
}

export interface JournalSegmentInfo {
  segmentId: number;
  size: number;
  startCursor?: JournalCursor;
  endCursor?: JournalCursor;
}

export interface JournalReadResult {
  cursor: JournalCursor;
  event: KernelEvent;
}

export interface JournalQueryOptions {
  limit?: number;
  afterCursor?: JournalCursor;
}

export interface EventJournalLike {
  appendEvent(event: KernelEvent): JournalAppendResult;
  readFromCursor(cursor?: JournalCursor, limit?: number): JournalReadResult[];
  readRunEvents(runId: RunId, options?: JournalQueryOptions): JournalReadResult[];
  readCorrelationEvents(correlationId: string, options?: JournalQueryOptions): JournalReadResult[];
  queryByType(type: KernelEventType, options?: JournalQueryOptions): JournalReadResult[];
  getLatestEvent(runId: RunId): JournalReadResult | undefined;
  listSegments(): JournalSegmentInfo[];
  requestFlush(reason?: JournalFlushSignal["reason"]): void;
  onFlushRequested(listener: (signal: JournalFlushSignal) => void): () => void;
}
