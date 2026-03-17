import type {
  GoalConstraint,
  GoalCriterion,
  GoalFrameNormalized,
  GoalFrameSource
} from "../types/index.js";
import type { GoalNormalizationOptions } from "./goal-types.js";

function normalizeCriteria(
  criteria: GoalCriterion[] | undefined,
  fallback: GoalCriterion[]
): GoalCriterion[] {
  const list = criteria ?? fallback;
  return list.map((criterion) => ({
    id: criterion.id,
    description: criterion.description.trim(),
    required: criterion.required
  }));
}

function dedupeConstraints(constraints: GoalConstraint[]): GoalConstraint[] {
  const seen = new Set<string>();
  const normalized: GoalConstraint[] = [];

  for (const constraint of constraints) {
    const key = `${constraint.key}:${JSON.stringify(constraint.value)}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    normalized.push({
      key: constraint.key.trim(),
      value: constraint.value,
      description: constraint.description?.trim()
    });
  }

  return normalized;
}

function buildDefaultSuccessCriteria(taskStatement: string): GoalCriterion[] {
  return [
    {
      id: "complete-task",
      description: `完成目标：${taskStatement}`,
      required: true
    }
  ];
}

function buildDefaultFailureCriteria(): GoalCriterion[] {
  return [
    {
      id: "goal-blocked",
      description: "遇到阻塞且无法继续推进当前目标",
      required: true
    }
  ];
}

export function normalizeGoal(
  source: GoalFrameSource,
  options: GoalNormalizationOptions = {}
): GoalFrameNormalized {
  const taskStatement = (options.taskStatement ?? source.userInput).trim();
  if (taskStatement.length === 0) {
    throw new Error("GoalFrameNormalized.taskStatement must not be empty.");
  }

  const mergedConstraints = dedupeConstraints([
    ...(source.constraints ?? []),
    ...(options.additionalConstraints ?? [])
  ]);

  return {
    goalId: source.goalId,
    taskStatement,
    successCriteria: normalizeCriteria(
      options.successCriteria,
      buildDefaultSuccessCriteria(taskStatement)
    ),
    failureCriteria: normalizeCriteria(
      options.failureCriteria,
      buildDefaultFailureCriteria()
    ),
    constraints: mergedConstraints,
    inputRefs: [...(source.inputRefs ?? [])],
    metadata: source.metadata ? { ...source.metadata } : undefined
  };
}
