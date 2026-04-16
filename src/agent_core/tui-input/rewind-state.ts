import {
  createSurfaceAppState,
  createSurfaceSession,
  type SurfaceAppState,
  type SurfaceMessage,
  type SurfaceTask,
  type SurfaceTurn,
} from "../surface/index.js";
import type { DirectTuiTurnCheckpointRecord } from "./direct-turn-checkpoints.js";

export const DIRECT_TUI_REWIND_MODES = [
  "rewind_turn_and_workspace",
  "rewind_turn_only",
  "rewind_workspace_only",
] as const;

export type DirectTuiRewindMode = (typeof DIRECT_TUI_REWIND_MODES)[number];

export interface DirectTuiRewindTurnOption {
  sessionId: string;
  agentId: string;
  turnId: string;
  turnIndex: number;
  messageId: string;
  createdAt: string;
  userText: string;
  displayUserText: string;
  transcriptCutMessageId?: string;
  workspaceCheckpointRef?: string;
  workspaceCheckpointCommit?: string;
  workspaceCheckpointError?: string;
  workspaceCheckpointErrorCode?: string;
  workspaceCheckpointErrorOrigin?: string;
  workspaceCheckpointErrorMessage?: string;
  checkpointState: "workspace_ready" | "tool_used_no_checkpoint" | "checkpoint_error" | "conversation_only";
  checkpointLabel: string;
}

export interface DirectTuiRewindModeOption {
  mode: DirectTuiRewindMode;
  label: string;
  description: string;
  disabled: boolean;
  reason?: string;
}

export function parseDirectTuiTurnIndex(turnId: string): number {
  const trimmed = turnId.trim();
  if (/^\d+$/u.test(trimmed)) {
    return Number.parseInt(trimmed, 10);
  }
  const match = trimmed.match(/(\d+)$/u);
  if (!match) {
    return Number.MAX_SAFE_INTEGER;
  }
  return Number.parseInt(match[1] ?? "", 10);
}

function hasToolUsageForTurn(messages: SurfaceMessage[], turnId: string): boolean {
  return messages.some((message) => {
    if (message.turnId !== turnId) {
      return false;
    }
    if (typeof message.capabilityKey === "string" && message.capabilityKey.trim().length > 0) {
      return true;
    }
    if (!message.metadata || typeof message.metadata !== "object") {
      return false;
    }
    const source = typeof message.metadata.source === "string" ? message.metadata.source : "";
    if (source === "tool_summary" || source === "family_summary") {
      return true;
    }
    return typeof message.metadata.familyKey === "string"
      || typeof message.metadata.tapFamilyKey === "string";
  });
}

function resolveCheckpointErrorDisplay(input: {
  code?: string;
  rawReason?: string;
}): {
  shortLabel: string;
  reason: string;
} {
  switch (input.code) {
    case "workspace_unavailable":
      return {
        shortLabel: "workspace-unavailable",
        reason: "当前工作区路径不可用，所以这轮没有建立工作区快照。",
      };
    case "workspace_unreadable":
      return {
        shortLabel: "workspace-unreadable",
        reason: "当前工作区里有不可读路径，所以这轮没有建立工作区快照。",
      };
    case "workspace_scan_failed":
      return {
        shortLabel: "workspace-scan-failed",
        reason: "扫描当前工作区时失败了，所以这轮没有建立工作区快照。",
      };
    case "nested_worktree_skipped":
      return {
        shortLabel: "nested-worktree",
        reason: "当前工作区遇到了嵌套 worktree，这轮没有建立工作区快照。",
      };
    default:
      return {
        shortLabel: "checkpoint-error",
        reason: normalizeWorkspaceCheckpointReason(input.rawReason) ?? "这轮工作区快照建立失败了。",
      };
  }
}

function resolveCheckpointState(params: {
  turnId: string;
  messages: SurfaceMessage[];
  checkpoint?: DirectTuiTurnCheckpointRecord;
}): Pick<DirectTuiRewindTurnOption, "checkpointState" | "checkpointLabel"> {
  if (params.checkpoint?.workspaceCheckpointRef) {
    return {
      checkpointState: "workspace_ready",
      checkpointLabel: "workspace-ready",
    };
  }
  if (params.checkpoint?.workspaceCheckpointError) {
    const errorDisplay = resolveCheckpointErrorDisplay({
      code: params.checkpoint.workspaceCheckpointErrorCode,
      rawReason: params.checkpoint.workspaceCheckpointError,
    });
    return {
      checkpointState: "checkpoint_error",
      checkpointLabel: errorDisplay.shortLabel,
    };
  }
  if (hasToolUsageForTurn(params.messages, params.turnId)) {
    return {
      checkpointState: "tool_used_no_checkpoint",
      checkpointLabel: "tool-used-no-checkpoint",
    };
  }
  return {
    checkpointState: "conversation_only",
    checkpointLabel: "conversation-only",
  };
}

function normalizeWorkspaceCheckpointReason(value: string | undefined): string | undefined {
  if (!value) {
    return undefined;
  }
  if (/ENOENT/u.test(value) || /no such file or directory/u.test(value)) {
    return "workspace path unavailable";
  }
  if (/EACCES/u.test(value) || /permission denied/u.test(value)) {
    return "workspace checkpoint skipped unreadable path";
  }
  if (/EISDIR/u.test(value) || /illegal operation on a directory/u.test(value)) {
    return "workspace checkpoint skipped nested worktree directory";
  }
  if (/scandir/u.test(value) || /readdir/u.test(value) || /workspace/i.test(value) && /scan/i.test(value)) {
    return "workspace checkpoint could not scan the workspace";
  }
  return value;
}

export function buildDirectTuiRewindTurnOptions(params: {
  messages: SurfaceMessage[];
  checkpoints: DirectTuiTurnCheckpointRecord[];
}): DirectTuiRewindTurnOption[] {
  const checkpointMap = new Map(params.checkpoints.map((entry) => [entry.turnId, entry]));
  return params.messages
    .filter((message) => message.kind === "user" && typeof message.turnId === "string" && message.turnId.length > 0)
    .map((message) => {
      const checkpoint = checkpointMap.get(message.turnId ?? "");
      const checkpointState = resolveCheckpointState({
        turnId: message.turnId ?? "",
        messages: params.messages,
        checkpoint,
      });
      return {
        sessionId: checkpoint?.sessionId ?? "",
        agentId: checkpoint?.agentId ?? "agent.core:main",
        turnId: message.turnId ?? "",
        turnIndex: parseDirectTuiTurnIndex(message.turnId ?? ""),
        messageId: message.messageId,
        createdAt: message.createdAt,
        userText: message.text,
        displayUserText: checkpoint?.displayUserText?.trim() || message.text,
        transcriptCutMessageId: checkpoint?.transcriptCutMessageId,
        workspaceCheckpointRef: checkpoint?.workspaceCheckpointRef,
        workspaceCheckpointCommit: checkpoint?.workspaceCheckpointCommit,
        workspaceCheckpointError: checkpoint?.workspaceCheckpointError,
        workspaceCheckpointErrorCode: checkpoint?.workspaceCheckpointErrorCode,
        workspaceCheckpointErrorOrigin: checkpoint?.workspaceCheckpointErrorOrigin,
        workspaceCheckpointErrorMessage: checkpoint?.workspaceCheckpointErrorMessage,
        checkpointState: checkpointState.checkpointState,
        checkpointLabel: checkpointState.checkpointLabel,
      };
    })
    .sort((left, right) => right.turnIndex - left.turnIndex);
}

export function buildDirectTuiRewindModeOptions(
  option: DirectTuiRewindTurnOption | undefined,
): DirectTuiRewindModeOption[] {
  const hasWorkspaceCheckpoint = Boolean(option?.workspaceCheckpointRef);
  const unavailableReason = option?.workspaceCheckpointError
    ? resolveCheckpointErrorDisplay({
      code: option.workspaceCheckpointErrorCode,
      rawReason: option.workspaceCheckpointError,
    }).reason
    : "当前这轮还没有可用的工作区快照。";
  return [
    {
      mode: "rewind_turn_and_workspace",
      label: "Rewind turn and workspace",
      description: "回退到选中输入，并回退之后的所有改动。",
      disabled: !hasWorkspaceCheckpoint,
      reason: !hasWorkspaceCheckpoint ? unavailableReason : undefined,
    },
    {
      mode: "rewind_turn_only",
      label: "Rewind turn only",
      description: "只回退对话，不动后续工作区改动。",
      disabled: false,
    },
    {
      mode: "rewind_workspace_only",
      label: "Rewind workspace only",
      description: "只回退后续工作区改动，不回退对话。",
      disabled: !hasWorkspaceCheckpoint,
      reason: !hasWorkspaceCheckpoint ? unavailableReason : undefined,
    },
  ];
}

function trimMessagesBeforeTurn(
  messages: SurfaceMessage[],
  targetTurnId: string,
  transcriptCutMessageId?: string,
): SurfaceMessage[] {
  const cutoffIndex = transcriptCutMessageId
    ? messages.findIndex((message) => message.messageId === transcriptCutMessageId)
    : messages.findIndex((message) => message.turnId === targetTurnId);
  if (cutoffIndex === undefined || cutoffIndex < 0) {
    return transcriptCutMessageId ? [] : messages;
  }
  return transcriptCutMessageId ? messages.slice(0, cutoffIndex + 1) : messages.slice(0, cutoffIndex);
}

function trimTurnsBeforeTarget(turns: SurfaceTurn[], targetTurnId: string): SurfaceTurn[] {
  return turns.filter((turn) => parseDirectTuiTurnIndex(turn.turnId) < parseDirectTuiTurnIndex(targetTurnId));
}

function trimTasksToTurn(tasks: SurfaceTask[], remainingTurnIds: Set<string>): SurfaceTask[] {
  return tasks.filter((task) => !task.turnId || remainingTurnIds.has(task.turnId));
}

export function rewindSurfaceStateToTurn(
  state: SurfaceAppState,
  targetTurnId: string,
  at: string,
  transcriptCutMessageId?: string,
): SurfaceAppState {
  const messages = trimMessagesBeforeTurn(state.messages, targetTurnId, transcriptCutMessageId);
  const turns = trimTurnsBeforeTarget(state.turns, targetTurnId);
  const remainingTurnIds = new Set(
    messages
      .map((message) => message.turnId)
      .filter((turnId): turnId is string => typeof turnId === "string" && turnId.length > 0),
  );
  const tasks = trimTasksToTurn(state.tasks, remainingTurnIds);
  const latestRemainingTurnId = turns[turns.length - 1]?.turnId;
  const session = state.session
    ? createSurfaceSession({
      ...state.session,
      activeTurnId: latestRemainingTurnId,
      currentRunId: latestRemainingTurnId,
      updatedAt: at,
      transcriptMessageIds: messages.map((message) => message.messageId),
      taskIds: tasks.map((task) => task.taskId),
    })
    : state.session;

  return createSurfaceAppState({
    ...state,
    session,
    turns,
    messages,
    tasks,
    currentTurnId: latestRemainingTurnId,
    selectedTurnId: latestRemainingTurnId,
    updatedAt: at,
  });
}
