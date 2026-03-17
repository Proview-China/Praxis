import type { BackpressureSignal, BackpressureState } from "./port-types.js";

export interface PortBackpressureMonitorOptions {
  maxQueueDepth: number;
  maxInflight: number;
  clock?: () => Date;
}

export class PortBackpressureMonitor {
  readonly #maxQueueDepth: number;
  readonly #maxInflight: number;
  readonly #clock: () => Date;
  readonly #listeners = new Set<(signal: BackpressureSignal) => void>();
  #lastState?: string;

  constructor(options: PortBackpressureMonitorOptions) {
    this.#maxQueueDepth = options.maxQueueDepth;
    this.#maxInflight = options.maxInflight;
    this.#clock = options.clock ?? (() => new Date());
  }

  evaluate(queueDepth: number, inflight: number): BackpressureState {
    if (inflight > this.#maxInflight) {
      return {
        active: true,
        queueDepth,
        inflight,
        reason: "inflight-threshold",
      };
    }

    if (queueDepth > this.#maxQueueDepth) {
      return {
        active: true,
        queueDepth,
        inflight,
        reason: "queue-threshold",
      };
    }

    return {
      active: false,
      queueDepth,
      inflight,
    };
  }

  notifyIfChanged(queueDepth: number, inflight: number): BackpressureState {
    const next = this.evaluate(queueDepth, inflight);
    const nextKey = `${next.active}:${next.reason ?? "none"}:${next.queueDepth}:${next.inflight}`;
    if (nextKey !== this.#lastState) {
      this.#lastState = nextKey;
      const signal: BackpressureSignal = {
        ...next,
        emittedAt: this.#clock().toISOString(),
      };
      for (const listener of this.#listeners) {
        listener(signal);
      }
    }
    return next;
  }

  onSignal(listener: (signal: BackpressureSignal) => void): () => void {
    this.#listeners.add(listener);
    return () => {
      this.#listeners.delete(listener);
    };
  }
}
