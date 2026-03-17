import type { CapabilityCallIntent, CapabilityPortRequest } from "../types/kernel-intents.js";
import type { PortQueueItem } from "./port-types.js";
import { INTENT_PRIORITY_ORDER } from "./port-types.js";

function compareQueueItems(left: PortQueueItem, right: PortQueueItem): number {
  const priorityDelta =
    INTENT_PRIORITY_ORDER[left.request.priority] - INTENT_PRIORITY_ORDER[right.request.priority];
  if (priorityDelta !== 0) {
    return priorityDelta;
  }

  const createdAtDelta =
    new Date(left.intent.createdAt).getTime() - new Date(right.intent.createdAt).getTime();
  if (createdAtDelta !== 0) {
    return createdAtDelta;
  }

  return left.intent.intentId.localeCompare(right.intent.intentId, "en");
}

export class CapabilityPortQueue {
  readonly #items: PortQueueItem[] = [];

  enqueue(intent: CapabilityCallIntent, request: CapabilityPortRequest): PortQueueItem {
    const item: PortQueueItem = {
      intent,
      request,
      enqueuedAt: intent.createdAt,
    };

    this.#items.push(item);
    this.#items.sort(compareQueueItems);
    return item;
  }

  dequeue(): PortQueueItem | undefined {
    return this.#items.shift();
  }

  size(): number {
    return this.#items.length;
  }

  peek(): PortQueueItem | undefined {
    return this.#items[0];
  }

  list(): readonly PortQueueItem[] {
    return this.#items;
  }
}
