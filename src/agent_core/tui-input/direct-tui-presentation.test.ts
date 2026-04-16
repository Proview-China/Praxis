import assert from "node:assert/strict";
import test from "node:test";

import { createSurfaceMessage } from "../surface/types.js";
import {
  hasDirectTuiFormalConversation,
  resolveDirectTuiAssistantTurnResultAction,
  resolveDirectTuiConversationPhase,
  shouldRenderDirectTuiConversationHeader,
} from "./direct-tui-presentation.js";

test("formal conversation starts only after a real user message appears", () => {
  const startupOnly = [
    createSurfaceMessage({
      messageId: "status:1",
      kind: "status",
      text: "warming up",
      createdAt: "2026-04-14T00:00:00.000Z",
    }),
    createSurfaceMessage({
      messageId: "assistant:welcome",
      kind: "assistant",
      text: "hello there",
      createdAt: "2026-04-14T00:00:01.000Z",
    }),
  ];
  assert.equal(hasDirectTuiFormalConversation(startupOnly), false);
  assert.equal(resolveDirectTuiConversationPhase({
    conversationActivated: false,
    messages: startupOnly,
  }), "intro");

  const withUser = [
    ...startupOnly,
    createSurfaceMessage({
      messageId: "user:1",
      kind: "user",
      text: "你好",
      createdAt: "2026-04-14T00:00:02.000Z",
    }),
  ];
  assert.equal(hasDirectTuiFormalConversation(withUser), true);
  assert.equal(resolveDirectTuiConversationPhase({
    conversationActivated: false,
    messages: withUser,
  }), "conversation");
});

test("conversation phase can activate immediately after submit before transcript catches up", () => {
  assert.equal(resolveDirectTuiConversationPhase({
    conversationActivated: true,
    messages: [],
  }), "conversation");
});

test("conversation header lives in the scrollable transcript instead of a fixed masthead", () => {
  assert.equal(shouldRenderDirectTuiConversationHeader({
    conversationActivated: false,
    messages: [],
    pendingSessionSwitch: false,
  }), true);

  assert.equal(shouldRenderDirectTuiConversationHeader({
    conversationActivated: true,
    messages: [],
    pendingSessionSwitch: false,
  }), false);

  assert.equal(shouldRenderDirectTuiConversationHeader({
    conversationActivated: true,
    messages: [
      createSurfaceMessage({
        messageId: "user:1",
        kind: "user",
        text: "你好",
        createdAt: "2026-04-14T00:00:02.000Z",
      }),
    ],
    pendingSessionSwitch: false,
  }), true);

  assert.equal(shouldRenderDirectTuiConversationHeader({
    conversationActivated: false,
    messages: [
      createSurfaceMessage({
        messageId: "user:2",
        kind: "user",
        text: "继续",
        createdAt: "2026-04-14T00:00:03.000Z",
      }),
    ],
    pendingSessionSwitch: true,
  }), false);
});

test("turn_result updates the active assistant message instead of appending a second segment", () => {
  assert.deepEqual(resolveDirectTuiAssistantTurnResultAction({
    finalAnswer: "你好！我是 Praxis Core。",
    streamedText: "你好！我是 Praxis Core，",
    activeMessageId: "assistant:turn-1:1",
  }), {
    kind: "update",
    text: "你好！我是 Praxis Core。",
    messageId: "assistant:turn-1:1",
  });
});

test("turn_result appends only when there was no streamed assistant message", () => {
  assert.deepEqual(resolveDirectTuiAssistantTurnResultAction({
    finalAnswer: "完整答案",
    streamedText: "",
  }), {
    kind: "append",
    text: "完整答案",
  });
});

test("turn_result is a noop when the final answer already matches streamed text", () => {
  assert.deepEqual(resolveDirectTuiAssistantTurnResultAction({
    finalAnswer: "最终一致",
    streamedText: "最终一致",
    activeMessageId: "assistant:turn-2:1",
  }), {
    kind: "noop",
  });
});
