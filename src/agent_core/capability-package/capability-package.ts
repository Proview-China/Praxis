import type {
  CapabilityKind,
  CapabilityRouteHint,
} from "../capability-types/capability-manifest.js";
import type {
  AccessRequestScope,
  ReviewVote,
  TaPoolRiskLevel,
} from "../ta-pool-types/ta-pool-review.js";
import {
  REVIEW_VOTES,
  TA_POOL_RISK_LEVELS,
} from "../ta-pool-types/ta-pool-review.js";
import type {
  TaCapabilityTier,
  TaPoolMode,
} from "../ta-pool-types/ta-pool-profile.js";
import {
  isTaPoolMode,
  TA_CAPABILITY_TIERS,
} from "../ta-pool-types/ta-pool-profile.js";
import type {
  PoolActivationSpec,
  PoolGenerationStrategy,
  ProvisionArtifactBundle,
  ProvisionArtifactRef,
  ReplayPolicy,
} from "../ta-pool-types/ta-pool-provision.js";
import {
  POOL_GENERATION_STRATEGIES,
  REPLAY_POLICIES,
  validatePoolActivationSpec,
  validateProvisionArtifactBundle,
} from "../ta-pool-types/ta-pool-provision.js";

export const CAPABILITY_PACKAGE_TEMPLATE_VERSION = "tap-capability-package.v1";
export const SUPPORTED_MCP_CAPABILITY_PACKAGE_KEYS = [
  "mcp.call",
  "mcp.native.execute",
] as const;
export type SupportedMcpCapabilityPackageKey =
  (typeof SUPPORTED_MCP_CAPABILITY_PACKAGE_KEYS)[number];

const MCP_CONFIGURE_CAPABILITY_KEY = "mcp.configure";

export interface CapabilityPackageManifest {
  capabilityKey: string;
  capabilityKind: CapabilityKind;
  tier: TaCapabilityTier;
  version: string;
  generation: number;
  description: string;
  dependencies: string[];
  tags: string[];
  routeHints: CapabilityRouteHint[];
  supportedPlatforms: string[];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageHookRef {
  ref: string;
  description?: string;
}

export interface CapabilityPackageResultMapping {
  successStatuses: string[];
  artifactKinds?: string[];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageAdapter {
  adapterId: string;
  runtimeKind: string;
  supports: string[];
  prepare: CapabilityPackageHookRef;
  execute: CapabilityPackageHookRef;
  cancel?: CapabilityPackageHookRef;
  resultMapping: CapabilityPackageResultMapping;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackagePolicyBaseline {
  grantedTier: TaCapabilityTier;
  mode: TaPoolMode;
  scope?: AccessRequestScope;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackagePolicy {
  defaultBaseline: CapabilityPackagePolicyBaseline;
  recommendedMode: TaPoolMode;
  riskLevel: TaPoolRiskLevel;
  defaultScope?: AccessRequestScope;
  reviewRequirements: ReviewVote[];
  safetyFlags: string[];
  humanGateRequirements: string[];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageBuilder {
  builderId: string;
  buildStrategy: string;
  requiresNetwork: boolean;
  requiresInstall: boolean;
  requiresSystemWrite: boolean;
  allowedWorkdirScope: string[];
  activationSpecRef: string;
  replayCapability: ReplayPolicy;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageVerification {
  smokeEntry: string;
  healthEntry: string;
  successCriteria: string[];
  failureSignals: string[];
  evidenceOutput: string[];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageUsageExample {
  exampleId: string;
  capabilityKey: string;
  operation: string;
  input: Record<string, unknown>;
  notes?: string;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageUsage {
  usageDocRef: string;
  skillRef?: string;
  bestPractices: string[];
  knownLimits: string[];
  exampleInvocations: CapabilityPackageUsageExample[];
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageLifecycle {
  installStrategy: string;
  replaceStrategy: string;
  rollbackStrategy: string;
  deprecateStrategy: string;
  cleanupStrategy: string;
  generationPolicy: PoolGenerationStrategy;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageArtifacts {
  toolArtifact: ProvisionArtifactRef;
  bindingArtifact: ProvisionArtifactRef;
  verificationArtifact: ProvisionArtifactRef;
  usageArtifact: ProvisionArtifactRef;
}

export interface CapabilityPackage {
  templateVersion: string;
  manifest: CapabilityPackageManifest;
  adapter: CapabilityPackageAdapter;
  policy: CapabilityPackagePolicy;
  builder: CapabilityPackageBuilder;
  verification: CapabilityPackageVerification;
  usage: CapabilityPackageUsage;
  lifecycle: CapabilityPackageLifecycle;
  activationSpec?: PoolActivationSpec;
  replayPolicy: ReplayPolicy;
  artifacts?: CapabilityPackageArtifacts;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageManifestInput {
  capabilityKey: string;
  capabilityKind: CapabilityKind;
  tier?: TaCapabilityTier;
  version?: string;
  generation?: number;
  description: string;
  dependencies?: string[];
  tags?: string[];
  routeHints?: CapabilityRouteHint[];
  supportedPlatforms?: string[];
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageAdapterInput {
  adapterId: string;
  runtimeKind: string;
  supports: string[];
  prepare: CapabilityPackageHookRef;
  execute: CapabilityPackageHookRef;
  cancel?: CapabilityPackageHookRef;
  resultMapping?: CapabilityPackageResultMapping;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackagePolicyInput {
  defaultBaseline: CapabilityPackagePolicyBaseline;
  recommendedMode: TaPoolMode;
  riskLevel: TaPoolRiskLevel;
  defaultScope?: AccessRequestScope;
  reviewRequirements?: ReviewVote[];
  safetyFlags?: string[];
  humanGateRequirements?: string[];
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageBuilderInput {
  builderId: string;
  buildStrategy: string;
  requiresNetwork?: boolean;
  requiresInstall?: boolean;
  requiresSystemWrite?: boolean;
  allowedWorkdirScope?: string[];
  activationSpecRef: string;
  replayCapability?: ReplayPolicy;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageVerificationInput {
  smokeEntry: string;
  healthEntry: string;
  successCriteria?: string[];
  failureSignals?: string[];
  evidenceOutput?: string[];
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageUsageExampleInput {
  exampleId: string;
  capabilityKey: string;
  operation: string;
  input?: Record<string, unknown>;
  notes?: string;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageUsageInput {
  usageDocRef: string;
  skillRef?: string;
  bestPractices?: string[];
  knownLimits?: string[];
  exampleInvocations?: CreateCapabilityPackageUsageExampleInput[];
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageLifecycleInput {
  installStrategy: string;
  replaceStrategy: string;
  rollbackStrategy: string;
  deprecateStrategy: string;
  cleanupStrategy: string;
  generationPolicy?: PoolGenerationStrategy;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageInput {
  templateVersion?: string;
  manifest: CreateCapabilityPackageManifestInput | CapabilityPackageManifest;
  adapter: CreateCapabilityPackageAdapterInput | CapabilityPackageAdapter;
  policy: CreateCapabilityPackagePolicyInput | CapabilityPackagePolicy;
  builder: CreateCapabilityPackageBuilderInput | CapabilityPackageBuilder;
  verification:
    | CreateCapabilityPackageVerificationInput
    | CapabilityPackageVerification;
  usage: CreateCapabilityPackageUsageInput | CapabilityPackageUsage;
  lifecycle: CreateCapabilityPackageLifecycleInput | CapabilityPackageLifecycle;
  activationSpec?: PoolActivationSpec;
  replayPolicy?: ReplayPolicy;
  artifacts?: CapabilityPackageArtifacts;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageFromProvisionBundleInput {
  bundle: ProvisionArtifactBundle;
  manifest: CreateCapabilityPackageManifestInput | CapabilityPackageManifest;
  adapter: CreateCapabilityPackageAdapterInput | CapabilityPackageAdapter;
  policy: CreateCapabilityPackagePolicyInput | CapabilityPackagePolicy;
  builder: CreateCapabilityPackageBuilderInput | CapabilityPackageBuilder;
  verification:
    | CreateCapabilityPackageVerificationInput
    | CapabilityPackageVerification;
  usage: CreateCapabilityPackageUsageInput | CapabilityPackageUsage;
  lifecycle: CreateCapabilityPackageLifecycleInput | CapabilityPackageLifecycle;
  metadata?: Record<string, unknown>;
}

export interface CreateCapabilityPackageFixtureInput {
  capabilityKey?: string;
  tier?: TaCapabilityTier;
  runtimeKind?: string;
  replayPolicy?: ReplayPolicy;
  activationSpec?: PoolActivationSpec;
}

export interface CreateMcpCapabilityPackageInput {
  capabilityKey: SupportedMcpCapabilityPackageKey;
  version?: string;
  generation?: number;
  replayPolicy?: ReplayPolicy;
  supportedPlatforms?: string[];
  routeHints?: CapabilityRouteHint[];
  metadata?: Record<string, unknown>;
}

function normalizeString(value: string, label: string): string {
  const normalized = value.trim();
  if (!normalized) {
    throw new Error(`${label} requires a non-empty value.`);
  }

  return normalized;
}

function normalizeStringArray(values?: readonly string[]): string[] {
  if (!values || values.length === 0) {
    return [];
  }

  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function normalizeRouteHints(
  routeHints?: readonly CapabilityRouteHint[],
): CapabilityRouteHint[] {
  if (!routeHints || routeHints.length === 0) {
    return [];
  }

  return routeHints
    .map((routeHint) => ({
      key: routeHint.key.trim(),
      value: routeHint.value.trim(),
    }))
    .filter((routeHint) => routeHint.key && routeHint.value);
}

function normalizeScope(scope?: AccessRequestScope): AccessRequestScope | undefined {
  if (!scope) {
    return undefined;
  }

  return {
    pathPatterns: normalizeStringArray(scope.pathPatterns),
    allowedOperations: normalizeStringArray(scope.allowedOperations),
    providerHints: normalizeStringArray(scope.providerHints),
    denyPatterns: normalizeStringArray(scope.denyPatterns),
    metadata: scope.metadata,
  };
}

function validateHookRef(label: string, hook: CapabilityPackageHookRef): void {
  normalizeString(hook.ref, `${label}.ref`);
  if (hook.description !== undefined) {
    normalizeString(hook.description, `${label}.description`);
  }
}

function validateArtifactRef(label: string, artifact: ProvisionArtifactRef): void {
  normalizeString(artifact.artifactId, `${label}.artifactId`);
  normalizeString(artifact.kind, `${label}.kind`);
  if (artifact.ref !== undefined) {
    normalizeString(artifact.ref, `${label}.ref`);
  }
}

function validateScope(label: string, scope?: AccessRequestScope): void {
  if (!scope) {
    return;
  }

  if (
    !scope.pathPatterns?.length &&
    !scope.allowedOperations?.length &&
    !scope.providerHints?.length &&
    !scope.denyPatterns?.length
  ) {
    throw new Error(`${label} requires at least one non-empty scope field.`);
  }
}

export function isSupportedMcpCapabilityPackageKey(
  capabilityKey: string,
): capabilityKey is SupportedMcpCapabilityPackageKey {
  return SUPPORTED_MCP_CAPABILITY_PACKAGE_KEYS.includes(
    capabilityKey as SupportedMcpCapabilityPackageKey,
  );
}

function createMcpCapabilityPackageActivationSpec(params: {
  capabilityKey: SupportedMcpCapabilityPackageKey;
  version: string;
  generation: number;
}): PoolActivationSpec {
  const slug = params.capabilityKey.replace(/\./g, "-");
  return {
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registerOrReplace: "register_or_replace",
    generationStrategy: "create_next_generation",
    drainStrategy: "graceful",
    manifestPayload: {
      capabilityKey: params.capabilityKey,
      version: params.version,
      generation: params.generation,
    },
    bindingPayload: {
      adapterId: `adapter.${slug}`,
      runtimeKind: "rax-mcp",
    },
    adapterFactoryRef: `factory:${slug}`,
  };
}

function createMcpCallCapabilityPackage(
  input: CreateMcpCapabilityPackageInput,
): CapabilityPackage {
  const version = input.version ?? "1.0.0";
  const generation = input.generation ?? 1;
  const replayPolicy = input.replayPolicy ?? "re_review_then_dispatch";
  const activationSpec = createMcpCapabilityPackageActivationSpec({
    capabilityKey: "mcp.call",
    version,
    generation,
  });

  return createCapabilityPackage({
    manifest: {
      capabilityKey: "mcp.call",
      capabilityKind: "tool",
      tier: "B1",
      version,
      generation,
      description: "Truthful shared-runtime MCP tool call surface with TAP review metadata.",
      dependencies: ["mcp.listTools"],
      tags: ["mcp", "tool-call", "shared-runtime", "truthful-surface"],
      routeHints: input.routeHints ?? [
        { key: "pool", value: "shared" },
        { key: "truthfulness", value: "shared-runtime" },
      ],
      supportedPlatforms: input.supportedPlatforms ?? ["linux", "macos", "windows"],
    },
    adapter: {
      adapterId: "adapter.mcp-call",
      runtimeKind: "rax-mcp",
      supports: ["mcp.call"],
      prepare: {
        ref: "adapter.prepare:rax-mcp.call",
        description: "Validate route plus connection-scoped tool invocation input.",
      },
      execute: {
        ref: "adapter.execute:rax-mcp.call",
        description: "Delegate to the shared rax MCP client call surface.",
      },
      resultMapping: {
        successStatuses: ["success"],
        artifactKinds: ["tool"],
        metadata: {
          resultSurface: "mcp.call",
        },
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: "B1",
        mode: "standard",
        scope: {
          pathPatterns: ["workspace/**"],
          allowedOperations: ["mcp.call", "read"],
          providerHints: ["mcp.shared-runtime"],
          denyPatterns: [MCP_CONFIGURE_CAPABILITY_KEY, "mcp.native.execute"],
        },
      },
      recommendedMode: "standard",
      riskLevel: "risky",
      defaultScope: {
        pathPatterns: ["workspace/**"],
        allowedOperations: ["mcp.call", "read"],
        providerHints: ["mcp.shared-runtime"],
        denyPatterns: [MCP_CONFIGURE_CAPABILITY_KEY],
      },
      reviewRequirements: ["allow_with_constraints"],
      safetyFlags: [
        "truthful_shared_runtime_surface",
        "remote_tool_side_effects",
        "requires_existing_connection",
        "no_mcp_configure",
      ],
      humanGateRequirements: [
        "unknown_remote_tool_side_effects_require_operator_judgement",
      ],
    },
    builder: {
      builderId: "builder.mcp-call",
      buildStrategy: "bind-existing-mcp-connection",
      requiresNetwork: false,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
    },
    verification: {
      smokeEntry: "smoke:mcp.call",
      healthEntry: "health:mcp.call",
      successCriteria: [
        "Active connection can invoke a tool and return normalized content.",
        "Remote tool failures stay surfaced as tool-level failures.",
      ],
      failureSignals: [
        "Connection is missing or stale.",
        "Requested tool is not exposed by the server.",
        "Invocation attempts to expand into mcp.configure.",
      ],
      evidenceOutput: ["normalized-call-result", "tool-error-envelope"],
    },
    usage: {
      usageDocRef: "docs/ability/25-tap-capability-package-template.md",
      bestPractices: [
        "Probe tool metadata with mcp.listTools before invoking unknown servers.",
        "Keep route/provider selection explicit so the shared-runtime lowering stays truthful.",
      ],
      knownLimits: [
        "Requires an existing connectionId and does not configure MCP servers.",
        "Resource and prompt surfaces remain separate MCP capabilities.",
      ],
      exampleInvocations: [
        {
          exampleId: "example.mcp.call.browser-search",
          capabilityKey: "mcp.call",
          operation: "mcp.call",
          input: {
            route: {
              provider: "openai",
              model: "gpt-5.4",
              layer: "agent",
            },
            input: {
              connectionId: "conn-browser",
              toolName: "browser.search",
              arguments: {
                q: "Praxis TAP",
              },
            },
          },
          notes: "Shared-runtime tool call example with an already-provisioned MCP connection.",
        },
      ],
    },
    lifecycle: {
      installStrategy: "bind to an existing MCP connection capability without provisioning configure hooks",
      replaceStrategy: "stage a new adapter generation before swapping call routing metadata",
      rollbackStrategy: "restore the previous call adapter generation",
      deprecateStrategy: "freeze new grants before removing the call adapter generation",
      cleanupStrategy: "remove superseded call metadata after drain",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy,
    metadata: {
      ...(input.metadata ?? {}),
      capabilityFamily: "mcp",
      thickness: "thick",
      truthfulness: "shared-runtime-call",
    },
  });
}

function createMcpNativeExecuteCapabilityPackage(
  input: CreateMcpCapabilityPackageInput,
): CapabilityPackage {
  const version = input.version ?? "1.0.0";
  const generation = input.generation ?? 1;
  const replayPolicy = input.replayPolicy ?? "re_review_then_dispatch";
  const activationSpec = createMcpCapabilityPackageActivationSpec({
    capabilityKey: "mcp.native.execute",
    version,
    generation,
  });

  return createCapabilityPackage({
    manifest: {
      capabilityKey: "mcp.native.execute",
      capabilityKind: "tool",
      tier: "B2",
      version,
      generation,
      description: "Provider-native MCP execute surface with long-running transport and TAP guardrails.",
      dependencies: [],
      tags: ["mcp", "native-execute", "provider-native", "long-running"],
      routeHints: input.routeHints ?? [
        { key: "pool", value: "native" },
        { key: "truthfulness", value: "provider-native" },
      ],
      supportedPlatforms: input.supportedPlatforms ?? ["linux", "macos", "windows"],
    },
    adapter: {
      adapterId: "adapter.mcp-native-execute",
      runtimeKind: "rax-mcp",
      supports: ["mcp.native.execute"],
      prepare: {
        ref: "adapter.prepare:rax-mcp.native.execute",
        description: "Validate native transport input and build a provider-native invocation.",
      },
      execute: {
        ref: "adapter.execute:rax-mcp.native.execute",
        description: "Delegate to the provider-native MCP execution runtime.",
      },
      cancel: {
        ref: "adapter.cancel:rax-mcp.native.execute",
        description: "Cancellation is handled by the runtime control plane when available.",
      },
      resultMapping: {
        successStatuses: ["success"],
        artifactKinds: ["tool"],
        metadata: {
          resultSurface: "mcp.native.execute",
          executionMode: "long-running",
        },
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: "B2",
        mode: "restricted",
        scope: {
          pathPatterns: ["workspace/**"],
          allowedOperations: ["mcp.native.execute", "exec"],
          providerHints: ["mcp.provider-native"],
          denyPatterns: [MCP_CONFIGURE_CAPABILITY_KEY, "workspace.outside.*"],
        },
      },
      recommendedMode: "restricted",
      riskLevel: "risky",
      defaultScope: {
        pathPatterns: ["workspace/**"],
        allowedOperations: ["mcp.native.execute", "exec"],
        providerHints: ["mcp.provider-native"],
        denyPatterns: [MCP_CONFIGURE_CAPABILITY_KEY, "system.write"],
      },
      reviewRequirements: ["escalate_to_human"],
      safetyFlags: [
        "provider_native_execution",
        "native_transport_side_effects",
        "long_running_invocation",
        "no_mcp_configure",
      ],
      humanGateRequirements: [
        "operator_review_required_before_native_transport_execution",
      ],
    },
    builder: {
      builderId: "builder.mcp-native-execute",
      buildStrategy: "bind-native-mcp-executor",
      requiresNetwork: false,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
    },
    verification: {
      smokeEntry: "smoke:mcp.native.execute",
      healthEntry: "health:mcp.native.execute",
      successCriteria: [
        "Supported transport input is lowered into a provider-native invocation.",
        "Execution result is returned without collapsing carrier metadata.",
      ],
      failureSignals: [
        "Transport kind is unsupported or missing required fields.",
        "Execution attempts to bypass review into mcp.configure.",
        "Provider-native invocation is missing its adapter metadata.",
      ],
      evidenceOutput: ["native-build-metadata", "native-execution-result"],
    },
    usage: {
      usageDocRef: "docs/ability/25-tap-capability-package-template.md",
      bestPractices: [
        "Prefer an explicit layer so provider-native lowering stays inspectable.",
        "Escalate before stdio transports that may spawn or attach to local processes.",
      ],
      knownLimits: [
        "Does not configure MCP servers or approve activation on its own.",
        "Long-running execution still depends on provider/runtime cancellation support.",
      ],
      exampleInvocations: [
        {
          exampleId: "example.mcp.native.execute.stdio",
          capabilityKey: "mcp.native.execute",
          operation: "mcp.native.execute",
          input: {
            route: {
              provider: "openai",
              model: "gpt-5.4",
              layer: "agent",
            },
            input: {
              transport: {
                kind: "stdio",
                command: "node",
                args: ["server.js"],
              },
            },
          },
          notes: "Native execution example that stays behind restricted-mode review.",
        },
      ],
    },
    lifecycle: {
      installStrategy: "register the native execute binding without widening into configure surfaces",
      replaceStrategy: "stage a new native execute generation before swapping bindings",
      rollbackStrategy: "restore the previous native execute generation",
      deprecateStrategy: "pause new native execute grants before removal",
      cleanupStrategy: "drain old native execute bindings before cleanup",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy,
    metadata: {
      ...(input.metadata ?? {}),
      capabilityFamily: "mcp",
      thickness: "thick",
      truthfulness: "provider-native-execute",
    },
  });
}

export function createMcpCapabilityPackage(
  input: CreateMcpCapabilityPackageInput,
): CapabilityPackage {
  switch (input.capabilityKey) {
    case "mcp.call":
      return createMcpCallCapabilityPackage(input);
    case "mcp.native.execute":
      return createMcpNativeExecuteCapabilityPackage(input);
  }
}

export function createCapabilityPackageActivationSpecRef(
  spec: Pick<PoolActivationSpec, "targetPool" | "activationMode" | "adapterFactoryRef">,
): string {
  return `activation-spec:${spec.targetPool}:${spec.activationMode}:${spec.adapterFactoryRef}`;
}

export function createCapabilityPackageManifest(
  input: CreateCapabilityPackageManifestInput | CapabilityPackageManifest,
): CapabilityPackageManifest {
  const manifest: CapabilityPackageManifest = {
    capabilityKey: normalizeString(input.capabilityKey, "manifest.capabilityKey"),
    capabilityKind: input.capabilityKind,
    tier: input.tier ?? "B1",
    version: normalizeString(input.version ?? "0.1.0", "manifest.version"),
    generation: input.generation ?? 1,
    description: normalizeString(input.description, "manifest.description"),
    dependencies: normalizeStringArray(input.dependencies),
    tags: normalizeStringArray(input.tags),
    routeHints: normalizeRouteHints(input.routeHints),
    supportedPlatforms: normalizeStringArray(input.supportedPlatforms ?? ["linux"]),
    metadata: input.metadata,
  };

  validateCapabilityPackageManifest(manifest);
  return manifest;
}

export function validateCapabilityPackageManifest(
  manifest: CapabilityPackageManifest,
): void {
  normalizeString(manifest.capabilityKey, "manifest.capabilityKey");
  normalizeString(manifest.version, "manifest.version");
  normalizeString(manifest.description, "manifest.description");

  if (!TA_CAPABILITY_TIERS.includes(manifest.tier)) {
    throw new Error(`Unsupported capability package tier: ${manifest.tier}.`);
  }

  if (!Number.isInteger(manifest.generation) || manifest.generation < 1) {
    throw new Error("Capability package manifest requires generation >= 1.");
  }

  if (manifest.supportedPlatforms.length === 0) {
    throw new Error("Capability package manifest requires at least one supportedPlatform.");
  }

  for (const routeHint of manifest.routeHints) {
    normalizeString(routeHint.key, "manifest.routeHints.key");
    normalizeString(routeHint.value, "manifest.routeHints.value");
  }
}

export function createCapabilityPackageAdapter(
  input: CreateCapabilityPackageAdapterInput | CapabilityPackageAdapter,
): CapabilityPackageAdapter {
  const adapter: CapabilityPackageAdapter = {
    adapterId: normalizeString(input.adapterId, "adapter.adapterId"),
    runtimeKind: normalizeString(input.runtimeKind, "adapter.runtimeKind"),
    supports: normalizeStringArray(input.supports),
    prepare: {
      ref: normalizeString(input.prepare.ref, "adapter.prepare.ref"),
      description: input.prepare.description?.trim() || undefined,
    },
    execute: {
      ref: normalizeString(input.execute.ref, "adapter.execute.ref"),
      description: input.execute.description?.trim() || undefined,
    },
    cancel: input.cancel
      ? {
          ref: normalizeString(input.cancel.ref, "adapter.cancel.ref"),
          description: input.cancel.description?.trim() || undefined,
        }
      : undefined,
    resultMapping: {
      successStatuses: normalizeStringArray(
        input.resultMapping?.successStatuses ?? ["success"],
      ),
      artifactKinds: normalizeStringArray(input.resultMapping?.artifactKinds),
      metadata: input.resultMapping?.metadata,
    },
    metadata: input.metadata,
  };

  validateCapabilityPackageAdapter(adapter);
  return adapter;
}

export function validateCapabilityPackageAdapter(
  adapter: CapabilityPackageAdapter,
): void {
  normalizeString(adapter.adapterId, "adapter.adapterId");
  normalizeString(adapter.runtimeKind, "adapter.runtimeKind");

  if (adapter.supports.length === 0) {
    throw new Error("Capability package adapter requires at least one supports entry.");
  }

  validateHookRef("adapter.prepare", adapter.prepare);
  validateHookRef("adapter.execute", adapter.execute);

  if (adapter.cancel) {
    validateHookRef("adapter.cancel", adapter.cancel);
  }

  if (adapter.resultMapping.successStatuses.length === 0) {
    throw new Error("Capability package adapter requires at least one resultMapping successStatus.");
  }
}

export function createCapabilityPackagePolicy(
  input: CreateCapabilityPackagePolicyInput | CapabilityPackagePolicy,
): CapabilityPackagePolicy {
  const policy: CapabilityPackagePolicy = {
    defaultBaseline: {
      grantedTier: input.defaultBaseline.grantedTier,
      mode: input.defaultBaseline.mode,
      scope: normalizeScope(input.defaultBaseline.scope),
      metadata: input.defaultBaseline.metadata,
    },
    recommendedMode: input.recommendedMode,
    riskLevel: input.riskLevel,
    defaultScope: normalizeScope(input.defaultScope),
    reviewRequirements: normalizeStringArray(
      input.reviewRequirements ?? ["allow_with_constraints"],
    ) as ReviewVote[],
    safetyFlags: normalizeStringArray(input.safetyFlags),
    humanGateRequirements: normalizeStringArray(input.humanGateRequirements),
    metadata: input.metadata,
  };

  validateCapabilityPackagePolicy(policy);
  return policy;
}

export function validateCapabilityPackagePolicy(
  policy: CapabilityPackagePolicy,
): void {
  if (!TA_CAPABILITY_TIERS.includes(policy.defaultBaseline.grantedTier)) {
    throw new Error(
      `Unsupported policy baseline tier: ${policy.defaultBaseline.grantedTier}.`,
    );
  }

  if (!isTaPoolMode(policy.defaultBaseline.mode)) {
    throw new Error(
      `Unsupported policy baseline mode: ${policy.defaultBaseline.mode}.`,
    );
  }

  if (!isTaPoolMode(policy.recommendedMode)) {
    throw new Error(`Unsupported recommended policy mode: ${policy.recommendedMode}.`);
  }

  if (!TA_POOL_RISK_LEVELS.includes(policy.riskLevel)) {
    throw new Error(`Unsupported policy risk level: ${policy.riskLevel}.`);
  }

  validateScope("policy.defaultBaseline.scope", policy.defaultBaseline.scope);
  validateScope("policy.defaultScope", policy.defaultScope);

  if (policy.reviewRequirements.length === 0) {
    throw new Error("Capability package policy requires at least one reviewRequirement.");
  }

  for (const requirement of policy.reviewRequirements) {
    if (!REVIEW_VOTES.includes(requirement)) {
      throw new Error(`Unsupported review requirement: ${requirement}.`);
    }
  }
}

export function createCapabilityPackageBuilder(
  input: CreateCapabilityPackageBuilderInput | CapabilityPackageBuilder,
): CapabilityPackageBuilder {
  const builder: CapabilityPackageBuilder = {
    builderId: normalizeString(input.builderId, "builder.builderId"),
    buildStrategy: normalizeString(input.buildStrategy, "builder.buildStrategy"),
    requiresNetwork: input.requiresNetwork ?? false,
    requiresInstall: input.requiresInstall ?? false,
    requiresSystemWrite: input.requiresSystemWrite ?? false,
    allowedWorkdirScope: normalizeStringArray(
      input.allowedWorkdirScope ?? ["workspace/**"],
    ),
    activationSpecRef: normalizeString(
      input.activationSpecRef,
      "builder.activationSpecRef",
    ),
    replayCapability: input.replayCapability ?? "re_review_then_dispatch",
    metadata: input.metadata,
  };

  validateCapabilityPackageBuilder(builder);
  return builder;
}

export function validateCapabilityPackageBuilder(
  builder: CapabilityPackageBuilder,
): void {
  normalizeString(builder.builderId, "builder.builderId");
  normalizeString(builder.buildStrategy, "builder.buildStrategy");
  normalizeString(builder.activationSpecRef, "builder.activationSpecRef");

  if (!REPLAY_POLICIES.includes(builder.replayCapability)) {
    throw new Error(`Unsupported builder replayCapability: ${builder.replayCapability}.`);
  }

  if (builder.allowedWorkdirScope.length === 0) {
    throw new Error("Capability package builder requires at least one allowedWorkdirScope.");
  }
}

export function createCapabilityPackageVerification(
  input:
    | CreateCapabilityPackageVerificationInput
    | CapabilityPackageVerification,
): CapabilityPackageVerification {
  const verification: CapabilityPackageVerification = {
    smokeEntry: normalizeString(input.smokeEntry, "verification.smokeEntry"),
    healthEntry: normalizeString(input.healthEntry, "verification.healthEntry"),
    successCriteria: normalizeStringArray(
      input.successCriteria ?? ["smoke passes", "health passes"],
    ),
    failureSignals: normalizeStringArray(
      input.failureSignals ?? ["smoke failed", "health failed"],
    ),
    evidenceOutput: normalizeStringArray(
      input.evidenceOutput ?? ["logs", "health-report"],
    ),
    metadata: input.metadata,
  };

  validateCapabilityPackageVerification(verification);
  return verification;
}

export function validateCapabilityPackageVerification(
  verification: CapabilityPackageVerification,
): void {
  normalizeString(verification.smokeEntry, "verification.smokeEntry");
  normalizeString(verification.healthEntry, "verification.healthEntry");

  if (verification.successCriteria.length === 0) {
    throw new Error(
      "Capability package verification requires at least one successCriterion.",
    );
  }

  if (verification.failureSignals.length === 0) {
    throw new Error(
      "Capability package verification requires at least one failureSignal.",
    );
  }

  if (verification.evidenceOutput.length === 0) {
    throw new Error(
      "Capability package verification requires at least one evidenceOutput entry.",
    );
  }
}

export function createCapabilityPackageUsageExample(
  input: CreateCapabilityPackageUsageExampleInput | CapabilityPackageUsageExample,
): CapabilityPackageUsageExample {
  const example: CapabilityPackageUsageExample = {
    exampleId: normalizeString(input.exampleId, "usage.exampleInvocations.exampleId"),
    capabilityKey: normalizeString(
      input.capabilityKey,
      "usage.exampleInvocations.capabilityKey",
    ),
    operation: normalizeString(
      input.operation,
      "usage.exampleInvocations.operation",
    ),
    input: input.input ?? {},
    notes: input.notes?.trim() || undefined,
    metadata: input.metadata,
  };

  validateCapabilityPackageUsageExample(example);
  return example;
}

export function validateCapabilityPackageUsageExample(
  example: CapabilityPackageUsageExample,
): void {
  normalizeString(example.exampleId, "usage.exampleInvocations.exampleId");
  normalizeString(example.capabilityKey, "usage.exampleInvocations.capabilityKey");
  normalizeString(example.operation, "usage.exampleInvocations.operation");
}

export function createCapabilityPackageUsage(
  input: CreateCapabilityPackageUsageInput | CapabilityPackageUsage,
): CapabilityPackageUsage {
  const usage: CapabilityPackageUsage = {
    usageDocRef: normalizeString(input.usageDocRef, "usage.usageDocRef"),
    skillRef: input.skillRef?.trim() || undefined,
    bestPractices: normalizeStringArray(input.bestPractices),
    knownLimits: normalizeStringArray(input.knownLimits),
    exampleInvocations: (input.exampleInvocations ?? []).map((example) =>
      createCapabilityPackageUsageExample(example),
    ),
    metadata: input.metadata,
  };

  validateCapabilityPackageUsage(usage);
  return usage;
}

export function validateCapabilityPackageUsage(usage: CapabilityPackageUsage): void {
  normalizeString(usage.usageDocRef, "usage.usageDocRef");

  if (usage.exampleInvocations.length === 0) {
    throw new Error(
      "Capability package usage requires at least one exampleInvocation.",
    );
  }
}

export function createCapabilityPackageLifecycle(
  input: CreateCapabilityPackageLifecycleInput | CapabilityPackageLifecycle,
): CapabilityPackageLifecycle {
  const lifecycle: CapabilityPackageLifecycle = {
    installStrategy: normalizeString(
      input.installStrategy,
      "lifecycle.installStrategy",
    ),
    replaceStrategy: normalizeString(
      input.replaceStrategy,
      "lifecycle.replaceStrategy",
    ),
    rollbackStrategy: normalizeString(
      input.rollbackStrategy,
      "lifecycle.rollbackStrategy",
    ),
    deprecateStrategy: normalizeString(
      input.deprecateStrategy,
      "lifecycle.deprecateStrategy",
    ),
    cleanupStrategy: normalizeString(
      input.cleanupStrategy,
      "lifecycle.cleanupStrategy",
    ),
    generationPolicy: input.generationPolicy ?? "create_next_generation",
    metadata: input.metadata,
  };

  validateCapabilityPackageLifecycle(lifecycle);
  return lifecycle;
}

export function validateCapabilityPackageLifecycle(
  lifecycle: CapabilityPackageLifecycle,
): void {
  normalizeString(lifecycle.installStrategy, "lifecycle.installStrategy");
  normalizeString(lifecycle.replaceStrategy, "lifecycle.replaceStrategy");
  normalizeString(lifecycle.rollbackStrategy, "lifecycle.rollbackStrategy");
  normalizeString(lifecycle.deprecateStrategy, "lifecycle.deprecateStrategy");
  normalizeString(lifecycle.cleanupStrategy, "lifecycle.cleanupStrategy");

  if (!POOL_GENERATION_STRATEGIES.includes(lifecycle.generationPolicy)) {
    throw new Error(
      `Unsupported lifecycle generationPolicy: ${lifecycle.generationPolicy}.`,
    );
  }
}

export function createCapabilityPackageArtifactsFromProvisionBundle(
  bundle: Pick<
    ProvisionArtifactBundle,
    "toolArtifact" | "bindingArtifact" | "verificationArtifact" | "usageArtifact"
  >,
): CapabilityPackageArtifacts {
  if (
    !bundle.toolArtifact ||
    !bundle.bindingArtifact ||
    !bundle.verificationArtifact ||
    !bundle.usageArtifact
  ) {
    throw new Error(
      "Provision bundle requires tool, binding, verification, and usage artifacts.",
    );
  }

  const artifacts: CapabilityPackageArtifacts = {
    toolArtifact: bundle.toolArtifact,
    bindingArtifact: bundle.bindingArtifact,
    verificationArtifact: bundle.verificationArtifact,
    usageArtifact: bundle.usageArtifact,
  };

  validateCapabilityPackageArtifacts(artifacts);
  return artifacts;
}

export function validateCapabilityPackageArtifacts(
  artifacts: CapabilityPackageArtifacts,
): void {
  validateArtifactRef("artifacts.toolArtifact", artifacts.toolArtifact);
  validateArtifactRef("artifacts.bindingArtifact", artifacts.bindingArtifact);
  validateArtifactRef(
    "artifacts.verificationArtifact",
    artifacts.verificationArtifact,
  );
  validateArtifactRef("artifacts.usageArtifact", artifacts.usageArtifact);
}

export function validateMcpCapabilityPackage(
  capabilityPackage: CapabilityPackage,
): void {
  const capabilityKey = capabilityPackage.manifest.capabilityKey;
  if (capabilityKey === MCP_CONFIGURE_CAPABILITY_KEY) {
    throw new Error(
      "mcp.configure must remain outside first-class TAP capability packages.",
    );
  }

  if (!isSupportedMcpCapabilityPackageKey(capabilityKey)) {
    return;
  }

  if (capabilityPackage.adapter.runtimeKind !== "rax-mcp") {
    throw new Error(
      `${capabilityKey} capability packages must use runtimeKind rax-mcp.`,
    );
  }

  if (!capabilityPackage.adapter.supports.includes(capabilityKey)) {
    throw new Error(
      `${capabilityKey} capability packages must explicitly list themselves in adapter.supports.`,
    );
  }

  if (
    !capabilityPackage.policy.defaultScope?.denyPatterns?.includes(
      MCP_CONFIGURE_CAPABILITY_KEY,
    )
  ) {
    throw new Error(
      `${capabilityKey} capability packages must deny ${MCP_CONFIGURE_CAPABILITY_KEY} in policy.defaultScope.`,
    );
  }

  if (
    !capabilityPackage.policy.defaultBaseline.scope?.denyPatterns?.includes(
      MCP_CONFIGURE_CAPABILITY_KEY,
    )
  ) {
    throw new Error(
      `${capabilityKey} capability packages must deny ${MCP_CONFIGURE_CAPABILITY_KEY} in policy.defaultBaseline.scope.`,
    );
  }

  if (!capabilityPackage.policy.safetyFlags.includes("no_mcp_configure")) {
    throw new Error(
      `${capabilityKey} capability packages must carry the no_mcp_configure safety flag.`,
    );
  }

  if (capabilityPackage.policy.riskLevel === "normal") {
    throw new Error(
      `${capabilityKey} capability packages cannot advertise normal risk.`,
    );
  }

  if (capabilityKey === "mcp.call") {
    if (
      !capabilityPackage.policy.safetyFlags.includes(
        "truthful_shared_runtime_surface",
      )
    ) {
      throw new Error(
        "mcp.call capability packages must carry the truthful_shared_runtime_surface safety flag.",
      );
    }
    if (
      capabilityPackage.builder.requiresInstall
      || capabilityPackage.builder.requiresSystemWrite
    ) {
      throw new Error(
        "mcp.call capability packages must not require install or system writes.",
      );
    }
    return;
  }

  if (capabilityKey === "mcp.native.execute") {
    if (capabilityPackage.policy.recommendedMode !== "restricted") {
      throw new Error(
        "mcp.native.execute capability packages must recommend restricted mode.",
      );
    }
    if (
      !capabilityPackage.policy.safetyFlags.includes(
        "native_transport_side_effects",
      )
    ) {
      throw new Error(
        "mcp.native.execute capability packages must flag native_transport_side_effects.",
      );
    }
    if (capabilityPackage.policy.humanGateRequirements.length === 0) {
      throw new Error(
        "mcp.native.execute capability packages require at least one humanGateRequirement.",
      );
    }
  }
}

export function validateCapabilityPackage(capabilityPackage: CapabilityPackage): void {
  normalizeString(
    capabilityPackage.templateVersion,
    "capabilityPackage.templateVersion",
  );
  validateCapabilityPackageManifest(capabilityPackage.manifest);
  validateCapabilityPackageAdapter(capabilityPackage.adapter);
  validateCapabilityPackagePolicy(capabilityPackage.policy);
  validateCapabilityPackageBuilder(capabilityPackage.builder);
  validateCapabilityPackageVerification(capabilityPackage.verification);
  validateCapabilityPackageUsage(capabilityPackage.usage);
  validateCapabilityPackageLifecycle(capabilityPackage.lifecycle);

  if (!REPLAY_POLICIES.includes(capabilityPackage.replayPolicy)) {
    throw new Error(
      `Unsupported capability package replayPolicy: ${capabilityPackage.replayPolicy}.`,
    );
  }

  if (
    capabilityPackage.builder.replayCapability !== capabilityPackage.replayPolicy
  ) {
    throw new Error(
      "Capability package replayPolicy must match builder.replayCapability.",
    );
  }

  if (capabilityPackage.activationSpec) {
    validatePoolActivationSpec(capabilityPackage.activationSpec);
    normalizeString(
      capabilityPackage.builder.activationSpecRef,
      "builder.activationSpecRef",
    );
  }

  if (capabilityPackage.artifacts) {
    validateCapabilityPackageArtifacts(capabilityPackage.artifacts);
  }

  validateMcpCapabilityPackage(capabilityPackage);
}

export function createCapabilityPackage(
  input: CreateCapabilityPackageInput,
): CapabilityPackage {
  const capabilityPackage: CapabilityPackage = {
    templateVersion:
      input.templateVersion ?? CAPABILITY_PACKAGE_TEMPLATE_VERSION,
    manifest: createCapabilityPackageManifest(input.manifest),
    adapter: createCapabilityPackageAdapter(input.adapter),
    policy: createCapabilityPackagePolicy(input.policy),
    builder: createCapabilityPackageBuilder(input.builder),
    verification: createCapabilityPackageVerification(input.verification),
    usage: createCapabilityPackageUsage(input.usage),
    lifecycle: createCapabilityPackageLifecycle(input.lifecycle),
    activationSpec: input.activationSpec,
    replayPolicy:
      input.replayPolicy ??
      ("replayCapability" in input.builder
        ? (input.builder.replayCapability ?? "re_review_then_dispatch")
        : "re_review_then_dispatch"),
    artifacts: input.artifacts,
    metadata: input.metadata,
  };

  validateCapabilityPackage(capabilityPackage);
  return capabilityPackage;
}

export function createCapabilityPackageFromProvisionBundle(
  input: CreateCapabilityPackageFromProvisionBundleInput,
): CapabilityPackage {
  validateProvisionArtifactBundle(input.bundle);

  return createCapabilityPackage({
    manifest: input.manifest,
    adapter: input.adapter,
    policy: input.policy,
    builder: input.builder,
    verification: input.verification,
    usage: input.usage,
    lifecycle: input.lifecycle,
    activationSpec: input.bundle.activationSpec,
    replayPolicy:
      input.bundle.replayPolicy ??
      ("replayCapability" in input.builder
        ? (input.builder.replayCapability ?? "re_review_then_dispatch")
        : "re_review_then_dispatch"),
    artifacts: createCapabilityPackageArtifactsFromProvisionBundle(input.bundle),
    metadata: input.metadata,
  });
}

export function createCapabilityPackageFixture(
  input: CreateCapabilityPackageFixtureInput = {},
): CapabilityPackage {
  const capabilityKey = input.capabilityKey ?? "tap.playwright";
  const activationSpec =
    input.activationSpec ??
    {
      targetPool: "ta-capability-pool",
      activationMode: "activate_after_verify",
      registerOrReplace: "register_or_replace",
      generationStrategy: "create_next_generation",
      drainStrategy: "graceful",
      manifestPayload: {
        capabilityKey,
        version: "1.0.0",
      },
      bindingPayload: {
        adapterId: "adapter.playwright",
        runtimeKind: input.runtimeKind ?? "mcp",
      },
      adapterFactoryRef: "factory:playwright",
    };

  const replayPolicy = input.replayPolicy ?? "re_review_then_dispatch";

  return createCapabilityPackage({
    manifest: {
      capabilityKey,
      capabilityKind: "tool",
      tier: input.tier ?? "B2",
      version: "1.0.0",
      generation: 1,
      description: "Reusable TAP capability package fixture.",
      dependencies: ["mcp.playwright"],
      tags: ["tap", "fixture", "browser"],
      routeHints: [{ key: "provider", value: "playwright" }],
      supportedPlatforms: ["linux", "macos", "windows"],
    },
    adapter: {
      adapterId: "adapter.playwright",
      runtimeKind: input.runtimeKind ?? "mcp",
      supports: ["open_browser", "take_screenshot"],
      prepare: { ref: "adapter.prepare:playwright" },
      execute: { ref: "adapter.execute:playwright" },
      cancel: { ref: "adapter.cancel:playwright" },
      resultMapping: {
        successStatuses: ["success", "partial"],
        artifactKinds: ["tool", "verification", "usage"],
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: input.tier ?? "B2",
        mode: "balanced",
        scope: {
          pathPatterns: ["workspace/**"],
          allowedOperations: ["exec", "read"],
        },
      },
      recommendedMode: "standard",
      riskLevel: "risky",
      defaultScope: {
        pathPatterns: ["workspace/**"],
        allowedOperations: ["exec", "read"],
        denyPatterns: ["sudo *"],
      },
      reviewRequirements: ["allow_with_constraints"],
      safetyFlags: ["network_access", "browser_side_effects"],
      humanGateRequirements: ["first_install_requires_human_ack"],
    },
    builder: {
      builderId: "builder.playwright",
      buildStrategy: "install-and-register",
      requiresNetwork: true,
      requiresInstall: true,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
    },
    verification: {
      smokeEntry: "smoke:mcp:playwright",
      healthEntry: "health:mcp:playwright",
      successCriteria: ["browser opens", "screenshot artifact emitted"],
      failureSignals: ["browser install failed", "session handshake timed out"],
      evidenceOutput: ["console-log", "smoke-report"],
    },
    usage: {
      usageDocRef: "docs/ability/25-tap-capability-package-template.md",
      skillRef: "playwright",
      bestPractices: [
        "Prefer deterministic selectors.",
        "Capture screenshots for user-visible evidence.",
      ],
      knownLimits: ["Requires a browser runtime.", "Cannot bypass manual login."],
      exampleInvocations: [
        {
          exampleId: "example.open-browser",
          capabilityKey,
          operation: "open_browser",
          input: {
            url: "https://example.com",
          },
          notes: "Minimal browser launch example.",
        },
      ],
    },
    lifecycle: {
      installStrategy: "user-space install under managed tooling paths",
      replaceStrategy: "stage new generation before switching binding",
      rollbackStrategy: "restore previous binding artifact",
      deprecateStrategy: "mark deprecated before removal",
      cleanupStrategy: "remove superseded tool artifacts after drain",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy,
    artifacts: {
      toolArtifact: {
        artifactId: "tool.playwright",
        kind: "tool",
        ref: "tool:playwright",
      },
      bindingArtifact: {
        artifactId: "binding.playwright",
        kind: "binding",
        ref: "binding:playwright",
      },
      verificationArtifact: {
        artifactId: "verification.playwright",
        kind: "verification",
        ref: "verification:playwright",
      },
      usageArtifact: {
        artifactId: "usage.playwright",
        kind: "usage",
        ref: "usage:playwright",
      },
    },
  });
}
