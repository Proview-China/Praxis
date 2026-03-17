import assert from "node:assert/strict";
import test from "node:test";

import { AppendOnlyEventJournal } from "./append-only-log.js";
import type { KernelEvent } from "../types/kernel-events.js";

function createEvent(overrides: Partial<KernelEvent> = {}): KernelEvent {
  return {
    eventId: overrides.eventId ?? `evt-${Math.random().toString(16).slice(2)}`,
    type: overrides.type ?? "run.created",
    sessionId: overrides.sessionId ?? "session-1",
    runId: overrides.runId ?? "run-1",
    createdAt: overrides.createdAt ?? new Date().toISOString(),
    payload: overrides.payload ?? { goalId: "goal-1" },
    correlationId: overrides.correlationId,
    causationId: overrides.causationId,
    metadata: overrides.metadata
  } as KernelEvent;
}

test("append-only log preserves append order and returns sequential cursors", () => {
  const journal = new AppendOnlyEventJournal({
    segmentSize: 8,
    threshold: 16
  });

  const first = journal.appendEvent(createEvent({ eventId: "evt-1" }));
  const second = journal.appendEvent(createEvent({ eventId: "evt-2", type: "run.resumed", payload: {} }));

  assert.equal(first.cursor, "journal:0:0");
  assert.equal(second.cursor, "journal:0:1");
  assert.equal(first.sequence, 1);
  assert.equal(second.sequence, 2);

  const all = journal.readFromCursor();
  assert.deepEqual(all.map((entry) => entry.event.eventId), ["evt-1", "evt-2"]);
});

test("readFromCursor continues after the supplied cursor", () => {
  const journal = new AppendOnlyEventJournal({
    segmentSize: 8,
    threshold: 16
  });

  const first = journal.appendEvent(createEvent({ eventId: "evt-1" }));
  journal.appendEvent(createEvent({ eventId: "evt-2", type: "run.resumed", payload: {} }));
  journal.appendEvent(createEvent({ eventId: "evt-3", type: "run.paused", payload: { reason: "manual" } }));

  const afterFirst = journal.readFromCursor(first.cursor);
  assert.deepEqual(afterFirst.map((entry) => entry.event.eventId), ["evt-2", "evt-3"]);
});

test("journal indexes events by runId and correlationId", () => {
  const journal = new AppendOnlyEventJournal({
    segmentSize: 8,
    threshold: 16
  });

  journal.appendEvent(createEvent({ eventId: "evt-1", runId: "run-a", correlationId: "corr-1" }));
  journal.appendEvent(createEvent({ eventId: "evt-2", runId: "run-b", correlationId: "corr-1" }));
  journal.appendEvent(createEvent({ eventId: "evt-3", runId: "run-a", correlationId: "corr-2" }));

  assert.deepEqual(
    journal.readRunEvents("run-a").map((entry) => entry.event.eventId),
    ["evt-1", "evt-3"]
  );
  assert.deepEqual(
    journal.readCorrelationEvents("corr-1").map((entry) => entry.event.eventId),
    ["evt-1", "evt-2"]
  );
});

test("flush trigger fires asynchronously on threshold and segment rotation", async () => {
  const journal = new AppendOnlyEventJournal({
    segmentSize: 2,
    threshold: 2
  });

  const signals: string[] = [];
  const waitForSignal = new Promise<void>((resolve) => {
    journal.onFlushRequested((signal) => {
      signals.push(signal.reason);
      if (signals.length >= 1) {
        resolve();
      }
    });
  });

  journal.appendEvent(createEvent({ eventId: "evt-1" }));
  journal.appendEvent(createEvent({ eventId: "evt-2", type: "run.resumed", payload: {} }));
  await waitForSignal;

  assert.ok(signals.includes("threshold") || signals.includes("segment-rotated"));
});

test("concurrent producers still produce a stable append-only order", async () => {
  const journal = new AppendOnlyEventJournal({
    segmentSize: 32,
    threshold: 64
  });

  await Promise.all(
    Array.from({ length: 10 }, (_, index) =>
      Promise.resolve().then(() => {
        journal.appendEvent(createEvent({
          eventId: `evt-${index}`,
          correlationId: "corr-shared"
        }));
      })
    )
  );

  const all = journal.readCorrelationEvents("corr-shared");
  assert.equal(all.length, 10);
  assert.deepEqual(
    all.map((entry) => entry.event.eventId),
    Array.from({ length: 10 }, (_, index) => `evt-${index}`)
  );
});
