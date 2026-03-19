import type { CapabilityPackage } from "../capability-package/index.js";
import type {
  CapabilityAdapter,
  CapabilityManifest,
  CapabilityRouteHint,
} from "../capability-types/index.js";
import type { ProvisionAssetRecord } from "../ta-pool-provision/index.js";
import type {
  PoolActivationMode,
  PoolActivationSpec,
  PoolDrainStrategy,
  PoolGenerationStrategy,
  PoolRegistrationStrategy,
  ProvisionArtifactRef,
} from "../ta-pool-types/index.js";
import type { ActivationFactoryResolverLike } from "./activation-factory-resolver.js";

export interface MaterializedActivationRegistrationInput {
  manifest: CapabilityManifest;
  targetPool: string;
  activationMode: PoolActivationMode;
  registrationStrategy: PoolRegistrationStrategy;
  generationStrategy: PoolGenerationStrategy;
  drainStrategy: PoolDrainStrategy;
  adapterFactoryRef: string;
  bindingPayload: Record<string, unknown>;
  bindingArtifactRef?: string;
  rollbackHandle?: ProvisionArtifactRef;
  metadata?: Record<string, unknown>;
}

export interface ActivationMaterializedRegistration
  extends MaterializedActivationRegistrationInput {
  capabilityPackage?: CapabilityPackage;
  adapter: CapabilityAdapter;
}

export type MaterializedActivationRegistration = ActivationMaterializedRegistration;

export interface MaterializeProvisionAssetActivationInput {
  asset: ProvisionAssetRecord;
  activationSpec?: PoolActivationSpec;
}

export interface MaterializeActivationRegistrationInput {
  capabilityPackage: CapabilityPackage;
  factoryResolver: ActivationFactoryResolverLike;
  capabilityIdPrefix?: string;
}

function assertNonEmpty(value: unknown, label: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error(`${label} requires a non-empty string.`);
  }
  return value.trim();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function readBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

function readStringArray(value: unknown): string[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }
  const normalized = [...new Set(
    value
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean),
  )];
  return normalized.length > 0 ? normalized : undefined;
}

function readRouteHints(value: unknown): CapabilityRouteHint[] | undefined {
  if (!Array.isArray(value)) {
    return undefined;
  }
  const routeHints = value
    .filter((item): item is Record<string, unknown> => isRecord(item))
    .map((item) => ({
      key: assertNonEmpty(item.key, "Activation route hint key"),
      value: assertNonEmpty(item.value, "Activation route hint value"),
    }));
  return routeHints.length > 0 ? routeHints : undefined;
}

function normalizeCapabilityKind(kind: unknown): CapabilityManifest["kind"] {
  return kind === "model" || kind === "resource" || kind === "runtime"
    ? kind
    : "tool";
}

function materializeManifestFromPayload(params: {
  capabilityKeyFallback: string;
  payload: Record<string, unknown>;
  capabilityIdPrefix?: string;
  preferStableCapabilityId?: boolean;
}): CapabilityManifest {
  const capabilityKey = typeof params.payload.capabilityKey === "string" && params.payload.capabilityKey.trim()
    ? params.payload.capabilityKey.trim()
    : params.capabilityKeyFallback;
  const generation = Number.isInteger(params.payload.generation) && Number(params.payload.generation) >= 0
    ? Number(params.payload.generation)
    : 1;
  const explicitCapabilityId = typeof params.payload.capabilityId === "string" && params.payload.capabilityId.trim()
    ? params.payload.capabilityId.trim()
    : undefined;
  const capabilityId = params.capabilityIdPrefix
    ? `${params.capabilityIdPrefix}:${capabilityKey}:${generation}`
    : params.preferStableCapabilityId
      ? explicitCapabilityId ?? `capability:${capabilityKey}:${generation}`
      : explicitCapabilityId ?? `capability:${capabilityKey}`;

  return {
    capabilityId,
    capabilityKey,
    kind: normalizeCapabilityKind(params.payload.kind ?? params.payload.capabilityKind),
    version: typeof params.payload.version === "string" && params.payload.version.trim()
      ? params.payload.version.trim()
      : "0.0.0-dev",
    generation,
    description: typeof params.payload.description === "string" && params.payload.description.trim()
      ? params.payload.description.trim()
      : `Provisioned capability ${capabilityKey}.`,
    supportsStreaming: readBoolean(params.payload.supportsStreaming),
    supportsCancellation: readBoolean(params.payload.supportsCancellation),
    supportsPrepare: readBoolean(params.payload.supportsPrepare, true),
    hotPath: readBoolean(params.payload.hotPath),
    routeHints: readRouteHints(params.payload.routeHints),
    tags: readStringArray(params.payload.tags),
    metadata: isRecord(params.payload.metadata) ? params.payload.metadata : undefined,
  };
}

export function materializeCapabilityManifestFromActivation(input: {
  capabilityPackage?: CapabilityPackage;
  activationSpec: PoolActivationSpec;
  capabilityIdPrefix?: string;
  capabilityKeyFallback?: string;
}): CapabilityManifest {
  const manifest = materializeManifestFromPayload({
    capabilityKeyFallback:
      input.capabilityPackage?.manifest.capabilityKey
      ?? input.capabilityKeyFallback
      ?? "unknown.capability",
    payload: input.activationSpec.manifestPayload,
    capabilityIdPrefix: input.capabilityIdPrefix,
    preferStableCapabilityId: input.capabilityPackage === undefined,
  });

  if (
    input.capabilityPackage
    && manifest.capabilityKey !== input.capabilityPackage.manifest.capabilityKey
  ) {
    throw new Error(
      `Activation manifest capabilityKey ${manifest.capabilityKey} does not match capability package ${input.capabilityPackage.manifest.capabilityKey}.`,
    );
  }

  return manifest;
}

export function materializeProvisionAssetActivation(
  input: MaterializeProvisionAssetActivationInput,
): MaterializedActivationRegistrationInput {
  const activationSpec = input.activationSpec ?? input.asset.activation.spec;
  if (!activationSpec) {
    throw new Error(
      `Provision asset ${input.asset.provisionId} is missing a PoolActivationSpec.`,
    );
  }

  return {
    manifest: materializeCapabilityManifestFromActivation({
      activationSpec,
      capabilityKeyFallback: input.asset.capabilityKey,
    }),
    targetPool: assertNonEmpty(activationSpec.targetPool, "Pool activation targetPool"),
    activationMode: activationSpec.activationMode,
    registrationStrategy: activationSpec.registerOrReplace,
    generationStrategy: activationSpec.generationStrategy,
    drainStrategy: activationSpec.drainStrategy,
    adapterFactoryRef: assertNonEmpty(
      activationSpec.adapterFactoryRef,
      "Pool activation adapterFactoryRef",
    ),
    bindingPayload: activationSpec.bindingPayload,
    bindingArtifactRef: input.asset.activation.bindingArtifactRef,
    rollbackHandle: activationSpec.rollbackHandle,
    metadata: {
      ...(activationSpec.metadata ?? {}),
      provisionId: input.asset.provisionId,
      bundleId: input.asset.bundleId,
      assetId: input.asset.assetId,
    },
  };
}

function createAssetFromCapabilityPackage(
  capabilityPackage: CapabilityPackage,
): ProvisionAssetRecord {
  const activationSpec = capabilityPackage.activationSpec;
  if (!activationSpec) {
    throw new Error(
      `Capability package ${capabilityPackage.manifest.capabilityKey} is missing an activationSpec.`,
    );
  }

  return {
    assetId: capabilityPackage.artifacts?.bindingArtifact.artifactId ?? `${capabilityPackage.manifest.capabilityKey}:asset`,
    provisionId: typeof capabilityPackage.metadata?.provisionId === "string"
      ? capabilityPackage.metadata.provisionId
      : `${capabilityPackage.manifest.capabilityKey}:provision`,
    bundleId: typeof capabilityPackage.metadata?.bundleId === "string"
      ? capabilityPackage.metadata.bundleId
      : `${capabilityPackage.manifest.capabilityKey}:bundle`,
    capabilityKey: capabilityPackage.manifest.capabilityKey,
    status: "ready_for_review",
    toolArtifact: capabilityPackage.artifacts?.toolArtifact ?? { artifactId: `${capabilityPackage.manifest.capabilityKey}:tool`, kind: "tool" },
    bindingArtifact: capabilityPackage.artifacts?.bindingArtifact ?? { artifactId: `${capabilityPackage.manifest.capabilityKey}:binding`, kind: "binding" },
    verificationArtifact: capabilityPackage.artifacts?.verificationArtifact ?? { artifactId: `${capabilityPackage.manifest.capabilityKey}:verification`, kind: "verification" },
    usageArtifact: capabilityPackage.artifacts?.usageArtifact ?? { artifactId: `${capabilityPackage.manifest.capabilityKey}:usage`, kind: "usage" },
    activation: {
      bindingArtifact: capabilityPackage.artifacts?.bindingArtifact ?? { artifactId: `${capabilityPackage.manifest.capabilityKey}:binding`, kind: "binding" },
      bindingArtifactRef: capabilityPackage.artifacts?.bindingArtifact?.ref,
      targetPool: activationSpec.targetPool,
      adapterFactoryRef: activationSpec.adapterFactoryRef,
      spec: activationSpec,
    },
    replayPolicy: capabilityPackage.replayPolicy,
    createdAt: typeof capabilityPackage.metadata?.createdAt === "string"
      ? capabilityPackage.metadata.createdAt
      : new Date(0).toISOString(),
    updatedAt: typeof capabilityPackage.metadata?.updatedAt === "string"
      ? capabilityPackage.metadata.updatedAt
      : new Date(0).toISOString(),
    metadata: capabilityPackage.metadata,
  };
}

export async function materializeActivationRegistration(
  input: MaterializeActivationRegistrationInput,
): Promise<ActivationMaterializedRegistration> {
  const { capabilityPackage } = input;
  const activationSpec = capabilityPackage.activationSpec;
  if (!activationSpec) {
    throw new Error(
      `Capability package ${capabilityPackage.manifest.capabilityKey} is missing an activation spec.`,
    );
  }

  const asset = createAssetFromCapabilityPackage(capabilityPackage);
  const materialized = materializeProvisionAssetActivation({
    asset,
    activationSpec,
  });
  const adapter = input.factoryResolver.materialize({
    capabilityPackage,
    activationSpec,
    manifest: materialized.manifest,
    bindingPayload: materialized.bindingPayload,
    asset,
    materialized,
  });

  return {
    ...materialized,
    capabilityPackage,
    adapter,
  };
}
