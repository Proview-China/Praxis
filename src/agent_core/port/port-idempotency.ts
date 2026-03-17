import type { CapabilityPortResponse } from "../types/kernel-results.js";

export class CapabilityPortIdempotencyCache {
  readonly #responses = new Map<string, CapabilityPortResponse>();

  get(key: string | undefined): CapabilityPortResponse | undefined {
    if (!key) {
      return undefined;
    }
    return this.#responses.get(key);
  }

  set(key: string | undefined, response: CapabilityPortResponse): void {
    if (!key) {
      return;
    }
    this.#responses.set(key, response);
  }

  size(): number {
    return this.#responses.size;
  }
}
