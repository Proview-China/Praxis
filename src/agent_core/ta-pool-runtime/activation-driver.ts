import { randomUUID } from "node:crypto";

import type { CapabilityAdapter } from "../capability-types/index.js";
import {
  createTaActivationAttemptRecord,
  createTaActivationFailure,
  createTaActivationReceipt,
  type TaActivationAttemptRecord,
  type TaActivationFailure,
  type TaActivationReceipt,
} from "./activation-types.js";
import type {
  MaterializedActivationRegistrationInput,
} from "./activation-materializer.js";
import type { ActivationFactoryResolverLike } from "./activation-factory-resolver.js";
import type { ProvisionAssetRecord } from "../ta-pool-provision/index.js";

export interface ActivationDriverInput {
  asset: ProvisionAssetRecord;
  materialized: MaterializedActivationRegistrationInput;
  poolRegistry: {
    getActiveRegistrationsForCapability(capabilityKey: string): ReadonlyArray<{
      binding: {
        bindingId: string;
        generation: number;
        capabilityId: string;
      };
      manifest: {
        capabilityKey: string;
      };
      adapter: CapabilityAdapter;
    }>;
    register(manifest: MaterializedActivationRegistrationInput["manifest"], adapter: CapabilityAdapter): {
      binding: {
        bindingId: string;
        generation: number;
        capabilityId: string;
      };
      manifest: MaterializedActivationRegistrationInput["manifest"];
      adapter: CapabilityAdapter;
    };
    replace(bindingId: string, manifest: MaterializedActivationRegistrationInput["manifest"], adapter: CapabilityAdapter): {
      binding: {
        bindingId: string;
        generation: number;
        capabilityId: string;
      };
      manifest: MaterializedActivationRegistrationInput["manifest"];
      adapter: CapabilityAdapter;
    };
  };
  factoryResolver: ActivationFactoryResolverLike;
  clock?: () => Date;
  idFactory?: () => string;
}

export interface ActivationDriverSuccessResult {
  status: "activated";
  attempt: TaActivationAttemptRecord;
  receipt: TaActivationReceipt;
  binding: {
    bindingId: string;
    generation: number;
    capabilityId: string;
  };
  adapter: CapabilityAdapter;
  asset: ProvisionAssetRecord;
}

export interface ActivationDriverFailureResult {
  status: "failed";
  attempt: TaActivationAttemptRecord;
  failure: TaActivationFailure;
  asset: ProvisionAssetRecord;
}

export type ActivationDriverResult =
  | ActivationDriverSuccessResult
  | ActivationDriverFailureResult;

function cloneAsset(
  asset: ProvisionAssetRecord,
  status: ProvisionAssetRecord["status"],
  metadata: Record<string, unknown>,
  updatedAt: string,
): ProvisionAssetRecord {
  return {
    ...asset,
    status,
    updatedAt,
    metadata: {
      ...(asset.metadata ?? {}),
      ...metadata,
    },
  };
}

function resolveReplaceBindingId(input: ActivationDriverInput): string | undefined {
  return input.poolRegistry
    .getActiveRegistrationsForCapability(input.materialized.manifest.capabilityKey)[0]
    ?.binding.bindingId;
}

export function activateProvisionAsset(
  input: ActivationDriverInput,
): ActivationDriverResult {
  const now = (input.clock ?? (() => new Date()))().toISOString();
  const attempt = createTaActivationAttemptRecord({
    attemptId: (input.idFactory ?? randomUUID)(),
    provisionId: input.asset.provisionId,
    capabilityKey: input.asset.capabilityKey,
    targetPool: input.materialized.targetPool,
    activationMode: input.materialized.activationMode,
    registrationStrategy: input.materialized.registrationStrategy,
    startedAt: now,
    metadata: {
      bundleId: input.asset.bundleId,
      assetId: input.asset.assetId,
    },
  });

  try {
    const adapter = input.factoryResolver.materialize({
      activationSpec: input.asset.activation.spec!,
      asset: input.asset,
      materialized: input.materialized,
      manifest: input.materialized.manifest,
      bindingPayload: input.materialized.bindingPayload,
    });
    const replaceBindingId = resolveReplaceBindingId(input);
    const registration = input.materialized.registrationStrategy === "replace"
      ? input.poolRegistry.replace(
        replaceBindingId ?? (() => {
          throw new Error("Activation replace strategy requires an existing active binding.");
        })(),
        input.materialized.manifest,
        adapter,
      )
      : input.materialized.registrationStrategy === "register_or_replace" && replaceBindingId
        ? input.poolRegistry.replace(
          replaceBindingId,
          input.materialized.manifest,
          adapter,
        )
        : input.poolRegistry.register(
          input.materialized.manifest,
          adapter,
        );

    const receipt = createTaActivationReceipt({
      attemptId: attempt.attemptId,
      provisionId: input.asset.provisionId,
      capabilityKey: input.asset.capabilityKey,
      targetPool: input.materialized.targetPool,
      capabilityId: registration.binding.capabilityId,
      bindingId: registration.binding.bindingId,
      generation: registration.binding.generation,
      registrationStrategy: replaceBindingId ? "replace" : "register",
      activatedAt: now,
      metadata: {
        assetId: input.asset.assetId,
      },
    });

    return {
      status: "activated",
      attempt: {
        ...attempt,
        status: "succeeded",
        updatedAt: now,
        completedAt: now,
        receipt,
      },
      receipt,
      binding: registration.binding,
      adapter,
      asset: cloneAsset(input.asset, "active", {
        activationAttemptId: attempt.attemptId,
        activationReceipt: receipt,
      }, now),
    } satisfies ActivationDriverResult;
  } catch (error) {
    const failure = createTaActivationFailure({
      attemptId: attempt.attemptId,
      provisionId: input.asset.provisionId,
      capabilityKey: input.asset.capabilityKey,
      failedAt: now,
      code: "ta_pool_activation_failed",
      message: error instanceof Error ? error.message : String(error),
    });

    return {
      status: "failed",
      attempt: {
        ...attempt,
        status: "failed",
        updatedAt: now,
        completedAt: now,
        failure,
      },
      failure,
      asset: cloneAsset(input.asset, "failed", {
        activationAttemptId: attempt.attemptId,
        activationFailure: failure,
      }, now),
    } satisfies ActivationDriverResult;
  }
}

export async function runActivationDriver(
  input: ActivationDriverInput,
): Promise<ActivationDriverResult> {
  return await activateProvisionAsset(input);
}
