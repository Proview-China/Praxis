import type {
  CapabilityPackage,
  FirstWaveCapabilityKey,
} from "../capability-package/index.js";
import {
  createFirstWaveCapabilityPackageCatalog,
} from "../capability-package/index.js";
import type {
  AgentCapabilityProfile,
  CreateAgentCapabilityProfileInput,
} from "../ta-pool-types/index.js";
import { createAgentCapabilityProfile } from "../ta-pool-types/index.js";
import type { CapabilityAccessAssignment } from "./profile-baseline.js";

export const FIRST_WAVE_BASELINE_CAPABILITIES = [
  "code.read",
  "docs.read",
] as const;

export const FIRST_WAVE_ALLOWED_CAPABILITY_PATTERNS = [
  "repo.write",
  "shell.restricted",
  "test.run",
  "skill.doc.generate",
] as const;

export const FIRST_WAVE_BOOTSTRAP_REVIEW_ONLY_CAPABILITIES = [] as const;

export const FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITIES = [
  "dependency.install",
  "network.download",
] as const;

export const FIRST_WAVE_REVIEW_ONLY_CAPABILITIES = [
  ...FIRST_WAVE_BOOTSTRAP_REVIEW_ONLY_CAPABILITIES,
  ...FIRST_WAVE_EXTENDED_REVIEW_ONLY_CAPABILITIES,
] as const;

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
  baselineCapabilities?: string[];
  allowedCapabilityPatterns?: string[];
  reviewOnlyCapabilities?: string[];
  reviewOnlyCapabilityPatterns?: string[];
}

export function createFirstWaveCapabilityProfile(
  input: CreateFirstWaveCapabilityProfileInput,
): AgentCapabilityProfile {
  const assembled = assembleCapabilityProfileFromPackages({
    ...input,
    packages: createFirstWaveCapabilityPackageCatalog(),
  });

  return createAgentCapabilityProfile({
    ...assembled,
    baselineCapabilities: [
      ...(assembled.baselineCapabilities ?? []),
      ...(input.baselineCapabilities ?? []),
    ],
    allowedCapabilityPatterns: [
      ...(assembled.allowedCapabilityPatterns ?? []),
      ...(input.allowedCapabilityPatterns ?? []),
    ],
    reviewOnlyCapabilities: [
      ...(assembled.reviewOnlyCapabilities ?? []),
      ...(input.reviewOnlyCapabilities ?? []),
    ],
    reviewOnlyCapabilityPatterns: input.reviewOnlyCapabilityPatterns,
    metadata: {
      ...(assembled.metadata ?? {}),
      firstWaveProfile: true,
    },
  });
}
