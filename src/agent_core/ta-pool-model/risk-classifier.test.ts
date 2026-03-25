import assert from "node:assert/strict";
import test from "node:test";

import { classifyCapabilityRisk } from "./risk-classifier.js";

test("risk classifier keeps ordinary repo reads at normal risk", () => {
  const result = classifyCapabilityRisk({
    capabilityKey: "docs.read",
    requestedTier: "B0",
  });

  assert.equal(result.riskLevel, "normal");
  assert.equal(result.reason, "default_normal");
});

test("risk classifier marks broad control surfaces as risky", () => {
  const result = classifyCapabilityRisk({
    capabilityKey: "mcp.playwright",
    requestedTier: "B1",
  });

  assert.equal(result.riskLevel, "risky");
  assert.equal(result.reason, "risky_pattern");
  assert.equal(result.matchedPattern, "mcp.playwright");
});

test("risk classifier treats packaged MCP execution surfaces as risky by default", () => {
  const callResult = classifyCapabilityRisk({
    capabilityKey: "mcp.call",
    requestedTier: "B1",
  });
  const nativeExecuteResult = classifyCapabilityRisk({
    capabilityKey: "mcp.native.execute",
    requestedTier: "B2",
  });

  assert.equal(callResult.riskLevel, "risky");
  assert.equal(callResult.matchedPattern, "mcp.call");
  assert.equal(nativeExecuteResult.riskLevel, "risky");
  assert.equal(nativeExecuteResult.matchedPattern, "mcp.native.execute");
});

test("risk classifier marks destructive operations as dangerous", () => {
  const result = classifyCapabilityRisk({
    capabilityKey: "shell.rm.force",
    requestedTier: "B2",
  });

  assert.equal(result.riskLevel, "dangerous");
  assert.equal(result.reason, "dangerous_pattern");
  assert.equal(result.matchedPattern, "shell.rm*");
});

test("risk classifier treats unmatched B3 requests as risky instead of dangerous", () => {
  const result = classifyCapabilityRisk({
    capabilityKey: "docs.read",
    requestedTier: "B3",
  });

  assert.equal(result.riskLevel, "risky");
  assert.equal(result.reason, "critical_tier");
});
