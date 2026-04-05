import assert from "node:assert/strict";
import test from "node:test";

import { createAgentLineage, createCmpBranchFamily } from "./index.js";
import { createAgentCoreRuntime } from "./runtime.js";

test("AgentCoreRuntime exposes async CMP five-agent live wrappers without mutating the sync mainline", async () => {
  const runtime = createAgentCoreRuntime();

  const icma = await runtime.captureCmpIcmaWithLlm({
    ingest: {
      agentId: "main-live-runtime",
      sessionId: "session-live-runtime",
      taskSummary: "live wrapper ingress",
      materials: [{ kind: "user_input", ref: "payload:live:user" }],
      lineage: createAgentLineage({
        agentId: "main-live-runtime",
        depth: 0,
        projectId: "cmp-live-runtime",
        branchFamily: createCmpBranchFamily({
          workBranch: "work/main-live-runtime",
          cmpBranch: "cmp/main-live-runtime",
          mpBranch: "mp/main-live-runtime",
          tapBranch: "tap/main-live-runtime",
        }),
      }),
    },
    createdAt: "2026-03-31T00:00:00.000Z",
    loopId: "cmp-live-runtime-icma",
  }, {
    mode: "llm_assisted",
    executor: async () => ({
      output: {
        intent: "live wrapper ingress intent",
        sourceAnchorRefs: ["payload:live:user"],
        candidateBodyRefs: ["payload:live:user"],
        boundary: "preserve_root_system_and_emit_controlled_fragments_only",
        operatorGuide: "operator live",
        childGuide: "child live",
      },
      provider: "openai",
      model: "gpt-5.4",
      requestId: "runtime-live-icma",
    }),
  });

  const checker = await runtime.evaluateCmpCheckerWithLlm({
    agentId: "main-live-runtime",
    candidateId: "candidate-live-runtime",
    checkedSnapshotId: "snapshot-live-runtime",
    checkedAt: "2026-03-31T00:00:01.000Z",
    suggestPromote: false,
    metadata: {
      sourceSectionIds: ["section-pre-runtime"],
      checkedSectionIds: ["section-checked-runtime"],
    },
  }, {
    mode: "llm_assisted",
    executor: async () => ({
      output: {
        sourceSectionIds: ["section-pre-runtime"],
        checkedSectionIds: ["section-checked-runtime"],
        splitDecisionRefs: ["split-runtime"],
        mergeDecisionRefs: ["merge-runtime"],
        trimSummary: "runtime live checker trimmed context",
        shortReason: "runtime live checker ready",
        detailedReason: "runtime live checker kept only task-relevant evidence",
      },
      provider: "openai",
      model: "gpt-5.4",
      requestId: "runtime-live-checker",
    }),
  });

  assert.equal(icma.loop.liveTrace?.status, "live_applied");
  assert.equal(icma.loop.structuredOutput.intent, "live wrapper ingress intent");
  assert.equal(checker.checkerRecord.liveTrace?.status, "live_applied");
  assert.equal(checker.checkerRecord.reviewOutput.trimSummary, "runtime live checker trimmed context");

  const summary = runtime.getCmpFiveAgentRuntimeSummary("main-live-runtime");
  assert.equal(summary.live.icma.status, "succeeded");
  assert.equal(summary.live.checker.status, "succeeded");
});
