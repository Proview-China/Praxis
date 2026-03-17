import { RaxRoutingError } from "../../rax/errors.js";
import type { CapabilityPortDefinition } from "./port-types.js";

export class CapabilityPortRegistry {
  readonly #definitions = new Map<string, CapabilityPortDefinition>();

  register(definition: CapabilityPortDefinition): void {
    if (this.#definitions.has(definition.capabilityKey)) {
      throw new RaxRoutingError(
        "agent_core_capability_port_duplicate",
        `Capability port ${definition.capabilityKey} is already registered.`
      );
    }

    this.#definitions.set(definition.capabilityKey, definition);
  }

  get(capabilityKey: string): CapabilityPortDefinition | undefined {
    return this.#definitions.get(capabilityKey);
  }

  list(): readonly CapabilityPortDefinition[] {
    return [...this.#definitions.values()];
  }
}
