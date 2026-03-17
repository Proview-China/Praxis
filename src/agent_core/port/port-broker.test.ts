import test from "node:test";
import assert from "node:assert/strict";

import { AppendOnlyEventJournal } from "../journal/append-only-log.js";
import type { CapabilityCallIntent } from "../types/kernel-intents.js";
import { CapabilityPortBroker } from "./port-broker.js";

function createIntent(overrides: Partial<CapabilityCallIntent> = {}): CapabilityCallIntent {
  return {
    intentId: overrides.intentId ?? "intent-1",
    sessionId: overrides.sessionId ?? "session-1",
    runId: overrides.runId ?? "run-1",
    kind: "capability_call",
    createdAt: overrides.createdAt ?? "2026-03-17T00:00:00.000Z",
    priority: overrides.priority ?? "normal",
    request: overrides.request ?? {
      requestId: "request-1",
      intentId: overrides.intentId ?? "intent-1",
      sessionId: overrides.sessionId ?? "session-1",
      runId: overrides.runId ?? "run-1",
      capabilityKey: "capability.echo",
      input: { value: 1 },
      priority: overrides.priority ?? "normal",
    },
    ...overrides,
  };
}

test("CapabilityPortBroker enqueues and dispatches in priority order", async () => {
  const broker = new CapabilityPortBroker();
  const seen: string[] = [];

  broker.registerCapabilityPort({
    capabilityKey: "capability.echo",
    async handler(request) {
      seen.push(request.requestId);
      return {
        output: request.input,
      };
    },
  });

  broker.enqueueIntent({
    intent: createIntent({
      intentId: "intent-low",
      priority: "low",
      request: {
        requestId: "request-low",
        intentId: "intent-low",
        sessionId: "session-1",
        runId: "run-1",
        capabilityKey: "capability.echo",
        input: { value: "low" },
        priority: "low",
      },
    }),
  });
  broker.enqueueIntent({
    intent: createIntent({
      intentId: "intent-high",
      priority: "high",
      request: {
        requestId: "request-high",
        intentId: "intent-high",
        sessionId: "session-1",
        runId: "run-1",
        capabilityKey: "capability.echo",
        input: { value: "high" },
        priority: "high",
      },
    }),
  });

  await broker.dispatchNext();
  await broker.dispatchNext();

  assert.deepEqual(seen, ["request-high", "request-low"]);
});

test("CapabilityPortBroker uses idempotency cache for duplicate requests", async () => {
  const broker = new CapabilityPortBroker();
  let calls = 0;

  broker.registerCapabilityPort({
    capabilityKey: "capability.echo",
    async handler(request) {
      calls += 1;
      return {
        output: request.input,
      };
    },
  });

  const intent = createIntent({
    request: {
      requestId: "request-1",
      intentId: "intent-1",
      sessionId: "session-1",
      runId: "run-1",
      capabilityKey: "capability.echo",
      input: { value: 1 },
      priority: "normal",
      idempotencyKey: "same-key",
    },
    idempotencyKey: "same-key",
  });

  broker.enqueueIntent({ intent });
  const first = await broker.dispatchNext();
  assert.equal(first?.fromCache, false);

  const cachedEnqueue = broker.enqueueIntent({
    intent: createIntent({
      intentId: "intent-2",
      request: {
        requestId: "request-2",
        intentId: "intent-2",
        sessionId: "session-1",
        runId: "run-1",
        capabilityKey: "capability.echo",
        input: { value: 1 },
        priority: "normal",
        idempotencyKey: "same-key",
      },
      idempotencyKey: "same-key",
    }),
  });
  const second = await broker.dispatchNext();

  assert.equal(calls, 1);
  assert.equal(cachedEnqueue.status, "completed");
  assert.equal(second, undefined);
});

test("CapabilityPortBroker emits backpressure signals when queue threshold is exceeded", async () => {
  const broker = new CapabilityPortBroker({
    maxQueueDepth: 1,
  });
  const signals: boolean[] = [];

  broker.onBackpressureSignal((signal) => {
    signals.push(signal.active);
  });

  broker.enqueueIntent({ intent: createIntent({ intentId: "intent-1" }) });
  broker.enqueueIntent({
    intent: createIntent({
      intentId: "intent-2",
      request: {
        requestId: "request-2",
        intentId: "intent-2",
        sessionId: "session-1",
        runId: "run-1",
        capabilityKey: "capability.echo",
        input: { value: 2 },
        priority: "normal",
      },
    }),
  });

  assert.ok(signals.includes(true));
});

test("CapabilityPortBroker supports timeout failure and result callbacks", async () => {
  const journal = new AppendOnlyEventJournal();
  const broker = new CapabilityPortBroker({
    journal,
  });
  const statuses: string[] = [];

  broker.registerCapabilityPort({
    capabilityKey: "capability.slow",
    timeoutMs: 5,
    async handler() {
      await new Promise((resolve) => setTimeout(resolve, 20));
      return {
        output: { unreachable: true },
      };
    },
  });

  broker.onResult((payload) => {
    statuses.push(payload.response.status);
  });

  broker.enqueueIntent({
    intent: createIntent({
      request: {
        requestId: "request-slow",
        intentId: "intent-1",
        sessionId: "session-1",
        runId: "run-1",
        capabilityKey: "capability.slow",
        input: {},
        priority: "normal",
      },
    }),
  });

  const receipt = await broker.dispatchNext();
  assert.equal(receipt?.response.status, "timed_out");
  assert.deepEqual(statuses, ["timed_out"]);

  const events = journal.queryByType("capability.result_received");
  assert.equal(events.length, 1);
});

test("CapabilityPortBroker stores prepared invocation cache entries", () => {
  const broker = new CapabilityPortBroker();
  const entry = broker.setPreparedInvocation("cache-key", {
    capabilityKey: "capability.echo",
    sessionId: "session-1",
    runId: "run-1",
    value: { prepared: true },
  });

  assert.equal(entry.cacheKey, "cache-key");
  assert.deepEqual(broker.getPreparedInvocation("cache-key")?.value, { prepared: true });
});
