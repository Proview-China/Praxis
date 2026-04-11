import assert from "node:assert/strict";
import test from "node:test";

import {
  SURFACE_EVENT_TYPES,
  createSurfaceMessageAppendedEvent,
  createSurfacePanelUpdatedEvent,
  createSurfaceSessionStartedEvent,
  createSurfaceTaskUpsertedEvent,
  createSurfaceTurnStartedEvent,
} from "./events.js";

test("surface event constants include expected event names", () => {
  assert.ok(SURFACE_EVENT_TYPES.includes("session.started"));
  assert.ok(SURFACE_EVENT_TYPES.includes("message.appended"));
  assert.ok(SURFACE_EVENT_TYPES.includes("overlay.closed"));
});

test("surface event creators keep stable discriminators", () => {
  const sessionEvent = createSurfaceSessionStartedEvent({
    sessionId: "s-1",
    startedAt: "2026-04-11T00:00:00.000Z",
    uiMode: "direct",
  });
  assert.equal(sessionEvent.type, "session.started");

  const turnEvent = createSurfaceTurnStartedEvent({
    id: "turn-1",
    turnIndex: 1,
    status: "running",
    startedAt: "2026-04-11T00:00:01.000Z",
  });
  assert.equal(turnEvent.type, "turn.started");

  const messageEvent = createSurfaceMessageAppendedEvent({
    id: "msg-1",
    kind: "assistant",
    createdAt: "2026-04-11T00:00:02.000Z",
    text: "hello",
  });
  assert.equal(messageEvent.type, "message.appended");

  const taskEvent = createSurfaceTaskUpsertedEvent({
    taskId: "task-1",
    kind: "core_turn",
    status: "running",
    title: "run",
    startedAt: "2026-04-11T00:00:03.000Z",
    updatedAt: "2026-04-11T00:00:03.000Z",
  });
  assert.equal(taskEvent.type, "task.started");

  const panelEvent = createSurfacePanelUpdatedEvent("tap", {
    kind: "tap",
    title: "TAP",
    updatedAt: "2026-04-11T00:00:04.000Z",
    summaryLines: ["running"],
    summary: "running",
  }, "2026-04-11T00:00:04.000Z");
  assert.equal(panelEvent.type, "tap.snapshot.updated");
  assert.equal(panelEvent.snapshot.kind, "tap");
});
