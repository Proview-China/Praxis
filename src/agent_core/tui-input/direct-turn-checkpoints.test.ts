import assert from "node:assert/strict";
import test from "node:test";
import { join } from "node:path";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";

import {
  appendDirectTuiCheckpointEvent,
  getDirectTuiTurnCheckpoint,
  listDirectTuiTurnCheckpoints,
  upsertDirectTuiTurnCheckpoint,
} from "./direct-turn-checkpoints.js";

test("direct turn checkpoints save, list, and replace records by turn id", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-turn-checkpoints-"));
  const workspaceRoot = join(home, "workspace");
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    rmSync(workspaceRoot, { recursive: true, force: true });
    upsertDirectTuiTurnCheckpoint("session-1", {
      sessionId: "session-1",
      agentId: "agent.core:main",
      turnId: "1",
      turnIndex: 1,
      messageId: "user:1",
      transcriptCutMessageId: "assistant:1:1",
      createdAt: "2026-04-14T00:00:01.000Z",
      userText: "first",
      displayUserText: "first",
      displayUserTextSource: "raw",
      workspaceRoot,
      workspaceCheckpointRef: "refs/checkpoints/1",
      workspaceCheckpointCommit: "abc123",
    }, workspaceRoot);
    upsertDirectTuiTurnCheckpoint("session-1", {
      sessionId: "session-1",
      agentId: "agent.core:main",
      turnId: "2",
      turnIndex: 2,
      messageId: "user:2",
      transcriptCutMessageId: "assistant:2:1",
      createdAt: "2026-04-14T00:00:02.000Z",
      userText: "second",
      displayUserText: "second",
      displayUserTextSource: "raw",
      workspaceRoot,
      workspaceCheckpointError: "snapshot failed",
      workspaceCheckpointErrorCode: "workspace_scan_failed",
      workspaceCheckpointErrorOrigin: "workspace_scan",
      workspaceCheckpointErrorMessage: "ENOENT: no such file or directory, scandir '/tmp/workspace/missing'",
    }, workspaceRoot);
    upsertDirectTuiTurnCheckpoint("session-1", {
      sessionId: "session-1",
      agentId: "agent.core:main",
      turnId: "2",
      turnIndex: 2,
      messageId: "user:2",
      transcriptCutMessageId: "assistant:2:1",
      createdAt: "2026-04-14T00:00:02.000Z",
      userText: "second updated",
      displayUserText: "summarized second",
      displayUserTextSource: "mini_summary",
      workspaceRoot,
      workspaceCheckpointRef: "refs/checkpoints/2",
      workspaceCheckpointCommit: "def456",
    }, workspaceRoot);

    const listed = listDirectTuiTurnCheckpoints("session-1", workspaceRoot);
    assert.equal(listed.length, 2);
    assert.equal(listed[0]?.turnId, "1");
    assert.equal(listed[1]?.userText, "second updated");
    assert.equal(listed[1]?.displayUserText, "summarized second");
    assert.equal(getDirectTuiTurnCheckpoint("session-1", "2", workspaceRoot)?.workspaceCheckpointCommit, "def456");
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
  }
});

test("direct checkpoint events append structured failure readback", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-turn-checkpoint-events-"));
  const workspaceRoot = join(home, "workspace");
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    appendDirectTuiCheckpointEvent({
      sessionId: "session-1",
      turnId: "1",
      workspaceRoot,
      createdAt: "2026-04-14T00:00:01.000Z",
      status: "checkpoint_failed",
      errorCode: "workspace_unavailable",
      errorOrigin: "workspace_root",
      errorMessage: "ENOENT: no such file or directory, scandir '/tmp/bad'",
    });

    const content = readFileSync(join(workspaceRoot, ".raxode", "rewind", "checkpoint-events.jsonl"), "utf8");
    assert.match(content, /"errorCode":"workspace_unavailable"/u);
    assert.match(content, /"errorOrigin":"workspace_root"/u);
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
  }
});
