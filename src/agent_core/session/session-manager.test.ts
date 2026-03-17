import assert from "node:assert/strict";
import test from "node:test";

import { SessionManager } from "./session-manager.js";

function createManager() {
  let ticks = 0;
  return new SessionManager({
    clock: {
      now: () => new Date(`2026-03-17T12:00:0${ticks++}.000Z`)
    },
    idFactory: {
      createSessionId: () => "session-1",
      createColdLogRef: (sessionId) => `cold:${sessionId}:1`
    }
  });
}

test("create/load/update session header works", () => {
  const manager = createManager();
  const created = manager.createSession({
    metadata: { owner: "tester" }
  });

  assert.equal(created.sessionId, "session-1");
  assert.equal(created.status, "idle");
  assert.deepEqual(created.runIds, []);
  assert.equal(created.version, 1);

  const loaded = manager.loadSessionHeader("session-1");
  assert.equal(loaded?.metadata?.owner, "tester");

  const updated = manager.updateSessionHeader("session-1", {
    status: "paused",
    metadata: { purpose: "manual-check" }
  });

  assert.equal(updated.status, "paused");
  assert.equal(updated.version, 2);
  assert.equal(updated.metadata?.owner, "tester");
  assert.equal(updated.metadata?.purpose, "manual-check");
});

test("attachRun and setActiveRun keep active run routing stable", () => {
  const manager = createManager();
  manager.createSession();

  const attached = manager.attachRun({
    sessionId: "session-1",
    runId: "run-1",
    makeActive: true
  });

  assert.deepEqual(attached.runIds, ["run-1"]);
  assert.equal(attached.activeRunId, "run-1");
  assert.equal(attached.status, "active");

  const switched = manager.setActiveRun("session-1", "run-2");
  assert.deepEqual(switched.runIds, ["run-1", "run-2"]);
  assert.equal(switched.activeRunId, "run-2");
  assert.equal(switched.status, "active");

  const cleared = manager.setActiveRun("session-1", undefined);
  assert.equal(cleared.activeRunId, undefined);
  assert.equal(cleared.status, "idle");
});

test("markCheckpoint updates checkpoint and journal cursor refs", () => {
  const manager = createManager();
  manager.createSession();

  const marked = manager.markCheckpoint({
    sessionId: "session-1",
    checkpointId: "cp-1",
    journalCursor: "journal:0:4"
  });

  assert.equal(marked.lastCheckpointRef, "cp-1");
  assert.equal(marked.lastJournalCursor, "journal:0:4");
});

test("eviction moves session header to cold log without keeping hot copy", () => {
  const manager = createManager();
  manager.createSession({
    activeRunId: "run-1",
    runIds: ["run-1"]
  });

  const eviction = manager.evictSession("session-1");
  assert.equal(eviction.coldLogRef, "cold:session-1:1");
  assert.equal(manager.hasHotSession("session-1"), false);
  assert.equal(manager.hasColdSession("session-1"), true);

  const cold = manager.readColdLog("session-1");
  assert.equal(cold?.header.coldLogRef, "cold:session-1:1");
  assert.equal(cold?.header.status, "archived");
  assert.equal(cold?.header.activeRunId, undefined);
});

test("loadSessionHeader lazily restores session header from cold log", () => {
  const manager = createManager();
  manager.createSession({
    runIds: ["run-1"],
    lastCheckpointRef: "cp-9",
    lastJournalCursor: "journal:2:8"
  });
  manager.evictSession("session-1");

  const restored = manager.loadSessionHeader("session-1");
  assert.equal(restored?.sessionId, "session-1");
  assert.equal(restored?.coldLogRef, "cold:session-1:1");
  assert.equal(restored?.lastCheckpointRef, "cp-9");
  assert.equal(restored?.lastJournalCursor, "journal:2:8");
  assert.equal(manager.hasHotSession("session-1"), true);
});
