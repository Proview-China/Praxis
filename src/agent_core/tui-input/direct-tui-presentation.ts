import type { SurfaceMessage } from "../surface/types.js";

export type DirectTuiConversationPhase = "intro" | "conversation";

export function hasDirectTuiFormalConversation(
  messages: readonly Pick<SurfaceMessage, "kind">[],
): boolean {
  return messages.some((message) => message.kind === "user");
}

export function resolveDirectTuiConversationPhase(input: {
  conversationActivated: boolean;
  messages: readonly Pick<SurfaceMessage, "kind">[];
}): DirectTuiConversationPhase {
  if (input.conversationActivated || hasDirectTuiFormalConversation(input.messages)) {
    return "conversation";
  }
  return "intro";
}

export function shouldRenderDirectTuiConversationHeader(input: {
  conversationActivated: boolean;
  messages: readonly Pick<SurfaceMessage, "kind">[];
  pendingSessionSwitch: boolean;
}): boolean {
  if (input.pendingSessionSwitch) {
    return false;
  }
  return resolveDirectTuiConversationPhase({
    conversationActivated: input.conversationActivated,
    messages: input.messages,
  }) === "intro" || input.messages.length > 0;
}

export function shouldBreakDirectTuiAssistantSegmentOnStageStart(stage?: string | null): boolean {
  const normalizedStage = stage?.trim();
  if (!normalizedStage) {
    return true;
  }
  if (normalizedStage === "core/run") {
    return false;
  }
  if (normalizedStage.startsWith("cmp/")) {
    return false;
  }
  return true;
}

export interface DirectTuiCmpStatusDescriptor {
  label: string;
  animated: boolean;
  tone: "muted" | "active" | "warning" | "danger";
}

export function deriveDirectTuiCmpStatusDescriptor(input: {
  activeStage?: string | null;
  snapshot?: {
    status?: string;
    readbackStatus?: string;
    emptyReason?: string;
  } | null;
}): DirectTuiCmpStatusDescriptor {
  const activeStage = input.activeStage?.trim();
  if (activeStage) {
    return {
      label: `CMP ${activeStage.replace(/^cmp\//u, "")} running`,
      animated: true,
      tone: "active",
    };
  }

  const readbackStatus = input.snapshot?.readbackStatus?.trim().toLowerCase();
  const status = input.snapshot?.status?.trim().toLowerCase();
  if (readbackStatus === "failed" || status === "failed") {
    return {
      label: "CMP readback failed",
      animated: false,
      tone: "danger",
    };
  }
  if (readbackStatus === "degraded" || status === "degraded") {
    return {
      label: "CMP readback degraded",
      animated: false,
      tone: "warning",
    };
  }
  if (readbackStatus === "ready" && status === "empty") {
    return {
      label: "CMP ready but empty",
      animated: false,
      tone: "muted",
    };
  }
  if (readbackStatus === "ready" || status === "ready") {
    return {
      label: "CMP ready",
      animated: false,
      tone: "muted",
    };
  }
  if (status === "booting") {
    return {
      label: "CMP warming up",
      animated: false,
      tone: "muted",
    };
  }
  return {
    label: "CMP status pending",
    animated: false,
    tone: "muted",
  };
}

export type DirectTuiAssistantTurnResultAction =
  | { kind: "noop" }
  | { kind: "append"; text: string }
  | { kind: "update"; text: string; messageId: string };

export function resolveDirectTuiAssistantTurnResultAction(input: {
  finalAnswer: string | null;
  streamedText: string;
  activeMessageId?: string;
}): DirectTuiAssistantTurnResultAction {
  if (!input.finalAnswer) {
    return { kind: "noop" };
  }
  if (!input.activeMessageId) {
    if (input.streamedText.length > 0) {
      return { kind: "noop" };
    }
    return {
      kind: "append",
      text: input.finalAnswer,
    };
  }
  if (input.finalAnswer === input.streamedText) {
    return { kind: "noop" };
  }
  return {
    kind: "update",
    text: input.finalAnswer,
    messageId: input.activeMessageId,
  };
}
