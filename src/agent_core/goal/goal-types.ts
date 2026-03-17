import type {
  GoalConstraint,
  GoalCriterion,
  GoalFrameCompiled,
  GoalFrameNormalized,
  GoalFrameSource
} from "../types/index.js";

export type {
  GoalConstraint,
  GoalCriterion,
  GoalFrameCompiled,
  GoalFrameNormalized,
  GoalFrameSource
};

export interface GoalSourceInput {
  goalId?: string;
  sessionId?: string;
  runId?: string;
  userInput: string;
  inputRefs?: string[];
  constraints?: GoalConstraint[];
  metadata?: Record<string, unknown>;
}

export interface GoalNormalizationOptions {
  taskStatement?: string;
  successCriteria?: GoalCriterion[];
  failureCriteria?: GoalCriterion[];
  additionalConstraints?: GoalConstraint[];
}

export interface GoalCompileCapabilityHint {
  key: string;
  description?: string;
}

export interface GoalCompileContext {
  staticInstructions?: string[];
  capabilityHints?: GoalCompileCapabilityHint[];
  contextSummary?: string;
  metadata?: Record<string, unknown>;
}
