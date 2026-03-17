import { randomUUID } from "node:crypto";

import { RaxRoutingError } from "../../rax/errors.js";
import type { CapabilityResultReceivedEvent, IntentDispatchedEvent, IntentQueuedEvent, KernelEvent } from "../types/kernel-events.js";
import type { CapabilityCallIntent, CapabilityPortRequest } from "../types/kernel-intents.js";
import type { CapabilityPortResponse, KernelResult } from "../types/kernel-results.js";
import { CapabilityPortIdempotencyCache } from "./port-idempotency.js";
import { PortBackpressureMonitor } from "./port-backpressure.js";
import { CapabilityPortQueue } from "./port-queue.js";
import { CapabilityPortRegistry } from "./port-registry.js";
import type {
  BackpressureState,
  CapabilityDispatchReceipt,
  CapabilityPortBrokerOptions,
  CapabilityPortDefinition,
  CapabilityPortStats,
  CapabilityPreparedInvocationEntry,
  CapabilityResultCallback,
  CapabilityResultCallbackPayload,
  EnqueueCapabilityIntentInput,
  PortInflightItem,
  PortQueueItem,
} from "./port-types.js";

function createIntentQueuedEvent(intent: CapabilityCallIntent): IntentQueuedEvent {
  return {
    eventId: randomUUID(),
    type: "intent.queued",
    sessionId: intent.sessionId,
    runId: intent.runId,
    createdAt: new Date().toISOString(),
    correlationId: intent.correlationId,
    payload: {
      intentId: intent.intentId,
      kind: intent.kind,
      priority: intent.priority,
    },
  };
}

function createIntentDispatchedEvent(item: PortQueueItem, target: string): IntentDispatchedEvent {
  return {
    eventId: randomUUID(),
    type: "intent.dispatched",
    sessionId: item.intent.sessionId,
    runId: item.intent.runId,
    createdAt: new Date().toISOString(),
    correlationId: item.intent.correlationId,
    payload: {
      intentId: item.intent.intentId,
      dispatchTarget: target,
    },
  };
}

function createCapabilityResultReceivedEvent(
  item: PortQueueItem,
  response: CapabilityPortResponse,
): CapabilityResultReceivedEvent {
  return {
    eventId: randomUUID(),
    type: "capability.result_received",
    sessionId: item.intent.sessionId,
    runId: item.intent.runId,
    createdAt: response.completedAt ?? new Date().toISOString(),
    correlationId: item.intent.correlationId,
    payload: {
      requestId: item.request.requestId,
      resultId: response.result?.resultId ?? randomUUID(),
      status: response.result?.status ?? "failed",
    },
  };
}

export class CapabilityPortBroker {
  readonly #registry = new CapabilityPortRegistry();
  readonly #queue = new CapabilityPortQueue();
  readonly #idempotency = new CapabilityPortIdempotencyCache();
  readonly #preparedInvocationCache = new Map<string, CapabilityPreparedInvocationEntry>();
  readonly #inflight = new Map<string, PortInflightItem>();
  readonly #resultListeners = new Set<CapabilityResultCallback>();
  readonly #backpressure: PortBackpressureMonitor;
  readonly #journal?: CapabilityPortBrokerOptions["journal"];
  readonly #clock: () => Date;
  readonly #options: Required<Pick<CapabilityPortBrokerOptions, "maxInflight" | "maxQueueDepth">> & CapabilityPortBrokerOptions;

  constructor(options: CapabilityPortBrokerOptions = {}) {
    this.#options = {
      maxInflight: options.maxInflight ?? 16,
      maxQueueDepth: options.maxQueueDepth ?? 128,
      ...options,
    };
    this.#journal = options.journal;
    this.#clock = options.clock ?? (() => new Date());
    this.#backpressure = new PortBackpressureMonitor({
      maxInflight: this.#options.maxInflight,
      maxQueueDepth: this.#options.maxQueueDepth,
      clock: this.#clock,
    });
  }

  registerCapabilityPort(definition: CapabilityPortDefinition): void {
    this.#registry.register(definition);
  }

  listCapabilityPorts(): readonly CapabilityPortDefinition[] {
    return this.#registry.list();
  }

  onResult(callback: CapabilityResultCallback): () => void {
    this.#resultListeners.add(callback);
    return () => {
      this.#resultListeners.delete(callback);
    };
  }

  onBackpressureSignal(listener: Parameters<PortBackpressureMonitor["onSignal"]>[0]): () => void {
    return this.#backpressure.onSignal(listener);
  }

  enqueueIntent(input: EnqueueCapabilityIntentInput): CapabilityPortResponse {
    const { intent } = input;
    const cached = this.#idempotency.get(intent.request.idempotencyKey ?? intent.idempotencyKey);
    if (cached) {
      return cached;
    }

    this.#queue.enqueue(intent, intent.request);
    this.#appendJournal(createIntentQueuedEvent(intent));
    this.#backpressure.notifyIfChanged(this.#queue.size(), this.#inflight.size);

    return {
      requestId: intent.request.requestId,
      intentId: intent.intentId,
      sessionId: intent.sessionId,
      runId: intent.runId,
      status: "queued",
      metadata: {
        enqueuedAt: this.#clock().toISOString(),
      },
    };
  }

  async dispatchNext(): Promise<CapabilityDispatchReceipt | undefined> {
    if (this.#inflight.size >= this.#options.maxInflight) {
      this.#backpressure.notifyIfChanged(this.#queue.size(), this.#inflight.size);
      return undefined;
    }

    const next = this.#queue.dequeue();
    if (!next) {
      this.#backpressure.notifyIfChanged(0, this.#inflight.size);
      return undefined;
    }

    const cached = this.#idempotency.get(next.request.idempotencyKey ?? next.intent.idempotencyKey);
    if (cached) {
      this.#notifyResult({
        intent: next.intent,
        request: next.request,
        response: cached,
        fromCache: true,
      });
      this.#appendJournal(createCapabilityResultReceivedEvent(next, cached));
      this.#backpressure.notifyIfChanged(this.#queue.size(), this.#inflight.size);
      return {
        response: cached,
        fromCache: true,
      };
    }

    const definition = this.#registry.get(next.request.capabilityKey);
    if (!definition) {
      throw new RaxRoutingError(
        "agent_core_capability_port_missing_handler",
        `No capability port is registered for ${next.request.capabilityKey}.`,
      );
    }

    const inflight: PortInflightItem = {
      ...next,
      dispatchedAt: this.#clock().toISOString(),
    };
    this.#inflight.set(next.request.requestId, inflight);
    this.#appendJournal(createIntentDispatchedEvent(next, definition.capabilityKey));
    this.#backpressure.notifyIfChanged(this.#queue.size(), this.#inflight.size);

    try {
      const handlerResult = await this.#runHandler(definition, next.request);
      const response = this.#toCompletedResponse(next, handlerResult);
      this.#idempotency.set(next.request.idempotencyKey ?? next.intent.idempotencyKey, response);
      this.#appendJournal(createCapabilityResultReceivedEvent(next, response));
      this.#notifyResult({
        intent: next.intent,
        request: next.request,
        response,
        fromCache: false,
      });
      return {
        response,
        fromCache: false,
      };
    } catch (error) {
      const response = this.#toFailedResponse(next, error);
      this.#appendJournal(createCapabilityResultReceivedEvent(next, response));
      this.#notifyResult({
        intent: next.intent,
        request: next.request,
        response,
        fromCache: false,
      });
      return {
        response,
        fromCache: false,
      };
    } finally {
      this.#inflight.delete(next.request.requestId);
      this.#backpressure.notifyIfChanged(this.#queue.size(), this.#inflight.size);
    }
  }

  getBackpressureState(): BackpressureState {
    return this.#backpressure.evaluate(this.#queue.size(), this.#inflight.size);
  }

  getStats(): CapabilityPortStats {
    return {
      queued: this.#queue.size(),
      inflight: this.#inflight.size,
      handlers: this.#registry.list().length,
      cachedResponses: this.#idempotency.size(),
      preparedInvocationEntries: this.#preparedInvocationCache.size,
    };
  }

  setPreparedInvocation(cacheKey: string, entry: Omit<CapabilityPreparedInvocationEntry, "cacheKey" | "createdAt">): CapabilityPreparedInvocationEntry {
    const prepared: CapabilityPreparedInvocationEntry = {
      cacheKey,
      createdAt: this.#clock().toISOString(),
      ...entry,
    };
    this.#preparedInvocationCache.set(cacheKey, prepared);
    return prepared;
  }

  getPreparedInvocation(cacheKey: string): CapabilityPreparedInvocationEntry | undefined {
    return this.#preparedInvocationCache.get(cacheKey);
  }

  #appendJournal(event: KernelEvent): void {
    this.#journal?.appendEvent(event);
  }

  async #runHandler(
    definition: CapabilityPortDefinition,
    request: CapabilityPortRequest,
  ) {
    const timeoutMs = request.timeoutMs ?? definition.timeoutMs;
    if (!timeoutMs) {
      return definition.handler(request);
    }

    return Promise.race([
      definition.handler(request),
      new Promise<never>((_, reject) => {
        const timer = setTimeout(() => {
          reject(new RaxRoutingError(
            "agent_core_capability_timeout",
            `Capability ${definition.capabilityKey} timed out after ${timeoutMs}ms.`,
          ));
        }, timeoutMs);
        timer.unref?.();
      }),
    ]);
  }

  #toCompletedResponse(
    item: PortQueueItem,
    handlerResult: Awaited<ReturnType<CapabilityPortDefinition["handler"]>>,
  ): CapabilityPortResponse {
    return {
      requestId: item.request.requestId,
      intentId: item.intent.intentId,
      sessionId: item.intent.sessionId,
      runId: item.intent.runId,
      status: handlerResult.error ? "failed" : "completed",
      result: handlerResult.result,
      output: handlerResult.output,
      artifacts: handlerResult.artifacts,
      evidence: handlerResult.evidence,
      error: handlerResult.error,
      completedAt: this.#clock().toISOString(),
      metadata: handlerResult.metadata,
    };
  }

  #toFailedResponse(item: PortQueueItem, error: unknown): CapabilityPortResponse {
    return {
      requestId: item.request.requestId,
      intentId: item.intent.intentId,
      sessionId: item.intent.sessionId,
      runId: item.intent.runId,
      status: error instanceof RaxRoutingError && error.code === "agent_core_capability_timeout"
        ? "timed_out"
        : "failed",
      error: {
        code: error instanceof RaxRoutingError ? error.code : "agent_core_capability_failed",
        message: error instanceof Error ? error.message : "Capability handler failed.",
        retryable: error instanceof RaxRoutingError ? false : undefined,
      },
      completedAt: this.#clock().toISOString(),
    };
  }

  #notifyResult(payload: CapabilityResultCallbackPayload): void {
    for (const listener of this.#resultListeners) {
      listener(payload);
    }
  }
}
