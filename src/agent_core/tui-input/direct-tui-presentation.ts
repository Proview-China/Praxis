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
