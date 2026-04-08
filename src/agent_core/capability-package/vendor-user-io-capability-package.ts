import type {
  ReplayPolicy,
  PoolActivationSpec,
  TaCapabilityTier,
} from "../ta-pool-types/index.js";
import { createPoolActivationSpec } from "../ta-pool-types/index.js";
import {
  createCapabilityPackage,
  createCapabilityPackageActivationSpecRef,
  createCapabilityPackageSupportMatrix,
  type CapabilityPackage,
} from "./capability-package.js";

export const TAP_VENDOR_USER_IO_CAPABILITY_KEYS = [
  "request_user_input",
  "request_permissions",
] as const;

export type TapVendorUserIoCapabilityKey =
  (typeof TAP_VENDOR_USER_IO_CAPABILITY_KEYS)[number];

export const TAP_VENDOR_USER_IO_ACTIVATION_FACTORY_REFS: Readonly<
  Record<TapVendorUserIoCapabilityKey, string>
> = {
  request_user_input: "factory:tap.vendor-user-io:request_user_input",
  request_permissions: "factory:tap.vendor-user-io:request_permissions",
};

export interface CreateTapVendorUserIoCapabilityPackageInput {
  capabilityKey: TapVendorUserIoCapabilityKey;
  tier?: TaCapabilityTier;
  version?: string;
  generation?: number;
  replayPolicy?: ReplayPolicy;
  activationSpec?: PoolActivationSpec;
}

interface UserIoCapabilityDefaults {
  description: string;
  tags: string[];
  tier: TaCapabilityTier;
  routeHints: Array<{ key: string; value: string }>;
  successCriteria: string[];
  failureSignals: string[];
  evidenceOutput: string[];
  bestPractices: string[];
  knownLimits: string[];
  exampleInput: Record<string, unknown>;
  exampleNotes: string;
  reviewRequirements: ("allow" | "allow_with_constraints")[];
  safetyFlags: string[];
  riskLevel: "normal" | "risky" | "dangerous";
}

const USER_IO_USAGE_DOC_REF =
  "docs/ability/66-tap-native-capability-family-and-backend-selection.md";

const USER_IO_CAPABILITY_DEFAULTS: Record<
  TapVendorUserIoCapabilityKey,
  UserIoCapabilityDefaults
> = {
  request_user_input: {
    description:
      "Raise a structured question set back to the human operator when the current task cannot continue safely without new user input.",
    tags: ["tap", "user-io", "human-input", "governance"],
    tier: "B0",
    routeHints: [
      { key: "family", value: "tap-vendor-user-io" },
      { key: "backendKind", value: "portable" },
      { key: "selectionPolicy", value: "operator-surface" },
    ],
    successCriteria: [
      "Structured question payload is preserved for the operator surface.",
      "Capability result clearly marks that execution is waiting on new user input.",
    ],
    failureSignals: [
      "questions input is missing or empty",
      "user input handler is not configured",
    ],
    evidenceOutput: ["user-question-payload", "waiting-human-metadata"],
    bestPractices: [
      "Ask only when the task truly cannot proceed safely under current assumptions.",
      "Keep the number of questions small and the options mutually exclusive where possible.",
    ],
    knownLimits: [
      "This capability surfaces a request to the operator; it does not itself collect the answer yet.",
      "A later runtime bridge should turn the blocked envelope into a resumable waiting-human lane.",
    ],
    exampleInput: {
      questions: [
        {
          id: "deploy_scope",
          header: "部署",
          question: "这次只部署 API 还是连前端一起部署？",
          options: [
            { label: "只 API", description: "保持发布面最小。" },
            { label: "前后端一起", description: "一次完成全部上线。" },
          ],
        },
      ],
    },
    exampleNotes:
      "Structured human clarification request when deployment scope changes the execution plan.",
    reviewRequirements: ["allow"],
    safetyFlags: ["human_input_required"],
    riskLevel: "normal",
  },
  request_permissions: {
    description:
      "Request additional filesystem or network permissions from the operator when the current task needs a broader execution envelope.",
    tags: ["tap", "user-io", "permissions", "governance"],
    tier: "B1",
    routeHints: [
      { key: "family", value: "tap-vendor-user-io" },
      { key: "backendKind", value: "portable" },
      { key: "selectionPolicy", value: "operator-surface" },
    ],
    successCriteria: [
      "Requested permission profile is preserved for the operator surface.",
      "Capability result clearly marks that execution is waiting on permission expansion.",
    ],
    failureSignals: [
      "permissions payload is missing",
      "requested permission profile is empty",
      "permission request handler is not configured",
    ],
    evidenceOutput: ["permission-request-payload", "waiting-human-metadata"],
    bestPractices: [
      "Ask for the smallest permission expansion that unblocks the task.",
      "Attach a clear reason so the operator understands why the extra scope is needed.",
    ],
    knownLimits: [
      "This capability raises a permission request; it does not itself grant permissions.",
      "A later runtime bridge should merge granted permissions back into the execution context.",
    ],
    exampleInput: {
      permissions: {
        network: { enabled: true },
        file_system: {
          read: ["/tmp/example"],
        },
      },
      reason: "Need temporary network access to fetch the release manifest.",
    },
    exampleNotes:
      "Permission expansion request for a task that must read outside the current workspace or use the network.",
    reviewRequirements: ["allow_with_constraints"],
    safetyFlags: ["permission_escalation_request"],
    riskLevel: "risky",
  },
};

function createUserIoSupportMatrix(
  capabilityKey: TapVendorUserIoCapabilityKey,
) {
  return createCapabilityPackageSupportMatrix({
    routes: [
      {
        provider: "openai",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "inferred",
        preferred: true,
        notes: [
          "Operator-facing user-io requests are handled by the Praxis TAP runtime rather than a provider-native API primitive.",
        ],
      },
      {
        provider: "anthropic",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "inferred",
        notes: [
          "Anthropic-facing routes can surface the same user-io contract through the Praxis TAP runtime.",
        ],
      },
      {
        provider: "deepmind",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "inferred",
        notes: [
          "DeepMind-facing routes can surface the same user-io contract through the Praxis TAP runtime.",
        ],
      },
    ],
    metadata: {
      capabilityFamily: "tap-vendor-user-io",
      capabilityKey,
    },
  });
}

export function createTapVendorUserIoCapabilityPackage(
  input: CreateTapVendorUserIoCapabilityPackageInput,
): CapabilityPackage {
  const defaults = USER_IO_CAPABILITY_DEFAULTS[input.capabilityKey];
  const version = input.version ?? "1.0.0";
  const generation = input.generation ?? 1;
  const replayPolicy = input.replayPolicy ?? "re_review_then_dispatch";
  const adapterFactoryRef =
    TAP_VENDOR_USER_IO_ACTIVATION_FACTORY_REFS[input.capabilityKey];
  const adapterId = `adapter:${input.capabilityKey}`;
  const runtimeKind = "tap-vendor-user-io";

  const activationSpec =
    input.activationSpec ??
    createPoolActivationSpec({
      targetPool: "ta-capability-pool",
      activationMode: "activate_after_verify",
      registerOrReplace: "register_or_replace",
      generationStrategy: "create_next_generation",
      drainStrategy: "graceful",
      manifestPayload: {
        capabilityKey: input.capabilityKey,
        capabilityId: `capability:${input.capabilityKey}:${generation}`,
        version,
        generation,
        kind: "tool",
        description: defaults.description,
        supportsPrepare: true,
        supportsCancellation: false,
        routeHints: [
          { key: "runtime", value: runtimeKind },
          { key: "capability", value: input.capabilityKey },
        ],
        tags: defaults.tags,
      },
      bindingPayload: {
        adapterId,
        runtimeKind,
      },
      adapterFactoryRef,
      metadata: {
        packageKind: "tap-vendor-user-io-family",
      },
    });

  return createCapabilityPackage({
    manifest: {
      capabilityKey: input.capabilityKey,
      capabilityKind: "tool",
      tier: input.tier ?? defaults.tier,
      version,
      generation,
      description: defaults.description,
      dependencies: [],
      tags: defaults.tags,
      routeHints: defaults.routeHints,
      supportedPlatforms: ["linux", "macos", "windows"],
      metadata: {
        family: "tap-vendor-user-io",
        backendKind: "portable",
      },
    },
    supportMatrix: createUserIoSupportMatrix(input.capabilityKey),
    adapter: {
      adapterId,
      runtimeKind,
      supports: [input.capabilityKey],
      prepare: {
        ref: "integrations/tap-vendor-user-io-adapter#prepare",
        description: "Normalize a TAP operator-facing user-io request into a prepared execution state.",
      },
      execute: {
        ref: "integrations/tap-vendor-user-io-adapter#execute",
        description: "Surface a blocked result that carries a structured operator-facing user-io request payload.",
      },
      resultMapping: {
        successStatuses: ["blocked"],
        artifactKinds: ["usage", "verification"],
      },
      metadata: {
        activationFactoryRef: adapterFactoryRef,
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: input.tier ?? defaults.tier,
        mode: "standard",
        scope: {
          allowedOperations: [input.capabilityKey],
          providerHints: ["operator-surface"],
        },
      },
      recommendedMode: "standard",
      riskLevel: defaults.riskLevel,
      defaultScope: {
        allowedOperations: [input.capabilityKey],
        providerHints: ["operator-surface"],
      },
      reviewRequirements: defaults.reviewRequirements,
      safetyFlags: defaults.safetyFlags,
      humanGateRequirements: [],
    },
    builder: {
      builderId: `builder:${input.capabilityKey}:tap-vendor-user-io`,
      buildStrategy: "mount-existing-runtime",
      requiresNetwork: false,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
    },
    verification: {
      smokeEntry: `smoke:${input.capabilityKey}`,
      healthEntry: `health:tap-vendor-user-io:${input.capabilityKey}`,
      successCriteria: defaults.successCriteria,
      failureSignals: defaults.failureSignals,
      evidenceOutput: defaults.evidenceOutput,
    },
    usage: {
      usageDocRef: USER_IO_USAGE_DOC_REF,
      bestPractices: defaults.bestPractices,
      knownLimits: defaults.knownLimits,
      exampleInvocations: [
        {
          exampleId: `example:${input.capabilityKey}`,
          capabilityKey: input.capabilityKey,
          operation: input.capabilityKey,
          input: defaults.exampleInput,
          notes: defaults.exampleNotes,
        },
      ],
    },
    lifecycle: {
      installStrategy:
        "register the TAP user-io adapter family and let later runtime bridges connect blocked requests to operator surfaces",
      replaceStrategy: "register_or_replace active binding generation",
      rollbackStrategy: "restore the previous user-io binding generation",
      deprecateStrategy: "freeze new user-io dispatches before draining superseded bindings",
      cleanupStrategy: "clear superseded user-io binding artifacts after drain",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy,
    artifacts: {
      toolArtifact: {
        artifactId: `tool:${input.capabilityKey}`,
        kind: "tool",
        ref: `tool:${input.capabilityKey}`,
      },
      bindingArtifact: {
        artifactId: `binding:${input.capabilityKey}`,
        kind: "binding",
        ref: `binding:${input.capabilityKey}`,
      },
      verificationArtifact: {
        artifactId: `verification:${input.capabilityKey}`,
        kind: "verification",
        ref: `verification:${input.capabilityKey}`,
      },
      usageArtifact: {
        artifactId: `usage:${input.capabilityKey}`,
        kind: "usage",
        ref: `usage:${input.capabilityKey}`,
      },
    },
    metadata: {
      bundleId: `bundle:${input.capabilityKey}:tap-vendor-user-io`,
      provisionId: `provision:${input.capabilityKey}:tap-vendor-user-io`,
      packageKind: "tap-vendor-user-io-family",
    },
  });
}

export function createTapVendorUserIoCapabilityPackageCatalog(): CapabilityPackage[] {
  return TAP_VENDOR_USER_IO_CAPABILITY_KEYS.map((capabilityKey) =>
    createTapVendorUserIoCapabilityPackage({ capabilityKey }),
  );
}
