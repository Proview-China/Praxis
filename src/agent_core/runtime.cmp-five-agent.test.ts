import assert from "node:assert/strict";
import test from "node:test";

import { createAgentLineage, createCmpBranchFamily } from "./index.js";
import { createAgentCoreRuntime } from "./runtime.js";

test("AgentCoreRuntime can orchestrate a CMP five-agent active live loop through the unified async wrapper", async () => {
  const runtime = createAgentCoreRuntime();

  const result = await runtime.runCmpFiveAgentActiveLiveLoop({
    icma: {
      input: {
        ingest: {
          agentId: "main-runtime-loop",
          sessionId: "session-runtime-loop",
          taskSummary: "runtime active live loop task",
          materials: [{ kind: "user_input", ref: "payload:runtime:loop:user" }],
          lineage: createAgentLineage({
            agentId: "main-runtime-loop",
            depth: 0,
            projectId: "cmp-runtime-live-loop",
            branchFamily: createCmpBranchFamily({
              workBranch: "work/main-runtime-loop",
              cmpBranch: "cmp/main-runtime-loop",
              mpBranch: "mp/main-runtime-loop",
              tapBranch: "tap/main-runtime-loop",
            }),
          }),
        },
        createdAt: "2026-03-31T00:20:00.000Z",
        loopId: "runtime-loop-icma",
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            intent: "runtime active live loop intent",
            sourceAnchorRefs: ["payload:runtime:loop:user"],
            candidateBodyRefs: ["payload:runtime:loop:user"],
            boundary: "preserve_root_system_and_emit_controlled_fragments_only",
            operatorGuide: "runtime operator loop",
            childGuide: "runtime child loop",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-loop-icma",
        }),
      },
    },
    iterator: {
      input: {
        agentId: "main-runtime-loop",
        deltaId: "runtime-loop-delta",
        candidateId: "runtime-loop-candidate",
        branchRef: "refs/heads/cmp/main-runtime-loop",
        commitRef: "runtime-loop-commit",
        reviewRef: "refs/cmp/review/runtime-loop-candidate",
        createdAt: "2026-03-31T00:20:01.000Z",
        metadata: {
          sourceSectionIds: ["section-pre-runtime-loop"],
        },
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            sourceSectionIds: ["section-pre-runtime-loop"],
            commitRationale: "runtime loop iterator rationale",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-loop-iterator",
        }),
      },
    },
    checker: {
      input: {
        agentId: "main-runtime-loop",
        candidateId: "runtime-loop-candidate",
        checkedSnapshotId: "runtime-loop-snapshot",
        checkedAt: "2026-03-31T00:20:02.000Z",
        suggestPromote: false,
        metadata: {
          sourceSectionIds: ["section-pre-runtime-loop"],
          checkedSectionIds: ["section-checked-runtime-loop"],
        },
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            sourceSectionIds: ["section-pre-runtime-loop"],
            checkedSectionIds: ["section-checked-runtime-loop"],
            splitDecisionRefs: ["split-runtime-loop"],
            mergeDecisionRefs: ["merge-runtime-loop"],
            trimSummary: "runtime loop checker trim",
            shortReason: "runtime loop checker short reason",
            detailedReason: "runtime loop checker detailed reason",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-loop-checker",
        }),
      },
    },
    dbagent: {
      input: {
        checkedSnapshot: {
          snapshotId: "runtime-loop-snapshot",
          agentId: "main-runtime-loop",
          lineageRef: "lineage:main-runtime-loop",
          branchRef: "refs/heads/cmp/main-runtime-loop",
          commitRef: "runtime-loop-commit",
          checkedAt: "2026-03-31T00:20:03.000Z",
          qualityLabel: "usable",
          promotable: true,
        },
        projectionId: "runtime-loop-projection",
        contextPackage: {
          packageId: "runtime-loop-package",
          sourceProjectionId: "runtime-loop-projection",
          targetAgentId: "child-runtime-loop",
          packageKind: "child_seed",
          packageRef: "cmp-package:runtime-loop-snapshot:child-runtime-loop:child_seed",
          fidelityLabel: "checked_high_fidelity",
          createdAt: "2026-03-31T00:20:03.000Z",
        },
        createdAt: "2026-03-31T00:20:03.000Z",
        loopId: "runtime-loop-dbagent",
        metadata: {
          sourceRequestId: "runtime-loop-request",
          sourceSectionIds: ["section-checked-runtime-loop"],
        },
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            packageTopology: "active_plus_timeline_plus_task_snapshots",
            bundleSchemaVersion: "cmp-dispatch-bundle/v1",
            materializationRationale: "runtime loop dbagent rationale",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-loop-dbagent",
        }),
      },
    },
    dispatcher: {
      input: {
        contextPackage: {
          packageId: "runtime-loop-package",
          sourceProjectionId: "runtime-loop-projection",
          targetAgentId: "child-runtime-loop",
          packageKind: "child_seed",
          packageRef: "cmp-package:runtime-loop-snapshot:child-runtime-loop:child_seed",
          fidelityLabel: "checked_high_fidelity",
          createdAt: "2026-03-31T00:20:04.000Z",
        },
        dispatch: {
          agentId: "main-runtime-loop",
          packageId: "runtime-loop-package",
          sourceAgentId: "main-runtime-loop",
          targetAgentId: "child-runtime-loop",
          targetKind: "child",
          metadata: {
            sourceRequestId: "runtime-loop-request",
            sourceSnapshotId: "runtime-loop-snapshot",
          },
        },
        receipt: {
          dispatchId: "runtime-loop-dispatch",
          packageId: "runtime-loop-package",
          sourceAgentId: "main-runtime-loop",
          targetAgentId: "child-runtime-loop",
          status: "delivered",
          deliveredAt: "2026-03-31T00:20:04.000Z",
        },
        createdAt: "2026-03-31T00:20:04.000Z",
        loopId: "runtime-loop-dispatcher",
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            routeRationale: "runtime loop dispatcher rationale",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-loop-dispatcher",
        }),
      },
    },
  });

  assert.equal(result.icma.loop.liveTrace?.status, "live_applied");
  assert.equal(result.iterator.liveTrace?.status, "live_applied");
  assert.equal(result.checker.checkerRecord.liveTrace?.status, "live_applied");
  assert.equal(result.dbagent.loop.liveTrace?.status, "live_applied");
  assert.equal(result.dispatcher.loop.liveTrace?.status, "live_applied");
  assert.equal(result.summary.live.dispatcher.status, "succeeded");
});

test("AgentCoreRuntime can orchestrate a CMP five-agent passive live loop through the unified async wrapper", async () => {
  const runtime = createAgentCoreRuntime();

  const result = await runtime.runCmpFiveAgentPassiveLiveLoop({
    dbagent: {
      input: {
        loopId: "runtime-passive-dbagent",
        request: {
          requesterAgentId: "child-runtime-passive",
          projectId: "cmp-runtime-passive",
          reason: "need historical context",
          query: {
            snapshotId: "runtime-passive-snapshot",
          },
        },
        snapshot: {
          snapshotId: "runtime-passive-snapshot",
          agentId: "child-runtime-passive",
          lineageRef: "lineage:child-runtime-passive",
          branchRef: "refs/heads/cmp/child-runtime-passive",
          commitRef: "runtime-passive-commit",
          checkedAt: "2026-03-31T00:40:00.000Z",
          qualityLabel: "usable",
          promotable: false,
        },
        contextPackage: {
          packageId: "runtime-passive-package",
          sourceProjectionId: "runtime-passive-projection",
          targetAgentId: "child-runtime-passive",
          packageKind: "historical_reply",
          packageRef: "cmp-package:runtime-passive-snapshot:child-runtime-passive:historical_reply",
          fidelityLabel: "checked_high_fidelity",
          createdAt: "2026-03-31T00:40:00.000Z",
        },
        createdAt: "2026-03-31T00:40:00.000Z",
        metadata: {
          sourceRequestId: "runtime-passive-request",
          sourceSectionIds: ["runtime-passive-section"],
        },
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            packageTopology: "passive_reply_plus_timeline_plus_task_snapshots",
            bundleSchemaVersion: "cmp-dispatch-bundle/v1",
            materializationRationale: "runtime passive dbagent rationale",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-passive-dbagent",
        }),
      },
    },
    dispatcher: {
      input: {
        loopId: "runtime-passive-dispatcher",
        request: {
          requesterAgentId: "child-runtime-passive",
          projectId: "cmp-runtime-passive",
          reason: "need historical context",
          query: {
            snapshotId: "runtime-passive-snapshot",
          },
        },
        contextPackage: {
          packageId: "runtime-passive-package",
          sourceProjectionId: "runtime-passive-projection",
          targetAgentId: "child-runtime-passive",
          packageKind: "historical_reply",
          packageRef: "cmp-package:runtime-passive-snapshot:child-runtime-passive:historical_reply",
          fidelityLabel: "checked_high_fidelity",
          createdAt: "2026-03-31T00:40:01.000Z",
        },
        createdAt: "2026-03-31T00:40:01.000Z",
      },
      options: {
        mode: "llm_assisted",
        executor: async () => ({
          output: {
            routeRationale: "runtime passive dispatcher rationale",
          },
          provider: "openai",
          model: "gpt-5.4",
          requestId: "runtime-passive-dispatcher",
        }),
      },
    },
  });

  assert.equal(result.dbagent.loop.liveTrace?.status, "live_applied");
  assert.equal(result.dispatcher.liveTrace?.status, "live_applied");
  assert.equal(result.dispatcher.bundle.governance.routeRationale, "runtime passive dispatcher rationale");
  assert.equal(result.summary.live.dispatcher.status, "succeeded");
});
