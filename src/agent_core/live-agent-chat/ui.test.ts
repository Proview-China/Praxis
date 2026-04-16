import assert from "node:assert/strict";
import test from "node:test";

import {
  formatDirectCmpSnapshotLines,
  formatDirectCmpWorksiteSnapshotLines,
  formatDirectMpSnapshotLines,
} from "./ui.js";

test("formatDirectMpSnapshotLines renders live MP snapshot details instead of placeholder text", () => {
  const lines = formatDirectMpSnapshotLines({
    summaryLines: [
      "LanceDB-backed MP memory records are available.",
      "source=lancedb · /tmp/mp-cache",
      "2 memory records",
    ],
    status: "ready",
    sourceKind: "lancedb",
    sourceClass: "lancedb",
    rootPath: "/tmp/mp-cache",
    recordCount: 2,
    routingLines: [
      "delivery_status=available source_class=cmp_seeded_memory",
      "current_objective=continue payment refactor",
      "candidate_intake=2 rejected=1",
      "fallback_suppressed=true stage=none",
    ],
    entries: [
      {
        memoryId: "memory:1",
        label: "overlay:worklog",
        summary: "overlay:worklog / record one",
        agentId: "main",
        scopeLevel: "project",
      },
    ],
  });

  assert.match(lines.join("\n"), /LanceDB-backed MP memory records are available\./u);
  assert.match(lines.join("\n"), /source=lancedb\/lancedb/u);
  assert.match(lines.join("\n"), /route: delivery_status=available source_class=cmp_seeded_memory/u);
  assert.match(lines.join("\n"), /route: fallback_suppressed=true stage=none/u);
  assert.match(lines.join("\n"), /memory:1/u);
  assert.doesNotMatch(lines.join("\n"), /not wired into the direct CLI yet/u);
});

test("formatDirectMpSnapshotLines surfaces empty reason when no records exist", () => {
  const lines = formatDirectMpSnapshotLines({
    summaryLines: ["MP snapshot unavailable"],
    status: "empty",
    sourceKind: "repo_memory_fallback",
    sourceClass: "repo_memory_fallback",
    emptyReason: "No MP memory records are available in the current LanceDB or fallback snapshot.",
    entries: [],
  });

  assert.match(lines.join("\n"), /No MP memory records are available/u);
});

test("formatDirectCmpSnapshotLines renders live CMP snapshot even without latest turn artifacts", () => {
  const lines = formatDirectCmpSnapshotLines({
    summaryLines: [
      "1 DB-backed sections tracked",
      "persisted:1",
      "db=ready readback=ready",
    ],
    status: "ready",
    sourceKind: "cmp_readback",
    truthStatus: "ready",
    readbackStatus: "ready",
    requestLines: [
      "worksite: delivery=available, package=cmp-package:worksite-1, family=family-1, turn=4",
      "bridge: candidates=2, policy=checked_governed_package_grade, snapshot=snapshot-1",
    ],
    entries: [
      {
        sectionId: "section-1",
        lifecycle: "persisted",
        kind: "historical_context",
        agentId: "cmp-live-cli-main",
        ref: "stored:postgresql:section-1",
        updatedAt: "2026-04-16T00:00:00.000Z",
      },
    ],
  });

  assert.match(lines.join("\n"), /db=ready readback=ready/u);
  assert.match(lines.join("\n"), /worksite: delivery=available/u);
  assert.match(lines.join("\n"), /bridge: candidates=2/u);
  assert.match(lines.join("\n"), /persisted · historical_context · cmp-live-cli-main/u);
  assert.doesNotMatch(lines.join("\n"), /还没有 CMP 结果/u);
});

test("formatDirectCmpSnapshotLines keeps latest cmp turn as secondary context", () => {
  const lines = formatDirectCmpSnapshotLines({
    summaryLines: [
      "0 DB-backed sections tracked",
      "No section lifecycle data yet",
      "db=ready readback=ready",
    ],
    status: "empty",
    sourceKind: "cmp_readback",
    truthStatus: "ready",
    readbackStatus: "ready",
    emptyReason: "CMP DB truth is healthy but there are no materialized section records to show yet.",
    entries: [],
  }, {
    syncStatus: "synced",
    agentId: "cmp-live-cli-main",
    packageId: "pkg-1",
    packageRef: "cmp-package:pkg-1",
    projectionId: "projection-1",
    snapshotId: "snapshot-1",
    summary: {
      live: {
        icma: "active",
        iterator: "idle",
        checker: "idle",
        dbagent: "idle",
        dispatcher: "idle",
      },
    } as never,
    intent: "intent",
    operatorGuide: "guide",
    childGuide: "child-guide",
    checkerReason: "checker",
    routeRationale: "route via cmp",
    scopePolicy: "historical_reply_returns_via_core_path",
    packageStrategy: "active",
    timelineStrategy: "timeline",
  });

  assert.match(lines.join("\n"), /latest cmp turn:/u);
  assert.match(lines.join("\n"), /cmp-package:pkg-1/u);
  assert.match(lines.join("\n"), /route via cmp/u);
});

test("formatDirectCmpWorksiteSnapshotLines keeps only the focused worksite and bridge lines", () => {
  const lines = formatDirectCmpWorksiteSnapshotLines({
    summaryLines: ["CMP summary"],
    status: "ready",
    sourceKind: "cmp_readback",
    requestLines: [
      "requests: peerPending=1, peerApproved=0, reinterventionPending=0, reinterventionServed=0",
      "worksite: delivery=available, package=cmp-package:worksite-1, family=family-1, turn=4",
      "orchestration: review=parent review 1, unresolved=pending peer approvals=1, route=core_agent_return",
      "bridge: candidates=2, policy=checked_governed_package_grade, snapshot=snapshot-1",
    ],
    entries: [],
  });

  assert.equal(lines.length, 4);
  assert.match(lines[0] ?? "", /requests:/u);
  assert.match(lines[1] ?? "", /worksite:/u);
  assert.match(lines[2] ?? "", /orchestration:/u);
  assert.match(lines[3] ?? "", /bridge:/u);
});
