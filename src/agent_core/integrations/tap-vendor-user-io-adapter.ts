import type {
  CapabilityAdapter,
  CapabilityInvocationPlan,
  CapabilityLease,
  CapabilityManifest,
  PreparedCapabilityCall,
} from "../capability-types/index.js";
import { createPreparedCapabilityCall } from "../capability-invocation/index.js";
import type { CapabilityPackage } from "../capability-package/index.js";
import {
  createCapabilityManifestFromPackage,
  createTapVendorUserIoCapabilityPackage,
  TAP_VENDOR_USER_IO_ACTIVATION_FACTORY_REFS,
  TAP_VENDOR_USER_IO_CAPABILITY_KEYS,
  type TapVendorUserIoCapabilityKey,
} from "../capability-package/index.js";
import { createCapabilityResultEnvelope } from "../capability-result/index.js";
import type { ReplayPolicy } from "../ta-pool-types/index.js";
import type { ActivationAdapterFactory } from "../ta-pool-runtime/index.js";

export interface TapVendorUserIoAdapterOptions {
  capabilityKey?: TapVendorUserIoCapabilityKey;
}

export interface TapVendorUserIoRegistrationTarget {
  registerCapabilityAdapter(
    manifest: CapabilityManifest,
    adapter: CapabilityAdapter,
  ): unknown;
  registerTaActivationFactory(
    ref: string,
    factory: ActivationAdapterFactory,
  ): void;
}

export interface RegisterTapVendorUserIoFamilyInput {
  runtime: TapVendorUserIoRegistrationTarget;
  capabilityKeys?: readonly TapVendorUserIoCapabilityKey[];
  replayPolicy?: ReplayPolicy;
}

export interface RegisterTapVendorUserIoFamilyResult {
  capabilityKeys: TapVendorUserIoCapabilityKey[];
  activationFactoryRefs: string[];
  manifests: CapabilityManifest[];
  packages: CapabilityPackage[];
  bindings: unknown[];
}

type PreparedUserIoState =
  | {
      capabilityKey: "request_user_input";
      payload: {
        questions: unknown[];
      };
    }
  | {
      capabilityKey: "request_permissions";
      payload: {
        permissions: Record<string, unknown>;
        reason?: string;
      };
    };

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || Array.isArray(value) || typeof value !== "object") {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim().length > 0 ? value : undefined;
}

function stableStringify(value: unknown): string {
  if (value === null || value === undefined) {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((entry) => stableStringify(entry)).join(",")}]`;
  }
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, entryValue]) => `${JSON.stringify(key)}:${stableStringify(entryValue)}`);
    return `{${entries.join(",")}}`;
  }
  return JSON.stringify(value);
}

function parsePreparedUserIoState(
  capabilityKey: TapVendorUserIoCapabilityKey,
  plan: CapabilityInvocationPlan,
): PreparedUserIoState {
  const input = plan.input;
  if (capabilityKey === "request_user_input") {
    const questions = Array.isArray(input.questions) ? input.questions : [];
    if (questions.length === 0) {
      throw new Error("request_user_input requires a non-empty questions array.");
    }
    return {
      capabilityKey,
      payload: {
        questions,
      },
    };
  }

  const permissions = asRecord(input.permissions);
  if (!permissions || Object.keys(permissions).length === 0) {
    throw new Error("request_permissions requires a non-empty permissions object.");
  }
  return {
    capabilityKey,
    payload: {
      permissions,
      reason: asString(input.reason),
    },
  };
}

export class TapVendorUserIoAdapter implements CapabilityAdapter {
  readonly id: string;
  readonly runtimeKind = "tap-vendor-user-io";
  readonly #capabilityKey: TapVendorUserIoCapabilityKey;
  readonly #preparedStates = new Map<string, PreparedUserIoState>();

  constructor(options: TapVendorUserIoAdapterOptions = {}) {
    this.#capabilityKey = options.capabilityKey ?? "request_user_input";
    this.id = `adapter:${this.#capabilityKey}`;
  }

  supports(plan: CapabilityInvocationPlan): boolean {
    return plan.capabilityKey === this.#capabilityKey;
  }

  async prepare(
    plan: CapabilityInvocationPlan,
    lease: CapabilityLease,
  ): Promise<PreparedCapabilityCall> {
    const state = parsePreparedUserIoState(this.#capabilityKey, plan);
    const prepared = createPreparedCapabilityCall({
      lease,
      capabilityKey: plan.capabilityKey,
      executionMode: "direct",
      preparedPayloadRef: `tap-vendor-user-io:${stableStringify(state.payload)}`,
      cacheKey: lease.preparedCacheKey ?? stableStringify(state.payload),
      metadata: {
        capabilityKey: this.#capabilityKey,
      },
    });
    this.#preparedStates.set(prepared.preparedId, state);
    return prepared;
  }

  async execute(prepared: PreparedCapabilityCall) {
    const state = this.#preparedStates.get(prepared.preparedId);
    if (!state) {
      return createCapabilityResultEnvelope({
        executionId: prepared.preparedId,
        status: "failed",
        error: {
          code: "tap_vendor_user_io_prepared_state_missing",
          message: `Prepared user-io state for ${prepared.preparedId} was not found.`,
        },
        metadata: {
          capabilityKey: this.#capabilityKey,
          runtimeKind: this.runtimeKind,
        },
      });
    }

    return createCapabilityResultEnvelope({
      executionId: prepared.preparedId,
      status: "blocked",
      error: {
        code:
          state.capabilityKey === "request_user_input"
            ? "tap_vendor_user_input_required"
            : "tap_vendor_permission_request_required",
        message:
          state.capabilityKey === "request_user_input"
            ? "Operator input is required before this workflow can continue."
            : "Additional operator permissions are required before this workflow can continue.",
        details: state.payload,
      },
      metadata: {
        capabilityKey: state.capabilityKey,
        runtimeKind: this.runtimeKind,
        waitingHuman: true,
      },
    });
  }

  async healthCheck() {
    return {
      status: "healthy",
      adapterId: this.id,
      runtimeKind: this.runtimeKind,
      capabilityKey: this.#capabilityKey,
    };
  }
}

export function createTapVendorUserIoAdapter(
  options: TapVendorUserIoAdapterOptions = {},
): TapVendorUserIoAdapter {
  return new TapVendorUserIoAdapter(options);
}

export function createTapVendorUserIoActivationFactory(
  options: TapVendorUserIoAdapterOptions = {},
): ActivationAdapterFactory {
  return (context) =>
    createTapVendorUserIoAdapter({
      ...options,
      capabilityKey:
        TAP_VENDOR_USER_IO_CAPABILITY_KEYS.includes(
          context.manifest?.capabilityKey as TapVendorUserIoCapabilityKey,
        )
          ? (context.manifest?.capabilityKey as TapVendorUserIoCapabilityKey)
          : options.capabilityKey,
    });
}

export function registerTapVendorUserIoFamily(
  input: RegisterTapVendorUserIoFamilyInput,
): RegisterTapVendorUserIoFamilyResult {
  const capabilityKeys = (input.capabilityKeys ?? TAP_VENDOR_USER_IO_CAPABILITY_KEYS) as
    readonly TapVendorUserIoCapabilityKey[];

  const manifests: CapabilityManifest[] = [];
  const packages: CapabilityPackage[] = [];
  const bindings: unknown[] = [];
  const activationFactoryRefs: string[] = [];

  for (const capabilityKey of capabilityKeys) {
    const capabilityPackage = createTapVendorUserIoCapabilityPackage({
      capabilityKey,
      replayPolicy: input.replayPolicy,
    });
    const manifest = createCapabilityManifestFromPackage(capabilityPackage);
    const activationFactoryRef =
      TAP_VENDOR_USER_IO_ACTIVATION_FACTORY_REFS[capabilityKey];
    const factory = createTapVendorUserIoActivationFactory({ capabilityKey });

    input.runtime.registerTaActivationFactory(activationFactoryRef, factory);
    const adapter = factory({
      capabilityPackage,
      activationSpec: capabilityPackage.activationSpec!,
      bindingPayload: capabilityPackage.activationSpec?.bindingPayload,
      manifest,
      manifestPayload: capabilityPackage.activationSpec?.manifestPayload,
      metadata: {
        registrationSource: "registerTapVendorUserIoFamily",
      },
    });
    const binding = input.runtime.registerCapabilityAdapter(manifest, adapter);

    manifests.push(manifest);
    packages.push(capabilityPackage);
    bindings.push(binding);
    activationFactoryRefs.push(activationFactoryRef);
  }

  return {
    capabilityKeys: [...capabilityKeys],
    activationFactoryRefs,
    manifests,
    packages,
    bindings,
  };
}
