import assert from "node:assert/strict";
import test from "node:test";

import { createAgentCapabilityProfile } from "../ta-pool-types/ta-pool-profile.js";
import {
  createTapGovernanceObject,
  instantiateTapGovernanceObject,
  listShared15ViewMatrix,
} from "./governance-object.js";

test("shared 15-view matrix helper returns the frozen 5x3 cells", () => {
  const matrix = listShared15ViewMatrix();

  assert.equal(matrix.length, 15);
  assert.equal(matrix.some((cell) => cell.mode === "standard" && cell.riskLevel === "normal"), true);
});

test("tap governance object materializes the shared 15-view matrix", () => {
  const governance = createTapGovernanceObject({
    profile: createAgentCapabilityProfile({
      profileId: "profile.tap-governance",
      agentClass: "main-agent",
      defaultMode: "standard",
      baselineCapabilities: ["docs.read"],
    }),
  });

  assert.equal(governance.shared15ViewMatrix.length, 15);
  assert.equal(
    governance.shared15ViewMatrix.some((cell) =>
      cell.mode === "restricted" && cell.riskLevel === "dangerous" && cell.requiresHumanGate),
    true,
  );
  assert.equal(
    governance.shared15ViewMatrix.some((cell) =>
      cell.mode === "bapr" && cell.riskLevel === "dangerous" && cell.tmaLane === "extended"),
    true,
  );
});

test("tap governance object applies workspace, task, and user override layers", () => {
  const governance = createTapGovernanceObject({
    profile: createAgentCapabilityProfile({
      profileId: "profile.tap-governance-overrides",
      agentClass: "main-agent",
      defaultMode: "balanced",
      baselineCapabilities: ["docs.read"],
    }),
    workspaceMode: "standard",
    taskMode: "restricted",
    userOverride: {
      requestedMode: "yolo",
      automationDepth: "prefer_human",
      requireHumanOnRiskLevels: ["dangerous", "risky"],
      toolPolicyOverrides: [
        {
          capabilitySelector: "mcp.*",
          policy: "review_only",
        },
      ],
      explanationStyle: "plain_language",
    },
  });

  assert.equal(governance.workspacePolicy.canonicalWorkspaceMode, "standard");
  assert.equal(governance.taskPolicy.canonicalTaskMode, "restricted");
  assert.equal(governance.taskPolicy.effectiveMode, "yolo");
  assert.equal(governance.userSurface.automationDepth, "prefer_human");
  assert.deepEqual(governance.userSurface.requiresHumanOnRiskLevels, ["dangerous", "risky"]);
  assert.equal(governance.taskPolicy.toolPolicyOverrides[0]?.capabilitySelector, "mcp.*");
});

test("tap governance object derives tier snapshots from the effective mode", () => {
  const governance = createTapGovernanceObject({
    profile: createAgentCapabilityProfile({
      profileId: "profile.tap-governance-tier",
      agentClass: "main-agent",
      defaultMode: "standard",
    }),
    userOverride: {
      requestedMode: "restricted",
    },
  });

  assert.equal(governance.tierSnapshots.length, 4);
  assert.equal(governance.tierSnapshots.find((entry) => entry.tier === "B1")?.entry.decision, "escalate_to_human");
  assert.equal(governance.tierSnapshots.find((entry) => entry.tier === "B0")?.entry.decision, "allow");
});

test("tap governance object can instantiate a task-scoped governance object", () => {
  const governance = createTapGovernanceObject({
    objectId: "tap-governance:workspace",
    profile: createAgentCapabilityProfile({
      profileId: "profile.tap-governance-task",
      agentClass: "main-agent",
      defaultMode: "standard",
    }),
  });

  const taskScoped = instantiateTapGovernanceObject({
    governance,
    taskId: "task-1",
    requestedMode: "permissive",
    userOverride: {
      requestedMode: "permissive",
      automationDepth: "prefer_auto",
    },
  });

  assert.equal(taskScoped.objectId, "tap-governance:workspace:task-1");
  assert.equal(taskScoped.taskPolicy.effectiveMode, "permissive");
  assert.equal(taskScoped.taskPolicy.automationDepth, "prefer_auto");
});
