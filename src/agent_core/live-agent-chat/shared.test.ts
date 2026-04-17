import assert from "node:assert/strict";
import test from "node:test";

import { parseTapRequest } from "./shared.js";

test("parseTapRequest keeps shell.restricted command syntax compatible", () => {
  const parsed = parseTapRequest([
    "[TAP REQUEST]",
    "capability: shell.restricted",
    "requestedTier: B2",
    "reason: run a bounded shell request",
    "command: git status --short",
    "cwd: memory/generated/tap-debug/git-commit-repo",
  ].join("\n"));

  assert.ok(parsed);
  assert.equal(parsed?.capabilityKey, "shell.restricted");
  assert.equal(parsed?.requestedTier, "B2");
  assert.equal(parsed?.reason, "run a bounded shell request");
  assert.equal(parsed?.input.cwd, "memory/generated/tap-debug/git-commit-repo");
  assert.equal(parsed?.input.command, "zsh");
});

test("parseTapRequest accepts generic JSON input blocks for missing capability probes", () => {
  const parsed = parseTapRequest([
    "[TAP REQUEST]",
    "capability: tap.provision.probe",
    "requestedTier: B2",
    "reason: trigger provisioning probe",
    "timeoutMs: 45000",
    "input:",
    "{",
    '  "task": "stabilize provisioning probe lane",',
    '  "target": "computer.use"',
    "}",
  ].join("\n"));

  assert.ok(parsed);
  assert.equal(parsed?.capabilityKey, "tap.provision.probe");
  assert.equal(parsed?.requestedTier, "B2");
  assert.equal(parsed?.reason, "trigger provisioning probe");
  assert.equal(parsed?.input.timeoutMs, 45000);
  assert.equal(parsed?.input.task, "stabilize provisioning probe lane");
  assert.equal(parsed?.input.target, "computer.use");
});
