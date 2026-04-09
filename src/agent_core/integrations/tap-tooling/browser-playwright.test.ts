import assert from "node:assert/strict";
import test from "node:test";

import type { CapabilityInvocationPlan } from "../../capability-types/index.js";
import {
  assertBrowserUrlAllowed,
  normalizeBrowserPlaywrightInput,
  selectBrowserPlaywrightBackend,
} from "./browser-playwright.js";

function createPlan(input: Record<string, unknown>): CapabilityInvocationPlan {
  return {
    planId: "plan-browser",
    intentId: "intent-browser",
    sessionId: "session-browser",
    runId: "run-browser",
    capabilityKey: "browser.playwright",
    operation: "browser.playwright",
    input,
    priority: "normal",
  };
}

test("normalizeBrowserPlaywrightInput infers backend from route/provider hints", () => {
  const normalized = normalizeBrowserPlaywrightInput(
    createPlan({
      action: "navigate",
      url: "https://docs.example.com",
      route: {
        provider: "openai",
        model: "gpt-5",
      },
      allowedDomains: ["docs.example.com"],
    }),
  );

  assert.equal(normalized.action, "navigate");
  assert.equal(normalized.selectedBackend, "openai-codex-browser-mcp-style");
  assert.equal(normalized.toolName, "browser_navigate");
});

test("assertBrowserUrlAllowed respects wildcard domains", () => {
  assert.doesNotThrow(() => {
    assertBrowserUrlAllowed("https://api.example.com/health", ["*.example.com"]);
  });

  assert.throws(
    () => assertBrowserUrlAllowed("https://example.org", ["*.example.com"]),
    /allowedDomains/i,
  );
});

test("selectBrowserPlaywrightBackend falls back to shared runtime without route", () => {
  assert.equal(selectBrowserPlaywrightBackend(undefined), "playwright-shared-runtime");
});
