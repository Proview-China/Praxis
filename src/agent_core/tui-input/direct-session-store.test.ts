import assert from "node:assert/strict";
import test from "node:test";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

import {
  buildDirectTuiResumeSelector,
  listDirectTuiAgents,
  listDirectTuiSessions,
  loadDirectTuiSessionSnapshot,
  renameDirectTuiAgent,
  saveDirectTuiAgent,
  renameDirectTuiSession,
  resolveDirectTuiSessionSelection,
  resolveDirectTuiSnapshotTurnIndex,
  restoreDirectTuiDialogueTurnsFromSnapshot,
  saveDirectTuiSessionSnapshot,
} from "./direct-session-store.js";

test("direct session store saves, lists, loads, and renames snapshots", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-session-store-"));
  const workspace = mkdtempSync(join(tmpdir(), "praxis-direct-session-workspace-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    saveDirectTuiSessionSnapshot({
      schemaVersion: 1,
      sessionId: "session-1",
      agentId: "agent.core:main",
      name: "session one",
      workspace,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      compiledInitPreamble: "Project initialization context",
      initArtifactPath: `${workspace}/memory/generated/init-context.md`,
      agents: [],
      messages: [
        {
          messageId: "assistant:1",
          kind: "assistant",
          text: "hello",
          createdAt: "2026-04-14T00:00:01.000Z",
          updatedAt: "2026-04-14T00:00:02.000Z",
          capabilityKey: "core.reply",
          title: "Reply",
          errorCode: "none",
          metadata: {
            source: "tool_summary",
          },
        },
      ],
    }, workspace);

    const listed = listDirectTuiSessions(workspace);
    assert.equal(listed.length, 1);
    assert.equal(listed[0]?.name, "session one");
    assert.equal(listed[0]?.lastAssistantText, "hello");
    assert.equal(existsSync(join(workspace, ".raxode", "sessions", "index.json")), true);

    const loaded = loadDirectTuiSessionSnapshot("session-1", workspace);
    assert.equal(loaded?.sessionId, "session-1");
    assert.equal(loaded?.agentId, "agent.core:main");
    assert.equal(loaded?.messages.length, 1);
    assert.equal(loaded?.messages[0]?.updatedAt, "2026-04-14T00:00:02.000Z");
    assert.equal(loaded?.messages[0]?.capabilityKey, "core.reply");
    assert.deepEqual(loaded?.messages[0]?.metadata, { source: "tool_summary" });
    assert.deepEqual(loaded?.agents, []);
    assert.equal(loaded?.compiledInitPreamble, "Project initialization context");
    assert.equal(loaded?.initArtifactPath, `${workspace}/memory/generated/init-context.md`);

    renameDirectTuiSession("session-1", "renamed session", workspace);
    assert.equal(listDirectTuiSessions(workspace)[0]?.name, "renamed session");
    assert.equal(loadDirectTuiSessionSnapshot("session-1", workspace)?.name, "renamed session");
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspace, { recursive: true, force: true });
  }
});

test("direct session store scopes sessions to the current cwd", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-session-store-scope-home-"));
  const workspaceA = mkdtempSync(join(tmpdir(), "praxis-direct-session-scope-a-"));
  const workspaceB = mkdtempSync(join(tmpdir(), "praxis-direct-session-scope-b-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    saveDirectTuiSessionSnapshot({
      schemaVersion: 1,
      sessionId: "session-a",
      agentId: "agent.core:main",
      name: "alpha",
      workspace: workspaceA,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      agents: [],
      messages: [],
    }, workspaceA);

    assert.equal(listDirectTuiSessions(workspaceA).length, 1);
    assert.equal(listDirectTuiSessions(workspaceB).length, 0);
    assert.equal(loadDirectTuiSessionSnapshot("session-a", workspaceA)?.sessionId, "session-a");
    assert.equal(loadDirectTuiSessionSnapshot("session-a", workspaceB), null);
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspaceA, { recursive: true, force: true });
    rmSync(workspaceB, { recursive: true, force: true });
  }
});

test("direct session store ignores legacy global sessions", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-session-store-legacy-home-"));
  const workspace = mkdtempSync(join(tmpdir(), "praxis-direct-session-legacy-workspace-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    const legacySessionsDir = join(home, "sessions");
    mkdirSync(legacySessionsDir, { recursive: true });
    writeFileSync(join(legacySessionsDir, "direct-tui-index.json"), `${JSON.stringify({
      schemaVersion: 1,
      sessions: [{
        sessionId: "legacy-session",
        name: "legacy",
        workspace,
        route: "https://example.test",
        model: "gpt-5.4",
        createdAt: "2026-04-14T00:00:00.000Z",
        updatedAt: "2026-04-14T00:00:01.000Z",
        messageCount: 0,
      }],
    }, null, 2)}\n`, "utf8");
    writeFileSync(join(legacySessionsDir, "legacy-session.json"), `${JSON.stringify({
      schemaVersion: 1,
      sessionId: "legacy-session",
      agentId: "agent.core:legacy-session",
      name: "legacy",
      workspace,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      selectedAgentId: "agent.core:legacy-session",
      messages: [],
    }, null, 2)}\n`, "utf8");

    assert.deepEqual(listDirectTuiSessions(workspace), []);
    assert.equal(loadDirectTuiSessionSnapshot("legacy-session", workspace), null);
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspace, { recursive: true, force: true });
  }
});

test("direct session store falls back to the current workspace when snapshot workspace is invalid", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-session-store-invalid-"));
  const workspace = mkdtempSync(join(tmpdir(), "praxis-direct-session-invalid-workspace-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    saveDirectTuiSessionSnapshot({
      schemaVersion: 1,
      sessionId: "session-invalid-workspace",
      agentId: "agent.core:main",
      name: "invalid workspace",
      workspace,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      agents: [],
      messages: [],
    }, workspace);

    const snapshotPath = join(workspace, ".raxode", "sessions", "session-invalid-workspace.json");
    writeFileSync(snapshotPath, `${JSON.stringify({
      schemaVersion: 1,
      sessionId: "session-invalid-workspace",
      agentId: "agent.core:main",
      name: "invalid workspace",
      workspace: "/home/proview/[I\ufffd\ufffdgb",
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      agents: [],
      messages: [],
    }, null, 2)}\n`, "utf8");

    const loaded = loadDirectTuiSessionSnapshot("session-invalid-workspace", workspace);
    assert.equal(loaded?.workspace, workspace);
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspace, { recursive: true, force: true });
  }
});

test("direct session selector resolves exact ids, names, and unique prefixes", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-session-select-"));
  const workspace = mkdtempSync(join(tmpdir(), "praxis-direct-session-select-workspace-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    saveDirectTuiSessionSnapshot({
      schemaVersion: 1,
      sessionId: "direct-100",
      agentId: "agent.core:main",
      name: "alpha",
      workspace,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      agents: [],
      messages: [],
    }, workspace);
    saveDirectTuiSessionSnapshot({
      schemaVersion: 1,
      sessionId: "direct-200",
      agentId: "agent.core:main",
      name: "beta",
      workspace,
      route: "https://example.test",
      model: "gpt-5.4",
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:02.000Z",
      agents: [],
      messages: [],
    }, workspace);

    assert.equal(resolveDirectTuiSessionSelection("direct-100", workspace).session?.sessionId, "direct-100");
    assert.equal(resolveDirectTuiSessionSelection("alpha", workspace).session?.sessionId, "direct-100");
    assert.equal(resolveDirectTuiSessionSelection("direct-2", workspace).session?.sessionId, "direct-200");
    assert.equal(resolveDirectTuiSessionSelection("bet", workspace).session?.sessionId, "direct-200");
    assert.equal(resolveDirectTuiSessionSelection("missing", workspace).status, "not_found");
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspace, { recursive: true, force: true });
  }
});

test("resume selector prefers unique simple names and falls back to session id", () => {
  const sessions = [
    { sessionId: "direct-100", name: "alpha" },
    { sessionId: "direct-200", name: "needs spaces" },
    { sessionId: "direct-300", name: "alpha" },
  ];

  assert.equal(buildDirectTuiResumeSelector(sessions[0], [sessions[0]]), "alpha");
  assert.equal(buildDirectTuiResumeSelector(sessions[1], sessions), "direct-200");
  assert.equal(buildDirectTuiResumeSelector(sessions[0], sessions), "direct-100");
});

test("direct agent registry saves, lists, and renames agents", () => {
  const home = mkdtempSync(join(tmpdir(), "praxis-direct-agent-store-"));
  const workspace = mkdtempSync(join(tmpdir(), "praxis-direct-agent-workspace-"));
  const oldHome = process.env.RAXCODE_HOME;
  process.env.RAXCODE_HOME = home;

  try {
    saveDirectTuiAgent({
      agentId: "agent.core:main",
      name: "core",
      kind: "core",
      status: "idle",
      summary: "current direct shell agent",
      workspace,
      createdAt: "2026-04-14T00:00:00.000Z",
      updatedAt: "2026-04-14T00:00:01.000Z",
      lastSessionId: "session-1",
    }, workspace);

    assert.equal(listDirectTuiAgents(workspace)[0]?.name, "core");
    renameDirectTuiAgent("agent.core:main", "renamed core", workspace);
    assert.equal(listDirectTuiAgents(workspace)[0]?.name, "renamed core");
    assert.equal(existsSync(join(workspace, ".raxode", "sessions", "direct-tui-agents.json")), true);
  } finally {
    if (oldHome === undefined) {
      delete process.env.RAXCODE_HOME;
    } else {
      process.env.RAXCODE_HOME = oldHome;
    }
    rmSync(home, { recursive: true, force: true });
    rmSync(workspace, { recursive: true, force: true });
  }
});

test("direct session snapshot restore helpers recover dialogue turns and turn index", () => {
  const snapshot = {
    schemaVersion: 1 as const,
    sessionId: "session-restore",
    agentId: "agent.core:main",
    name: "restore target",
    workspace: "/tmp/workspace",
    route: "https://example.test",
    model: "gpt-5.4",
    createdAt: "2026-04-14T00:00:00.000Z",
    updatedAt: "2026-04-14T00:00:03.000Z",
    agents: [],
    messages: [
      {
        messageId: "status:1",
        kind: "status",
        text: "warming up",
        createdAt: "2026-04-14T00:00:00.000Z",
      },
      {
        messageId: "user:turn-1",
        kind: "user",
        text: "你好",
        createdAt: "2026-04-14T00:00:01.000Z",
        turnId: "turn-1",
      },
      {
        messageId: "assistant:turn-1:1",
        kind: "assistant",
        text: "你好，有什么我可以帮你的？",
        createdAt: "2026-04-14T00:00:02.000Z",
        turnId: "turn-1",
      },
      {
        messageId: "user:turn-2",
        kind: "user",
        text: "继续帮我搜索",
        createdAt: "2026-04-14T00:00:03.000Z",
        turnId: "turn-2",
      },
    ],
  };

  assert.deepEqual(restoreDirectTuiDialogueTurnsFromSnapshot(snapshot), [
    { role: "user", text: "你好" },
    { role: "assistant", text: "你好，有什么我可以帮你的？" },
    { role: "user", text: "继续帮我搜索" },
  ]);
  assert.equal(resolveDirectTuiSnapshotTurnIndex(snapshot), 2);
});
