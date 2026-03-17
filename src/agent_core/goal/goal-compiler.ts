import type { GoalFrameCompiled, GoalFrameNormalized } from "../types/index.js";
import { buildGoalCompiledCacheKey } from "./goal-cache-key.js";
import type { GoalCompileContext } from "./goal-types.js";

function renderSection(
  title: string,
  lines: string[]
): string[] {
  if (lines.length === 0) {
    return [];
  }

  return [title, ...lines];
}

export function compileGoal(
  normalized: GoalFrameNormalized,
  context: GoalCompileContext = {}
): GoalFrameCompiled {
  const instructionLines = [
    ...renderSection("Task", [normalized.taskStatement]),
    ...renderSection(
      "Success Criteria",
      normalized.successCriteria.map((criterion) => `- ${criterion.description}`)
    ),
    ...renderSection(
      "Failure Criteria",
      normalized.failureCriteria.map((criterion) => `- ${criterion.description}`)
    ),
    ...renderSection(
      "Constraints",
      normalized.constraints.map((constraint) => {
        const description = constraint.description
          ? ` (${constraint.description})`
          : "";
        return `- ${constraint.key}=${JSON.stringify(constraint.value)}${description}`;
      })
    ),
    ...renderSection(
      "Input Refs",
      normalized.inputRefs.map((ref) => `- ${ref}`)
    ),
    ...renderSection(
      "Static Instructions",
      (context.staticInstructions ?? []).map((instruction) => `- ${instruction}`)
    ),
    ...renderSection(
      "Capability Hints",
      (context.capabilityHints ?? []).map((hint) =>
        hint.description ? `- ${hint.key}: ${hint.description}` : `- ${hint.key}`
      )
    ),
    ...renderSection(
      "Context Summary",
      context.contextSummary ? [context.contextSummary] : []
    )
  ];

  const cacheKey = buildGoalCompiledCacheKey(normalized, context);

  return {
    goalId: normalized.goalId,
    instructionText: instructionLines.join("\n"),
    successCriteria: normalized.successCriteria.map((criterion) => ({ ...criterion })),
    failureCriteria: normalized.failureCriteria.map((criterion) => ({ ...criterion })),
    constraints: normalized.constraints.map((constraint) => ({ ...constraint })),
    inputRefs: [...normalized.inputRefs],
    cacheKey,
    metadata:
      normalized.metadata || context.metadata
        ? {
            ...(normalized.metadata ?? {}),
            ...(context.metadata ?? {})
          }
        : undefined
  };
}
