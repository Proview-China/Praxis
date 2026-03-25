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
  type SupportedSkillCapabilityPackageKey,
  isSupportedSkillCapabilityPackageKey,
} from "./capability-package.js";

export const SKILL_FAMILY_CAPABILITY_KEYS = [
  "skill.use",
  "skill.mount",
  "skill.prepare",
] as const satisfies readonly SupportedSkillCapabilityPackageKey[];

export type SkillFamilyCapabilityKey =
  (typeof SKILL_FAMILY_CAPABILITY_KEYS)[number];

export interface CreateRaxSkillCapabilityPackageInput {
  capabilityKey: SkillFamilyCapabilityKey;
  tier?: TaCapabilityTier;
  version?: string;
  generation?: number;
  replayPolicy?: ReplayPolicy;
  activationSpec?: PoolActivationSpec;
}

interface SkillFamilyCapabilityDefaults {
  description: string;
  tags: string[];
  verification: {
    smokeEntry: string;
    healthEntry: string;
    successCriteria: string[];
    failureSignals: string[];
    evidenceOutput: string[];
  };
  usage: {
    bestPractices: string[];
    knownLimits: string[];
    exampleInput: Record<string, unknown>;
    exampleNotes: string;
  };
  reviewRequirements: ("allow" | "allow_with_constraints")[];
  safetyFlags: string[];
}

function createExampleSkillContainer() {
  return {
    descriptor: {
      id: "browser_skill",
      name: "Browser Skill",
      version: "v1",
      tags: ["browser"],
      triggers: ["open page"],
      source: {
        kind: "local",
        rootDir: "/skills/browser",
        entryPath: "/skills/browser/SKILL.md",
      },
    },
    source: {
      kind: "local",
      rootDir: "/skills/browser",
      entryPath: "/skills/browser/SKILL.md",
    },
    entry: {
      path: "/skills/browser/SKILL.md",
    },
    bindings: {},
  };
}

const SKILL_PROVIDER_HINTS = ["openai", "anthropic", "deepmind"];
const SKILL_USAGE_DOC_REF = "docs/ability/14-skill-execution-roadmap.md";

function createSkillCapabilitySupportMatrix() {
  return createCapabilityPackageSupportMatrix({
    routes: [
      {
        provider: "openai",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "documented",
        notes: [
          "OpenAI skill carrier support is exposed through responses plus shell/environment attachment, while this package keeps the contract at the package-runtime layer.",
        ],
      },
      {
        provider: "openai",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "documented",
        preferred: true,
        notes: [
          "OpenAI agent/runtime skill mounting is the preferred TAP route for package-backed skill actions.",
        ],
      },
      {
        provider: "anthropic",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "documented",
      },
      {
        provider: "anthropic",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "documented",
        preferred: true,
        notes: [
          "Anthropic agent/runtime skill usage is the preferred TAP route for package-backed skill actions.",
        ],
      },
      {
        provider: "deepmind",
        sdkLayer: "api",
        lowering: "package-runtime",
        status: "inferred",
        notes: [
          "Direct Google API skill carrier coverage is weaker than ADK runtime skill tooling, so this route remains inferred for now.",
        ],
      },
      {
        provider: "deepmind",
        sdkLayer: "agent",
        lowering: "package-runtime",
        status: "documented",
        preferred: true,
        notes: [
          "Google ADK skill/runtime is the preferred TAP route for package-backed skill actions.",
        ],
      },
    ],
    metadata: {
      capabilityFamily: "skill",
      executionSurface: "package-runtime",
    },
  });
}

const SKILL_FAMILY_DEFAULTS: Record<
  SkillFamilyCapabilityKey,
  SkillFamilyCapabilityDefaults
> = {
  "skill.use": {
    description:
      "Resolve a skill source, container, or reference into a prepared carrier-backed invocation through the RAX skill runtime.",
    tags: ["skill", "skill-family", "carrier", "use"],
    verification: {
      smokeEntry: "smoke:skill:use",
      healthEntry: "health:rax:skill:use",
      successCriteria: [
        "skill source, container, or reference resolves into a prepared invocation",
        "activation summary stays attached to the result envelope",
      ],
      failureSignals: [
        "provider or model is missing",
        "skill source, container, and reference are all missing",
      ],
      evidenceOutput: [
        "prepared-invocation",
        "activation-summary",
        "container-summary",
      ],
    },
    usage: {
      bestPractices: [
        "Prefer an explicit source, container, or hosted reference instead of relying on hidden defaults.",
        "Keep includeResources/includeHelpers off unless the caller truly needs larger bundle context.",
      ],
      knownLimits: [
        "This family only formalizes skill.use, skill.mount, and skill.prepare.",
        "Managed skill registry lifecycle stays outside this first formal TAP package.",
      ],
      exampleInput: {
        route: {
          provider: "openai",
          model: "gpt-5.4",
          layer: "agent",
        },
        source: "/skills/browser",
        includeResources: false,
        includeHelpers: false,
      },
      exampleNotes:
        "Resolve a local skill package into a prepared invocation without executing the downstream user task.",
    },
    reviewRequirements: ["allow_with_constraints"],
    safetyFlags: [
      "progressive_loading_supported",
      "provider_skill_carrier",
      "source_or_reference_resolution",
    ],
  },
  "skill.mount": {
    description:
      "Mount an already loaded skill container onto a provider-specific carrier through the RAX skill runtime.",
    tags: ["skill", "skill-family", "carrier", "mount"],
    verification: {
      smokeEntry: "smoke:skill:mount",
      healthEntry: "health:rax:skill:mount",
      successCriteria: [
        "mounted result returns activation plus prepared invocation summaries",
        "container metadata remains attached to the result envelope",
      ],
      failureSignals: [
        "provider or model is missing",
        "container input is missing",
      ],
      evidenceOutput: [
        "prepared-invocation",
        "activation-summary",
        "container-summary",
      ],
    },
    usage: {
      bestPractices: [
        "Pass a preloaded container when the skill bundle has already been resolved earlier in the flow.",
        "Use includeResources/includeHelpers sparingly to avoid bloating the prepared carrier payload.",
      ],
      knownLimits: [
        "Requires a valid skill container input.",
        "Does not cover managed registry lifecycle calls such as list/publish/remove.",
      ],
      exampleInput: {
        route: {
          provider: "anthropic",
          model: "claude-opus-4-6-thinking",
          layer: "agent",
        },
        container: createExampleSkillContainer(),
        includeResources: true,
        includeHelpers: false,
      },
      exampleNotes:
        "Mount a previously loaded skill container onto a provider carrier while preserving progressive-loading control.",
    },
    reviewRequirements: ["allow"],
    safetyFlags: [
      "progressive_loading_supported",
      "provider_skill_carrier",
      "container_required",
    ],
  },
  "skill.prepare": {
    description:
      "Prepare a provider-scoped invocation from a loaded skill container without mounting or resolving a fresh source.",
    tags: ["skill", "skill-family", "carrier", "prepare"],
    verification: {
      smokeEntry: "smoke:skill:prepare",
      healthEntry: "health:rax:skill:prepare",
      successCriteria: [
        "prepared invocation summary is returned",
        "container summary stays attached to the result envelope",
      ],
      failureSignals: [
        "provider or model is missing",
        "container input is missing",
      ],
      evidenceOutput: ["prepared-invocation", "container-summary"],
    },
    usage: {
      bestPractices: [
        "Use this when the caller only needs the prepared invocation payload and not the mounted activation summary.",
        "Keep preparation separate from execution so reviewer and provisioner traces stay truthful.",
      ],
      knownLimits: [
        "Requires a valid skill container input.",
        "This action stops at prepared invocation output and does not execute the final model call.",
      ],
      exampleInput: {
        route: {
          provider: "deepmind",
          model: "gemini-3.1-pro-preview",
          layer: "agent",
        },
        container: createExampleSkillContainer(),
        includeResources: false,
        includeHelpers: true,
      },
      exampleNotes:
        "Build a prepared skill invocation for a loaded container without widening the family to managed registry operations.",
    },
    reviewRequirements: ["allow"],
    safetyFlags: [
      "progressive_loading_supported",
      "prepared_invocation_only",
      "container_required",
    ],
  },
};

export function isSkillFamilyCapabilityKey(
  capabilityKey: string,
): capabilityKey is SkillFamilyCapabilityKey {
  return SKILL_FAMILY_CAPABILITY_KEYS.includes(
    capabilityKey as SkillFamilyCapabilityKey,
  );
}

export function createRaxSkillCapabilityPackage(
  input: CreateRaxSkillCapabilityPackageInput,
): CapabilityPackage {
  if (
    !isSkillFamilyCapabilityKey(input.capabilityKey)
    || !isSupportedSkillCapabilityPackageKey(input.capabilityKey)
  ) {
    throw new Error(
      `Unsupported skill family capability package key: ${input.capabilityKey}.`,
    );
  }

  const defaults = SKILL_FAMILY_DEFAULTS[input.capabilityKey];
  const version = input.version ?? "1.0.0";
  const generation = input.generation ?? 1;
  const replayPolicy = input.replayPolicy ?? "auto_after_verify";
  const action = input.capabilityKey.replace("skill.", "");
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
        routeHints: [
          { key: "capability_family", value: "skill" },
          { key: "skill_action", value: action },
          { key: "runtime", value: "rax-skill" },
        ],
        tags: defaults.tags,
        metadata: {
          capabilityFamily: "skill",
          skillAction: action,
        },
      },
      bindingPayload: {
        adapterId: "rax.skill.adapter",
        runtimeKind: "rax-skill",
        capabilityKey: input.capabilityKey,
      },
      adapterFactoryRef: `factory:rax.skill:${action}`,
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
      },
    });

  return createCapabilityPackage({
    manifest: {
      capabilityKey: input.capabilityKey,
      capabilityKind: "tool",
      tier: input.tier ?? "B1",
      version,
      generation,
      description: defaults.description,
      dependencies: ["rax.skill"],
      tags: defaults.tags,
      routeHints: [
        { key: "capability_family", value: "skill" },
        { key: "skill_action", value: action },
        { key: "runtime", value: "rax-skill" },
      ],
      supportedPlatforms: ["linux", "macos", "windows"],
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
        progressiveLoading: true,
      },
    },
    supportMatrix: createSkillCapabilitySupportMatrix(),
    adapter: {
      adapterId: "rax.skill.adapter",
      runtimeKind: "rax-skill",
      supports: [input.capabilityKey],
      prepare: {
        ref: "integrations/rax-skill-adapter#prepare",
        description:
          "Normalize provider route plus skill action input into a prepared RAX skill call.",
      },
      execute: {
        ref: "integrations/rax-skill-adapter#execute",
        description:
          "Execute the prepared skill action through the shared RAX skill adapter surface.",
      },
      resultMapping: {
        successStatuses: ["success"],
        artifactKinds: ["tool", "usage"],
        metadata: {
          capabilityFamily: "skill",
          skillAction: action,
        },
      },
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
        progressiveLoading: true,
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: input.tier ?? "B1",
        mode: "balanced",
        scope: {
          allowedOperations: ["read", input.capabilityKey],
          providerHints: SKILL_PROVIDER_HINTS,
          metadata: {
            capabilityFamily: "skill",
            progressiveLoading: true,
          },
        },
      },
      recommendedMode: "standard",
      riskLevel: "normal",
      defaultScope: {
        allowedOperations: ["read", input.capabilityKey],
        providerHints: SKILL_PROVIDER_HINTS,
      },
      reviewRequirements: defaults.reviewRequirements,
      safetyFlags: defaults.safetyFlags,
      humanGateRequirements: [],
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
        progressiveLoading: true,
      },
    },
    builder: {
      builderId: `builder:${input.capabilityKey}`,
      buildStrategy: "register-shared-skill-runtime",
      requiresNetwork: false,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: replayPolicy,
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
      },
    },
    verification: {
      smokeEntry: defaults.verification.smokeEntry,
      healthEntry: defaults.verification.healthEntry,
      successCriteria: defaults.verification.successCriteria,
      failureSignals: defaults.verification.failureSignals,
      evidenceOutput: defaults.verification.evidenceOutput,
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
      },
    },
    usage: {
      usageDocRef: SKILL_USAGE_DOC_REF,
      bestPractices: defaults.usage.bestPractices,
      knownLimits: defaults.usage.knownLimits,
      exampleInvocations: [
        {
          exampleId: `example.${input.capabilityKey}`,
          capabilityKey: input.capabilityKey,
          operation: input.capabilityKey,
          input: defaults.usage.exampleInput,
          notes: defaults.usage.exampleNotes,
        },
      ],
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
      },
    },
    lifecycle: {
      installStrategy:
        "reuse the existing rax.skill runtime and shared adapter without extra install steps",
      replaceStrategy: "register_or_replace active skill binding generation",
      rollbackStrategy: "restore the previous shared skill binding generation",
      deprecateStrategy:
        "freeze new skill registrations before draining superseded generations",
      cleanupStrategy:
        "remove superseded shared skill binding artifacts after drain completes",
      generationPolicy: "create_next_generation",
      metadata: {
        capabilityFamily: "skill",
        skillAction: action,
      },
    },
    activationSpec,
    replayPolicy,
    metadata: {
      capabilityFamily: "skill",
      skillAction: action,
    },
  });
}

export function createRaxSkillCapabilityPackageCatalog(): CapabilityPackage[] {
  return SKILL_FAMILY_CAPABILITY_KEYS.map((capabilityKey) =>
    createRaxSkillCapabilityPackage({ capabilityKey }),
  );
}
