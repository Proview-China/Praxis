import type {
  CapabilityPackage,
  CapabilityPackageProfileAssignment,
  CapabilityPackageTargetLane,
  CreateCapabilityPackageInput,
} from "./capability-package.js";
import { createCapabilityPackage } from "./capability-package.js";
import type { TaCapabilityTier } from "../ta-pool-types/index.js";

type CapabilityRouteHint = {
  key: string;
  value: string;
};

export const FIRST_WAVE_CAPABILITY_KEYS = [
  "code.read",
  "docs.read",
  "repo.write",
  "shell.restricted",
  "test.run",
  "skill.doc.generate",
  "dependency.install",
  "network.download",
] as const;
export type FirstWaveCapabilityKey = (typeof FIRST_WAVE_CAPABILITY_KEYS)[number];

interface FirstWaveCapabilitySpec {
  capabilityKey: FirstWaveCapabilityKey;
  description: string;
  tier: TaCapabilityTier;
  profileAssignment: CapabilityPackageProfileAssignment;
  targetLane: CapabilityPackageTargetLane;
  allowedPattern?: string;
  riskLevel: CreateCapabilityPackageInput["policy"]["riskLevel"];
  runtimeKind: string;
  supportedOperations: string[];
  defaultScopeOperations: string[];
  routeHints?: CapabilityRouteHint[];
  bestPractices: string[];
  knownLimits: string[];
  safetyFlags?: string[];
  humanGateRequirements?: string[];
  requiresNetwork?: boolean;
  requiresInstall?: boolean;
  requiresSystemWrite?: boolean;
}

const COMMON_SUPPORTED_PLATFORMS = ["linux", "macos", "windows"];
const COMMON_PACKAGE_TAGS = ["tap", "first-wave", "registration-assembly"];

const FIRST_WAVE_CAPABILITY_SPECS: Record<FirstWaveCapabilityKey, FirstWaveCapabilitySpec> = {
  "code.read": {
    capabilityKey: "code.read",
    description: "Read repository source files and code structure for reviewer and TMA planning.",
    tier: "B0",
    profileAssignment: "baseline_capability",
    targetLane: "reviewer",
    riskLevel: "normal",
    runtimeKind: "tool",
    supportedOperations: ["read_code"],
    defaultScopeOperations: ["read"],
    routeHints: [{ key: "plane", value: "review" }],
    bestPractices: ["Read before proposing mutations.", "Quote the exact file evidence when escalating risk."],
    knownLimits: ["Read-only capability.", "Does not mutate repository state."],
  },
  "docs.read": {
    capabilityKey: "docs.read",
    description: "Read docs, handoff notes, and memory summaries without mutating runtime state.",
    tier: "B0",
    profileAssignment: "baseline_capability",
    targetLane: "reviewer",
    riskLevel: "normal",
    runtimeKind: "tool",
    supportedOperations: ["read_docs"],
    defaultScopeOperations: ["read"],
    routeHints: [{ key: "plane", value: "review" }],
    bestPractices: ["Prefer the latest repo docs before acting.", "Use docs as evidence, not as authority over current code."],
    knownLimits: ["Read-only capability.", "Cannot change docs by itself."],
  },
  "repo.write": {
    capabilityKey: "repo.write",
    description: "Apply bounded repository edits for bootstrap construction work.",
    tier: "B1",
    profileAssignment: "allowed_pattern",
    allowedPattern: "repo.write",
    targetLane: "bootstrap_tma",
    riskLevel: "normal",
    runtimeKind: "tool",
    supportedOperations: ["apply_patch", "write_repo_files"],
    defaultScopeOperations: ["read", "write"],
    routeHints: [{ key: "plane", value: "provision" }],
    bestPractices: ["Keep edits inside the active workspace.", "Pair each write with an immediate verification readback."],
    knownLimits: ["Repo-local only.", "Does not imply install or system mutation."],
  },
  "shell.restricted": {
    capabilityKey: "shell.restricted",
    description: "Run bounded shell commands inside the workspace for build and verification tasks.",
    tier: "B1",
    profileAssignment: "allowed_pattern",
    allowedPattern: "shell.restricted",
    targetLane: "bootstrap_tma",
    riskLevel: "risky",
    runtimeKind: "tool",
    supportedOperations: ["run_shell"],
    defaultScopeOperations: ["read", "exec"],
    routeHints: [{ key: "plane", value: "provision" }],
    bestPractices: ["Keep commands deterministic and workspace-scoped.", "Prefer read/build/test commands over mutating shell flows."],
    knownLimits: ["No destructive shell by default.", "Escalate before broader system changes."],
    safetyFlags: ["bounded_shell"],
  },
  "test.run": {
    capabilityKey: "test.run",
    description: "Execute targeted tests and build checks as first-wave verification.",
    tier: "B1",
    profileAssignment: "allowed_pattern",
    allowedPattern: "test.run",
    targetLane: "bootstrap_tma",
    riskLevel: "normal",
    runtimeKind: "tool",
    supportedOperations: ["run_tests"],
    defaultScopeOperations: ["read", "exec"],
    routeHints: [{ key: "plane", value: "verification" }],
    bestPractices: ["Run the smallest meaningful test slice first.", "Capture failing evidence instead of guessing."],
    knownLimits: ["Verification only.", "Does not approve deployment or activation."],
  },
  "skill.doc.generate": {
    capabilityKey: "skill.doc.generate",
    description: "Generate or update usage docs and skill-facing artifacts for a staged capability package.",
    tier: "B1",
    profileAssignment: "allowed_pattern",
    allowedPattern: "skill.doc.generate",
    targetLane: "bootstrap_tma",
    riskLevel: "normal",
    runtimeKind: "tool",
    supportedOperations: ["generate_docs"],
    defaultScopeOperations: ["read", "write"],
    routeHints: [{ key: "plane", value: "usage" }],
    bestPractices: ["Keep generated docs aligned with verified runtime behavior.", "Do not invent capabilities that are not wired."],
    knownLimits: ["Artifact-generation only.", "Still requires review before broader rollout."],
  },
  "dependency.install": {
    capabilityKey: "dependency.install",
    description: "Install new dependencies when first-wave capability assembly cannot stay purely repo-local.",
    tier: "B2",
    profileAssignment: "review_only",
    targetLane: "extended_tma",
    riskLevel: "risky",
    runtimeKind: "tool",
    supportedOperations: ["install_dependency"],
    defaultScopeOperations: ["read", "exec", "write"],
    routeHints: [{ key: "plane", value: "extended-provision" }],
    bestPractices: ["Prefer user-space or repo-local installs.", "Record exact install evidence and rollback hints."],
    knownLimits: ["Not baseline-eligible.", "Requires explicit review before execution."],
    safetyFlags: ["network_access", "install_side_effects"],
    humanGateRequirements: ["first_install_requires_review"],
    requiresNetwork: true,
    requiresInstall: true,
  },
  "network.download": {
    capabilityKey: "network.download",
    description: "Fetch remote artifacts or templates needed for extended capability assembly.",
    tier: "B2",
    profileAssignment: "review_only",
    targetLane: "extended_tma",
    riskLevel: "risky",
    runtimeKind: "tool",
    supportedOperations: ["download_artifact"],
    defaultScopeOperations: ["read", "write", "network"],
    routeHints: [{ key: "plane", value: "extended-provision" }],
    bestPractices: ["Prefer pinned URLs and checksum evidence.", "Keep downloads attributable to the blocked capability request."],
    knownLimits: ["External side effects require review.", "Does not imply activation approval."],
    safetyFlags: ["network_access"],
    humanGateRequirements: ["remote_fetch_requires_review"],
    requiresNetwork: true,
  },
};

function toAdapterRefFragment(capabilityKey: string): string {
  return capabilityKey.replace(/\./g, "_");
}

function toDefaultScopePathPatterns(targetLane: CapabilityPackageTargetLane): string[] {
  return targetLane === "reviewer" ? ["workspace/**", "docs/**", "memory/**"] : ["workspace/**"];
}

function toBuildStrategy(targetLane: CapabilityPackageTargetLane): string {
  return targetLane === "reviewer" ? "register-readonly-runtime" : "stage-and-register";
}

function toCapabilityKind(): "tool" {
  return "tool";
}

function createPackageInputFromSpec(spec: FirstWaveCapabilitySpec): CreateCapabilityPackageInput {
  const capabilityRef = toAdapterRefFragment(spec.capabilityKey);
  const activationSpec = {
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify" as const,
    registerOrReplace: "register_or_replace" as const,
    generationStrategy: "create_next_generation" as const,
    drainStrategy: "graceful" as const,
    manifestPayload: {
      capabilityKey: spec.capabilityKey,
      version: "1.0.0",
      description: spec.description,
      kind: toCapabilityKind(),
      generation: 1,
    },
    bindingPayload: {
      adapterId: `adapter.${capabilityRef}`,
      runtimeKind: spec.runtimeKind,
    },
    adapterFactoryRef: `factory:${spec.capabilityKey}`,
  };

  return {
    manifest: {
      capabilityKey: spec.capabilityKey,
      capabilityKind: toCapabilityKind(),
      tier: spec.tier,
      version: "1.0.0",
      generation: 1,
      description: spec.description,
      dependencies: [],
      tags: [...COMMON_PACKAGE_TAGS, spec.targetLane],
      routeHints: spec.routeHints ?? [],
      supportedPlatforms: COMMON_SUPPORTED_PLATFORMS,
    },
    adapter: {
      adapterId: `adapter.${capabilityRef}`,
      runtimeKind: spec.runtimeKind,
      supports: spec.supportedOperations,
      prepare: { ref: `adapter.prepare:${spec.capabilityKey}` },
      execute: { ref: `adapter.execute:${spec.capabilityKey}` },
      resultMapping: {
        successStatuses: ["success"],
        artifactKinds: ["tool", "verification", "usage"],
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: spec.tier,
        mode: spec.profileAssignment === "baseline_capability" ? "standard" : "permissive",
        scope: {
          pathPatterns: toDefaultScopePathPatterns(spec.targetLane),
          allowedOperations: spec.defaultScopeOperations,
        },
      },
      registrationAssembly: {
        profileAssignment: spec.profileAssignment,
        targetLane: spec.targetLane,
        allowedPattern: spec.allowedPattern,
        notes: [`First-wave registration assembly for ${spec.capabilityKey}.`],
      },
      recommendedMode: spec.profileAssignment === "review_only" ? "standard" : "permissive",
      riskLevel: spec.riskLevel,
      defaultScope: {
        pathPatterns: toDefaultScopePathPatterns(spec.targetLane),
        allowedOperations: spec.defaultScopeOperations,
      },
      reviewRequirements: spec.profileAssignment === "baseline_capability"
        ? ["allow"]
        : ["allow_with_constraints"],
      safetyFlags: spec.safetyFlags ?? [],
      humanGateRequirements: spec.humanGateRequirements ?? [],
    },
    builder: {
      builderId: `builder.${capabilityRef}`,
      buildStrategy: toBuildStrategy(spec.targetLane),
      requiresNetwork: spec.requiresNetwork ?? false,
      requiresInstall: spec.requiresInstall ?? false,
      requiresSystemWrite: spec.requiresSystemWrite ?? false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: `activation-spec:${activationSpec.targetPool}:${activationSpec.activationMode}:${activationSpec.adapterFactoryRef}`,
      replayCapability: spec.profileAssignment === "review_only"
        ? "re_review_then_dispatch"
        : "auto_after_verify",
    },
    verification: {
      smokeEntry: `smoke:${spec.capabilityKey}`,
      healthEntry: `health:${spec.capabilityKey}`,
      successCriteria: [`${spec.capabilityKey} verification passes`],
      failureSignals: [`${spec.capabilityKey} verification failed`],
      evidenceOutput: ["logs", "verification-report"],
    },
    usage: {
      usageDocRef: "docs/ability/25-tap-capability-package-template.md",
      bestPractices: spec.bestPractices,
      knownLimits: spec.knownLimits,
      exampleInvocations: [
        {
          exampleId: `example.${capabilityRef}`,
          capabilityKey: spec.capabilityKey,
          operation: spec.supportedOperations[0] ?? "invoke",
          input: {
            target: spec.capabilityKey,
          },
        },
      ],
    },
    lifecycle: {
      installStrategy: "stage artifact inputs before switching runtime binding",
      replaceStrategy: "register_or_replace",
      rollbackStrategy: "restore previous binding or remove staged registration",
      deprecateStrategy: "freeze new registrations before removal",
      cleanupStrategy: "drain superseded artifacts after verification",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy: spec.profileAssignment === "review_only"
      ? "re_review_then_dispatch"
      : "auto_after_verify",
    artifacts: {
      toolArtifact: {
        artifactId: `tool.${capabilityRef}`,
        kind: "tool",
        ref: `tool:${spec.capabilityKey}`,
      },
      bindingArtifact: {
        artifactId: `binding.${capabilityRef}`,
        kind: "binding",
        ref: `binding:${spec.capabilityKey}`,
      },
      verificationArtifact: {
        artifactId: `verification.${capabilityRef}`,
        kind: "verification",
        ref: `verification:${spec.capabilityKey}`,
      },
      usageArtifact: {
        artifactId: `usage.${capabilityRef}`,
        kind: "usage",
        ref: `usage:${spec.capabilityKey}`,
      },
    },
    metadata: {
      firstWave: true,
      registrationAssignment: spec.profileAssignment,
      targetLane: spec.targetLane,
    },
  };
}

export function createFirstWaveCapabilityPackage(
  capabilityKey: FirstWaveCapabilityKey,
): CapabilityPackage {
  return createCapabilityPackage(createPackageInputFromSpec(
    FIRST_WAVE_CAPABILITY_SPECS[capabilityKey],
  ));
}

export function createFirstWaveCapabilityPackageCatalog(): CapabilityPackage[] {
  return FIRST_WAVE_CAPABILITY_KEYS.map((capabilityKey) =>
    createFirstWaveCapabilityPackage(capabilityKey)
  );
}
