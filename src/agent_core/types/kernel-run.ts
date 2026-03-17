import type { GoalFrameCompiled } from "./kernel-goal.js";
import type { KernelResult } from "./kernel-results.js";
import type { AgentPhase, AgentStatus } from "./kernel-state.js";
import type { CheckpointId, RunId, SessionId } from "./kernel-session.js";

export interface RunRecord {
  runId: RunId;
  sessionId: SessionId;
  status: AgentStatus;
  phase: AgentPhase;
  goal: GoalFrameCompiled;
  currentStep: number;
  pendingIntentId?: string;
  lastEventId?: string;
  lastResult?: KernelResult;
  lastCheckpointRef?: CheckpointId;
  startedAt: string;
  endedAt?: string;
  metadata?: Record<string, unknown>;
}
