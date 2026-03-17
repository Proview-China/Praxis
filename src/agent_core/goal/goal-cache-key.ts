import { createHash } from "node:crypto";

import type { GoalFrameNormalized } from "../types/index.js";
import type { GoalCompileContext } from "./goal-types.js";

function normalizeForHash(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map((entry) => normalizeForHash(entry));
  }

  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .sort(([left], [right]) => left.localeCompare(right, "en"))
        .map(([key, entry]) => [key, normalizeForHash(entry)])
    );
  }

  return value;
}

export function stableStringify(value: unknown): string {
  return JSON.stringify(normalizeForHash(value));
}

export function buildGoalCompiledCacheKey(
  normalized: GoalFrameNormalized,
  context: GoalCompileContext = {}
): string {
  const hash = createHash("sha256");
  hash.update(
    stableStringify({
      goalId: normalized.goalId,
      taskStatement: normalized.taskStatement,
      successCriteria: normalized.successCriteria,
      failureCriteria: normalized.failureCriteria,
      constraints: normalized.constraints,
      inputRefs: normalized.inputRefs,
      metadata: normalized.metadata ?? null,
      staticInstructions: context.staticInstructions ?? [],
      capabilityHints: context.capabilityHints ?? [],
      contextSummary: context.contextSummary ?? null,
      contextMetadata: context.metadata ?? null
    })
  );

  return hash.digest("hex");
}
