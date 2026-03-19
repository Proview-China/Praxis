import {
  matchesCapabilityPattern,
  type TaCapabilityTier,
} from "../ta-pool-types/ta-pool-profile.js";
import type { TaPoolRiskLevel } from "../ta-pool-types/ta-pool-review.js";

export const TA_CAPABILITY_RISK_REASONS = [
  "default_normal",
  "risky_pattern",
  "dangerous_pattern",
  "critical_tier",
] as const;
export type TaCapabilityRiskReason = (typeof TA_CAPABILITY_RISK_REASONS)[number];

export interface TaCapabilityRiskClassifierConfig {
  riskyCapabilityPatterns?: string[];
  dangerousCapabilityPatterns?: string[];
}

export interface ClassifyCapabilityRiskInput {
  capabilityKey: string;
  requestedTier?: TaCapabilityTier;
  config?: TaCapabilityRiskClassifierConfig;
}

export interface TaCapabilityRiskClassification {
  capabilityKey: string;
  riskLevel: TaPoolRiskLevel;
  reason: TaCapabilityRiskReason;
  matchedPattern?: string;
}

const DEFAULT_RISKY_PATTERNS = [
  "shell.*",
  "system.*",
  "computer.use*",
  "workspace.outside.*",
  "filesystem.delete.*",
  "git.reset.*",
  "git.checkout.discard",
  "sudo",
  "mcp.root.*",
  "mcp.browser.control",
  "mcp.playwright",
  "computer_use.*",
  "code.exec.*",
  "shell.exec",
  "shell.run",
  "delete.*",
  "rm.*",
] as const;

const DEFAULT_DANGEROUS_PATTERNS = [
  "shell.rm*",
  "shell.delete*",
  "system.sudo",
  "git.reset.hard",
  "git.checkout.discard",
  "filesystem.delete.*",
  "workspace.outside.write",
  "workspace.outside.delete",
  "computer.use.dangerous",
] as const;

function normalizePatterns(params: {
  defaults: readonly string[];
  overrides?: readonly string[];
}): string[] {
  const values = params.overrides ?? params.defaults;
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function firstMatch(capabilityKey: string, patterns: readonly string[]): string | undefined {
  return patterns.find((pattern) =>
    matchesCapabilityPattern({
      capabilityKey,
      patterns: [pattern],
    })
  );
}

export function classifyCapabilityRisk(
  input: ClassifyCapabilityRiskInput,
): TaCapabilityRiskClassification {
  const dangerousPattern = firstMatch(
    input.capabilityKey,
    normalizePatterns({
      defaults: DEFAULT_DANGEROUS_PATTERNS,
      overrides: input.config?.dangerousCapabilityPatterns,
    }),
  );
  if (dangerousPattern) {
    return {
      capabilityKey: input.capabilityKey,
      riskLevel: "dangerous",
      reason: "dangerous_pattern",
      matchedPattern: dangerousPattern,
    };
  }

  const riskyPattern = firstMatch(
    input.capabilityKey,
    normalizePatterns({
      defaults: DEFAULT_RISKY_PATTERNS,
      overrides: input.config?.riskyCapabilityPatterns,
    }),
  );
  if (riskyPattern) {
    return {
      capabilityKey: input.capabilityKey,
      riskLevel: "risky",
      reason: "risky_pattern",
      matchedPattern: riskyPattern,
    };
  }

  if (input.requestedTier === "B3") {
    return {
      capabilityKey: input.capabilityKey,
      riskLevel: "risky",
      reason: "critical_tier",
    };
  }

  return {
    capabilityKey: input.capabilityKey,
    riskLevel: "normal",
    reason: "default_normal",
  };
}

export function isHighRiskLevel(riskLevel: TaPoolRiskLevel): boolean {
  return riskLevel === "risky" || riskLevel === "dangerous";
}
