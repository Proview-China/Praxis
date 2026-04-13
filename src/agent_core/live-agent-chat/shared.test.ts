import assert from "node:assert/strict";
import test from "node:test";

import {
  applyCliDefaultsToCapabilityRequest,
  normalizeCoreTaskStatus,
  parseCliOptions,
  parseCoreActionEnvelope,
  parseTapRequest,
  shouldStopCoreCapabilityLoop,
} from "./shared.js";
import type { OpenAILiveConfig } from "./shared.js";

const TEST_CONFIG = {
  apiKey: "test-openai-key",
  baseURL: "https://api.example.com/v1",
  model: "gpt-5.4",
} satisfies OpenAILiveConfig;

test("parseCliOptions reads once, history-turns, and direct ui mode", () => {
  const options = parseCliOptions([
    "--once",
    "hello",
    "--history-turns",
    "9",
    "--ui",
    "direct",
  ]);

  assert.deepEqual(options, {
    once: "hello",
    historyTurns: 9,
    uiMode: "direct",
  });
});

test("parseCoreActionEnvelope parses reply and capability_call envelopes", () => {
  const reply = parseCoreActionEnvelope("{\"action\":\"reply\",\"responseText\":\"ok\"}");
  assert.equal(reply.action, "reply");
  assert.equal(reply.responseText, "ok");
  assert.equal(reply.taskStatus, undefined);
  assert.equal(normalizeCoreTaskStatus(reply), "completed");

  const capability = parseCoreActionEnvelope(JSON.stringify({
    action: "capability_call",
    taskStatus: "incomplete",
    responseText: "先查一下",
    capabilityRequest: {
      capabilityKey: "code.read",
      reason: "需要看文件",
      input: {
        path: "src/index.ts",
      },
      requestedTier: "B0",
      timeoutMs: 15000,
    },
  }));
  assert.equal(capability.action, "capability_call");
  assert.equal(capability.taskStatus, "incomplete");
  assert.equal(capability.capabilityRequest?.capabilityKey, "code.read");
  assert.equal(capability.capabilityRequest?.timeoutMs, 15000);
  assert.equal(normalizeCoreTaskStatus(capability), "incomplete");
});

test("parseCoreActionEnvelope rejects invalid taskStatus values", () => {
  assert.throws(
    () => parseCoreActionEnvelope("{\"action\":\"reply\",\"responseText\":\"ok\",\"taskStatus\":\"maybe\"}"),
    /taskStatus/i,
  );
});

test("parseTapRequest parses shell restricted request blocks", () => {
  const request = parseTapRequest(`
[TAP REQUEST]
capability: shell.restricted
command: npm test
cwd: .
`);

  assert.equal(request?.capabilityKey, "shell.restricted");
  assert.deepEqual(request?.input, {
    command: "zsh",
    args: ["-lc", "npm test"],
    cwd: ".",
    timeoutMs: 20_000,
  });
});

test("shouldStopCoreCapabilityLoop stops on hard-stop statuses or loop budget", () => {
  assert.equal(shouldStopCoreCapabilityLoop({
    capabilityResultStatus: "success",
    completedLoops: 1,
    maxLoops: 4,
  }), false);
  assert.equal(shouldStopCoreCapabilityLoop({
    capabilityResultStatus: "failed",
    completedLoops: 1,
    maxLoops: 4,
  }), false);
  assert.equal(shouldStopCoreCapabilityLoop({
    capabilityResultStatus: "blocked",
    completedLoops: 1,
    maxLoops: 4,
  }), true);
  assert.equal(shouldStopCoreCapabilityLoop({
    capabilityResultStatus: "review_required",
    completedLoops: 1,
    maxLoops: 4,
  }), true);
  assert.equal(shouldStopCoreCapabilityLoop({
    capabilityResultStatus: "success",
    completedLoops: 4,
    maxLoops: 4,
  }), true);
});

test("applyCliDefaultsToCapabilityRequest keeps explicit browser.playwright inputs ahead of inferred and inherited defaults", async () => {
  const request = {
    capabilityKey: "browser.playwright",
    reason: "Open the page",
    input: {
      action: "navigate",
      url: "https://example.com",
      headless: false,
      browser: "webkit",
      isolated: true,
    },
  };

  const rewritten = await applyCliDefaultsToCapabilityRequest(
    request,
    TEST_CONFIG,
    "请无头打开这个页面",
    {
      headless: true,
      browser: "firefox",
      isolated: false,
    },
  );

  assert.equal(rewritten.input.headless, false);
  assert.equal(rewritten.input.browser, "webkit");
  assert.equal(rewritten.input.isolated, true);
});

test("applyCliDefaultsToCapabilityRequest lets browser.playwright inherit prior browser context after user-message inference", async () => {
  const request = {
    capabilityKey: "browser.playwright",
    reason: "Open the page",
    input: {
      action: "navigate",
      url: "https://example.com",
    },
  };

  const rewritten = await applyCliDefaultsToCapabilityRequest(
    request,
    TEST_CONFIG,
    "请无头打开这个页面",
    {
      headless: false,
      browser: "chromium",
      isolated: true,
    },
  );

  assert.equal(rewritten.input.headless, true);
  assert.equal(rewritten.input.browser, "chromium");
  assert.equal(rewritten.input.isolated, true);
});
