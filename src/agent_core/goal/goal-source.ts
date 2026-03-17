import { randomUUID } from "node:crypto";

import type { GoalFrameSource } from "../types/index.js";
import type { GoalSourceInput } from "./goal-types.js";

function trimOrThrow(label: string, value: string): string {
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    throw new Error(`${label} must not be empty.`);
  }
  return trimmed;
}

export function createGoalSource(input: GoalSourceInput): GoalFrameSource {
  return {
    goalId: input.goalId ?? randomUUID(),
    sessionId: input.sessionId,
    runId: input.runId,
    userInput: trimOrThrow("GoalFrameSource.userInput", input.userInput),
    inputRefs: [...(input.inputRefs ?? [])],
    constraints: [...(input.constraints ?? [])],
    metadata: input.metadata ? { ...input.metadata } : undefined
  };
}
