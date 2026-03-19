import assert from "node:assert/strict";
import test from "node:test";

import {
  getModePolicyEntry,
  getModePolicyMatrix,
  getModeRiskPolicyEntry,
  getModeRiskPolicyMatrix,
} from "./mode-policy.js";

test("mode risk matrix encodes the frozen second-wave canonical behavior", () => {
  const matrix = getModeRiskPolicyMatrix();

  assert.equal(matrix.bapr.dangerous, "allow");
  assert.equal(matrix.yolo.risky, "allow");
  assert.equal(matrix.yolo.dangerous, "deny");
  assert.equal(matrix.permissive.risky, "review");
  assert.equal(matrix.standard.dangerous, "human_gate");
  assert.equal(matrix.restricted.normal, "human_gate");
});

test("mode risk policy entry exposes baseline fast-path and default vote semantics", () => {
  const entry = getModeRiskPolicyEntry("standard", "normal");
  assert.equal(entry.decision, "review");
  assert.equal(entry.baselineFastPath, true);
  assert.equal(entry.defaultVote, "defer");

  const dangerousYolo = getModeRiskPolicyEntry("yolo", "dangerous");
  assert.equal(dangerousYolo.decision, "deny");
  assert.equal(dangerousYolo.defaultVote, "deny");
});

test("legacy tier policy matrix remains intact for current runtime compatibility", () => {
  const matrix = getModePolicyMatrix();
  assert.equal(matrix.strict?.B1, "review");
  assert.equal(matrix.strict?.B3, "escalate_to_human");
  assert.equal(matrix.balanced?.B3, "interrupt");
  assert.equal(matrix.yolo?.B1, "allow");

  const entry = getModePolicyEntry("yolo", "B3");
  assert.equal(entry.decision, "interrupt");
  assert.equal(entry.actsAsSafetyAirbag, true);
  assert.equal(entry.requiresHuman, false);
});
