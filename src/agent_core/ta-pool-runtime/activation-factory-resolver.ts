import type { CapabilityPackage } from "../capability-package/index.js";
import type { CapabilityAdapter, CapabilityManifest } from "../capability-types/index.js";
import type { ProvisionAssetRecord } from "../ta-pool-provision/index.js";
import type { PoolActivationSpec } from "../ta-pool-types/index.js";
import type { MaterializedActivationRegistrationInput } from "./activation-materializer.js";

export interface ActivationAdapterFactoryContext {
  capabilityPackage?: CapabilityPackage;
  activationSpec?: PoolActivationSpec;
  manifest?: CapabilityManifest;
  bindingPayload?: Record<string, unknown>;
  manifestPayload?: Record<string, unknown>;
  asset?: ProvisionAssetRecord;
  materialized?: MaterializedActivationRegistrationInput;
  metadata?: Record<string, unknown>;
}

export type ActivationAdapterFactoryInput = ActivationAdapterFactoryContext;
export type ActivationAdapterFactory = (
  context: ActivationAdapterFactoryContext,
) => CapabilityAdapter;

export interface ActivationFactoryResolverLike {
  register(ref: string, factory: ActivationAdapterFactory): void;
  resolve(ref: string): ActivationAdapterFactory | undefined;
  has(ref: string): boolean;
  materialize(context: ActivationAdapterFactoryContext, ref?: string): CapabilityAdapter;
}

function assertNonEmpty(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return normalized;
}

export class ActivationFactoryResolver implements ActivationFactoryResolverLike {
  readonly #factories = new Map<string, ActivationAdapterFactory>();

  register(ref: string, factory: ActivationAdapterFactory): void {
    this.#factories.set(assertNonEmpty(ref, "Activation factory ref"), factory);
  }

  resolve(ref: string): ActivationAdapterFactory | undefined {
    return this.#factories.get(assertNonEmpty(ref, "Activation factory ref"));
  }

  has(ref: string): boolean {
    return this.resolve(ref) !== undefined;
  }

  materialize(
    context: ActivationAdapterFactoryContext,
    ref = context.materialized?.adapterFactoryRef ?? context.activationSpec?.adapterFactoryRef,
  ): CapabilityAdapter {
    if (!ref) {
      throw new Error("Activation factory materialization requires an adapter factory ref.");
    }
    const factory = this.resolve(ref);
    if (!factory) {
      throw new Error(`No activation adapter factory is registered for ${ref}.`);
    }
    return factory(context);
  }
}

export function createActivationFactoryResolver(): ActivationFactoryResolver {
  return new ActivationFactoryResolver();
}
