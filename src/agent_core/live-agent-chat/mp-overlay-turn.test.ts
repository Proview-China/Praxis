import assert from "node:assert/strict";
import test from "node:test";

import type { LiveMpOverlayRefreshStateLike } from "./mp-overlay-turn.js";
import { readCmpMpCandidatePayloads, refreshLiveMpOverlayForTurn } from "./mp-overlay-turn.js";

test("readCmpMpCandidatePayloads returns undefined when CMP worksite has no exporter", () => {
  const result = readCmpMpCandidatePayloads({
    sessionId: "session-1",
    runtime: {
      cmp: {
        worksite: {
          exportCorePackage() {
            return {};
          },
        },
      },
    },
  }, "continue payment worksite");

  assert.equal(result, undefined);
});

test("refreshLiveMpOverlayForTurn reroutes MP per turn with current objective worksite and CMP candidates", async () => {
  const observedCalls: Array<Record<string, unknown>> = [];
  const state: LiveMpOverlayRefreshStateLike = {
    sessionId: "session-42",
    runtime: {
      cmp: {
        worksite: {
          exportCorePackage(input: { sessionId: string; currentObjective?: string }) {
            observedCalls.push({ kind: "exportCorePackage", ...input });
            return {
              schemaVersion: "core-cmp-worksite-package/v1",
              deliveryStatus: "available",
              identity: {
                sessionId: input.sessionId,
                agentId: "cmp-main",
                packageRef: "cmp-worksite:42",
              },
              objective: {
                currentObjective: input.currentObjective,
                taskSummary: "keep payment refactor worksite aligned",
              },
            };
          },
          exportMpCandidates(input: {
            sessionId: string;
            currentObjective?: string;
            limit?: number;
          }) {
            observedCalls.push({ kind: "exportMpCandidates", ...input });
            return {
              schemaVersion: "cmp-mp-candidate-export/v1",
              candidates: [{
                storedSection: {
                  storedSectionId: "stored-1",
                },
                checkedSnapshotRef: "snapshot-1",
                branchRef: "mp/main",
                scope: {
                  projectId: "proj-1",
                  agentId: "main",
                  scopeLevel: "project",
                  sessionMode: "shared",
                },
                confidence: "high",
              }],
            };
          },
        },
      },
    },
  };

  await refreshLiveMpOverlayForTurn(
    state,
    "/tmp/praxis-workspace",
    "continue payment refactor",
    {
      discoverMpOverlayArtifactsImpl: async (input) => {
        observedCalls.push({
          kind: "discover",
          cwd: input.cwd,
          userMessage: input.userMessage,
          currentObjective: input.currentObjective,
          cmpWorksitePackage: input.cmpWorksitePackage,
          cmpCandidatePayloads: input.cmpCandidatePayloads,
        });
        return {
          entries: [{
            id: "memory:payment-1",
            label: "payment-refactor",
            summary: "summary / fresh / aligned / high",
          }],
          routedPackage: {
            schemaVersion: "core-mp-routed-package/v2",
            deliveryStatus: "available",
            packageId: "mp-route:payment",
            sourceClass: "cmp_seeded_memory",
            summary: "MP routed payment memories.",
          },
        };
      },
    },
  );

  assert.equal(state.memoryOverlayEntries?.[0]?.id, "memory:payment-1");
  assert.equal(state.mpRoutedPackage?.packageId, "mp-route:payment");
  const discoverCall = observedCalls.find((entry) => entry.kind === "discover");
  assert.equal(discoverCall?.currentObjective, "continue payment refactor");
  assert.equal(
    (discoverCall?.cmpWorksitePackage as { objective?: { taskSummary?: string } })?.objective?.taskSummary,
    "keep payment refactor worksite aligned",
  );
  assert.equal(
    (discoverCall?.cmpCandidatePayloads as { schemaVersion?: string })?.schemaVersion,
    "cmp-mp-candidate-export/v1",
  );
});

test("refreshLiveMpOverlayForTurn keeps rerouting across multiple objectives in one session", async () => {
  const observedObjectives: string[] = [];
  const state: LiveMpOverlayRefreshStateLike = {
    sessionId: "session-99",
    runtime: {
      cmp: {
        worksite: {
          exportCorePackage(input: { sessionId: string; currentObjective?: string }) {
            return {
              schemaVersion: "core-cmp-worksite-package/v1",
              deliveryStatus: "available",
              identity: {
                sessionId: input.sessionId,
                agentId: "cmp-main",
                packageRef: `cmp-worksite:${input.currentObjective}`,
              },
              objective: {
                currentObjective: input.currentObjective,
              },
            };
          },
          exportMpCandidates(input: {
            currentObjective?: string;
          }) {
            return {
              schemaVersion: "cmp-mp-candidate-export/v1",
              currentObjective: input.currentObjective,
              candidates: [],
            };
          },
        },
      },
    },
  };

  await refreshLiveMpOverlayForTurn(
    state,
    "/tmp/praxis-workspace",
    "objective one",
    {
      discoverMpOverlayArtifactsImpl: async (input) => {
        observedObjectives.push(String(input.currentObjective));
        return {
          entries: [{
            id: `memory:${input.currentObjective}`,
            label: String(input.currentObjective),
            summary: "summary / fresh / aligned / high",
          }],
          routedPackage: {
            schemaVersion: "core-mp-routed-package/v2",
            deliveryStatus: "available",
            packageId: `mp-route:${input.currentObjective}`,
            sourceClass: "mp_native_resolve",
            summary: `MP routed ${input.currentObjective}.`,
          },
        };
      },
    },
  );

  await refreshLiveMpOverlayForTurn(
    state,
    "/tmp/praxis-workspace",
    "objective two",
    {
      discoverMpOverlayArtifactsImpl: async (input) => {
        observedObjectives.push(String(input.currentObjective));
        return {
          entries: [{
            id: `memory:${input.currentObjective}`,
            label: String(input.currentObjective),
            summary: "summary / fresh / aligned / high",
          }],
          routedPackage: {
            schemaVersion: "core-mp-routed-package/v2",
            deliveryStatus: "available",
            packageId: `mp-route:${input.currentObjective}`,
            sourceClass: "mp_native_resolve",
            summary: `MP routed ${input.currentObjective}.`,
          },
        };
      },
    },
  );

  assert.deepEqual(observedObjectives, ["objective one", "objective two"]);
  assert.equal(state.memoryOverlayEntries?.[0]?.id, "memory:objective two");
  assert.equal(state.mpRoutedPackage?.packageId, "mp-route:objective two");
});
