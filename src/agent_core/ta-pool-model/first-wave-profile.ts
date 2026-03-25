import type { CapabilityPackage } from "../capability-package/capability-package.js";
import type {
  FirstWaveCapabilityFamilyKey,
  FirstWaveCapabilityKey,
} from "../capability-package/first-wave-capability-package.js";
import {
  createFirstWaveCapabilityPackageCatalogForFamily,
  FIRST_WAVE_BOOTSTRAP_TMA_CAPABILITY_KEYS,
  FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITY_KEYS,
  FIRST_WAVE_REVIEWER_BASELINE_CAPABILITY_KEYS,
} from "../capability-package/first-wave-capability-package.js";
import type {
  AgentCapabilityProfile,
  CreateAgentCapabilityProfileInput,
} from "../ta-pool-types/index.js";
import { createAgentCapabilityProfile } from "../ta-pool-types/index.js";
import type { CapabilityAccessAssignment } from "./profile-baseline.js";

export const FIRST_WAVE_BASELINE_CAPABILITIES = FIRST_WAVE_REVIEWER_BASELINE_CAPABILITY_KEYS;
export const FIRST_WAVE_ALLOWED_CAPABILITY_PATTERNS = FIRST_WAVE_BOOTSTRAP_TMA_CAPABILITY_KEYS;
export const FIRST_WAVE_BOOTSTRAP_REVIEW_ONLY_CAPABILITIES = [] as const;
export const FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITIES =
  FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITY_KEYS;
export const FIRST_WAVE_REVIEW_ONLY_CAPABILITIES = [
  ...FIRST_WAVE_BOOTSTRAP_REVIEW_ONLY_CAPABILITIES,
  ...FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITIES,
] as const;

export const FIRST_WAVE_PROFILE_ASSEMBLY_TARGETS = [
  "baseline",
  "reviewer",
  "bootstrap_tma",
  "first_wave",
] as const;
export type FirstWaveProfileAssemblyTarget =
  (typeof FIRST_WAVE_PROFILE_ASSEMBLY_TARGETS)[number];

export interface FirstWaveProfileAssemblyDescriptor {
  target: FirstWaveProfileAssemblyTarget;
  summary: string;
  reviewerSummary: string;
  familyKeys: FirstWaveCapabilityFamilyKey[];
  readOnly: boolean;
  mayProvision: boolean;
  includesReviewOnly: boolean;
}

const FIRST_WAVE_PROFILE_ASSEMBLY_DESCRIPTOR_MAP: Record<
  FirstWaveProfileAssemblyTarget,
  FirstWaveProfileAssemblyDescriptor
> = {
  baseline: {
    target: "baseline",
    summary:
      "Baseline assembly keeps only the first-wave reviewer grounding family so downstream profiles can start from a read-only foundation.",
    reviewerSummary:
      "Baseline assembly is the smallest read-only slice: repo code and docs only, with no write or execution tools.",
    familyKeys: ["reviewer_baseline"],
    readOnly: true,
    mayProvision: false,
    includesReviewOnly: false,
  },
  reviewer: {
    target: "reviewer",
    summary:
      "Reviewer assembly is the read-only first-wave profile used to ground access decisions before stronger capabilities are requested.",
    reviewerSummary:
      "Reviewer can inspect code and docs only; write, shell, install, and network work stay out of this assembly target.",
    familyKeys: ["reviewer_baseline"],
    readOnly: true,
    mayProvision: false,
    includesReviewOnly: false,
  },
  bootstrap_tma: {
    target: "bootstrap_tma",
    summary:
      "Bootstrap TMA assembly combines the reviewer baseline with bounded repo-local build tools for first-wave package staging and verification.",
    reviewerSummary:
      "Bootstrap TMA can patch, run restricted shell, test, and generate docs inside the workspace, but it still does not baseline-install or download.",
    familyKeys: ["reviewer_baseline", "bootstrap_tma"],
    readOnly: false,
    mayProvision: true,
    includesReviewOnly: false,
  },
  first_wave: {
    target: "first_wave",
    summary:
      "First-wave assembly adds the extended review-only family on top of the reviewer baseline and bootstrap TMA tooling.",
    reviewerSummary:
      "First-wave keeps install and download powers review-gated while still exposing them in the package-backed assembly summary.",
    familyKeys: ["reviewer_baseline", "bootstrap_tma", "extended_review_only"],
    readOnly: false,
    mayProvision: true,
    includesReviewOnly: true,
  },
};

export interface AssembleCapabilityProfileFromPackagesInput {
  profileId: string;
  agentClass: string;
  packages: readonly CapabilityPackage[];
  defaultMode?: CreateAgentCapabilityProfileInput["defaultMode"];
  baselineTier?: CreateAgentCapabilityProfileInput["baselineTier"];
  baselineCapabilities?: string[];
  allowedCapabilityPatterns?: string[];
  reviewOnlyCapabilities?: string[];
  reviewOnlyCapabilityPatterns?: string[];
  deniedCapabilityPatterns?: string[];
  notes?: string;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPackageProfileAssemblySummary {
  baselineCapabilities: string[];
  allowedCapabilityPatterns: string[];
  reviewOnlyCapabilityKeys: string[];
}

export function getFirstWaveProfileAssemblyDescriptor(
  target: FirstWaveProfileAssemblyTarget,
): FirstWaveProfileAssemblyDescriptor {
  const descriptor = FIRST_WAVE_PROFILE_ASSEMBLY_DESCRIPTOR_MAP[target];
  return {
    ...descriptor,
    familyKeys: [...descriptor.familyKeys],
  };
}

export function listFirstWaveProfileAssemblyDescriptors(): FirstWaveProfileAssemblyDescriptor[] {
  return FIRST_WAVE_PROFILE_ASSEMBLY_TARGETS.map((target) =>
    getFirstWaveProfileAssemblyDescriptor(target),
  );
}

export function resolveFirstWaveCapabilityAssignment(
  capabilityKey: FirstWaveCapabilityKey | string,
): CapabilityAccessAssignment {
  if (FIRST_WAVE_BASELINE_CAPABILITIES.includes(capabilityKey as typeof FIRST_WAVE_BASELINE_CAPABILITIES[number])) {
    return "baseline";
  }

  if (
    FIRST_WAVE_ALLOWED_CAPABILITY_PATTERNS.includes(
      capabilityKey as typeof FIRST_WAVE_ALLOWED_CAPABILITY_PATTERNS[number],
    )
  ) {
    return "allowed_pattern";
  }

  if (
    FIRST_WAVE_REVIEW_ONLY_CAPABILITIES.includes(
      capabilityKey as typeof FIRST_WAVE_REVIEW_ONLY_CAPABILITIES[number],
    )
  ) {
    return "review_only";
  }

  return "unmatched";
}

function createFirstWaveCapabilityPackageCatalogForAssemblyTarget(
  target: FirstWaveProfileAssemblyTarget,
): CapabilityPackage[] {
  const descriptor = FIRST_WAVE_PROFILE_ASSEMBLY_DESCRIPTOR_MAP[target];
  const seen = new Set<string>();
  const packages: CapabilityPackage[] = [];

  for (const familyKey of descriptor.familyKeys) {
    for (const capabilityPackage of createFirstWaveCapabilityPackageCatalogForFamily(familyKey)) {
      const capabilityKey = capabilityPackage.manifest.capabilityKey;
      if (seen.has(capabilityKey)) {
        continue;
      }

      seen.add(capabilityKey);
      packages.push(capabilityPackage);
    }
  }

  return packages;
}

function assembleCapabilityProfileSummary(
  packages: readonly CapabilityPackage[],
): CapabilityPackageProfileAssemblySummary {
  const baselineCapabilities = new Set<string>();
  const allowedCapabilityPatterns = new Set<string>();
  const reviewOnlyCapabilityKeys = new Set<string>();

  for (const capabilityPackage of packages) {
    const capabilityKey = capabilityPackage.manifest.capabilityKey;
    const registration = capabilityPackage.policy.registrationAssembly;

    switch (registration.profileAssignment) {
      case "baseline_capability":
        baselineCapabilities.add(capabilityKey);
        break;
      case "allowed_pattern":
        allowedCapabilityPatterns.add(registration.allowedPattern ?? capabilityKey);
        break;
      case "review_only":
        reviewOnlyCapabilityKeys.add(capabilityKey);
        break;
    }
  }

  return {
    baselineCapabilities: [...baselineCapabilities],
    allowedCapabilityPatterns: [...allowedCapabilityPatterns],
    reviewOnlyCapabilityKeys: [...reviewOnlyCapabilityKeys],
  };
}

export function getFirstWaveCapabilityProfileAssemblySummary(
  target: FirstWaveProfileAssemblyTarget,
): CapabilityPackageProfileAssemblySummary {
  return assembleCapabilityProfileSummary(
    createFirstWaveCapabilityPackageCatalogForAssemblyTarget(target),
  );
}

export function assembleCapabilityProfileFromPackages(
  input: AssembleCapabilityProfileFromPackagesInput,
): AgentCapabilityProfile {
  const summary = assembleCapabilityProfileSummary(input.packages);
  const baselineCapabilities = [...new Set([
    ...summary.baselineCapabilities,
    ...(input.baselineCapabilities ?? []),
  ])];
  const allowedCapabilityPatterns = [...new Set([
    ...summary.allowedCapabilityPatterns,
    ...(input.allowedCapabilityPatterns ?? []),
  ])];
  const reviewOnlyCapabilities = [...new Set([
    ...summary.reviewOnlyCapabilityKeys,
    ...(input.reviewOnlyCapabilities ?? []),
  ])];
  const reviewOnlyCapabilityPatterns = [...new Set(
    (input.reviewOnlyCapabilityPatterns ?? []).map((value) => value.trim()).filter(Boolean),
  )];
  const notes = [
    input.notes,
    reviewOnlyCapabilities.length > 0
      ? `review-only: ${reviewOnlyCapabilities.join(", ")}`
      : undefined,
  ].filter((value): value is string => Boolean(value && value.trim())).join(" | ");

  return createAgentCapabilityProfile({
    profileId: input.profileId,
    agentClass: input.agentClass,
    defaultMode: input.defaultMode,
    baselineTier: input.baselineTier,
    baselineCapabilities,
    allowedCapabilityPatterns,
    reviewOnlyCapabilities,
    reviewOnlyCapabilityPatterns,
    deniedCapabilityPatterns: input.deniedCapabilityPatterns,
    notes: notes || undefined,
    metadata: {
      ...(input.metadata ?? {}),
      capabilityPackageAssembly: summary,
      capabilityPackageCount: input.packages.length,
    },
  });
}

export interface CreateFirstWaveCapabilityProfileInput
  extends Omit<AssembleCapabilityProfileFromPackagesInput, "packages"> {
  assemblyTarget?: FirstWaveProfileAssemblyTarget;
  baselineCapabilities?: string[];
  allowedCapabilityPatterns?: string[];
  reviewOnlyCapabilities?: string[];
  reviewOnlyCapabilityPatterns?: string[];
}

export function createFirstWaveCapabilityProfile(
  input: CreateFirstWaveCapabilityProfileInput,
): AgentCapabilityProfile {
  const assemblyTarget = input.assemblyTarget ?? "first_wave";
  const descriptor = getFirstWaveProfileAssemblyDescriptor(assemblyTarget);
  const assembled = assembleCapabilityProfileFromPackages({
    ...input,
    packages: createFirstWaveCapabilityPackageCatalogForAssemblyTarget(assemblyTarget),
  });

  return createAgentCapabilityProfile({
    profileId: assembled.profileId,
    agentClass: assembled.agentClass,
    defaultMode: assembled.defaultMode,
    baselineTier: assembled.baselineTier,
    baselineCapabilities: assembled.baselineCapabilities,
    allowedCapabilityPatterns: assembled.allowedCapabilityPatterns,
    reviewOnlyCapabilities: assembled.reviewOnlyCapabilities,
    reviewOnlyCapabilityPatterns: assembled.reviewOnlyCapabilityPatterns,
    deniedCapabilityPatterns: assembled.deniedCapabilityPatterns,
    notes: assembled.notes,
    metadata: {
      ...(assembled.metadata ?? {}),
      firstWaveProfile: true,
      firstWaveAssemblyTarget: assemblyTarget,
      firstWaveAssemblyFamilies: [...descriptor.familyKeys],
    },
  });
}
