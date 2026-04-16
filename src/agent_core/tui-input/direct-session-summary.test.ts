import assert from "node:assert/strict";
import test from "node:test";

import {
  buildDirectTuiSessionExitSummary,
  estimateDirectTuiUsagePriceUsd,
  formatDirectTuiPercent,
  formatDirectTuiTokenCount,
  formatDirectTuiUsd,
} from "./direct-session-summary.js";

test("direct session summary aggregates usage totals and resume selector", () => {
  const summary = buildDirectTuiSessionExitSummary({
    snapshot: {
      sessionId: "direct-100",
      name: "alpha",
      usageLedger: [
        {
          requestId: "turn:1",
          kind: "core_turn",
          provider: "openai",
          model: "gpt-5.4",
          status: "success",
          inputTokens: 2_000_000,
          outputTokens: 500_000,
          thinkingTokens: 100_000,
          startedAt: "2026-04-16T00:00:00.000Z",
          endedAt: "2026-04-16T00:00:01.000Z",
        },
        {
          requestId: "turn:2",
          kind: "core_turn",
          provider: "openai",
          model: "gpt-5.4-mini",
          status: "failed",
          inputTokens: 500_000,
          outputTokens: 250_000,
          startedAt: "2026-04-16T00:00:02.000Z",
          endedAt: "2026-04-16T00:00:03.000Z",
          estimated: true,
        },
      ],
    },
    sessions: [
      { sessionId: "direct-100", name: "alpha" },
      { sessionId: "direct-200", name: "beta" },
    ],
    generatedAt: "2026-04-16T00:00:04.000Z",
  });

  assert.equal(summary.inputTokens, 2_500_000);
  assert.equal(summary.outputTokens, 750_000);
  assert.equal(summary.thinkingTokens, 100_000);
  assert.equal(summary.requestCount, 2);
  assert.equal(summary.successCount, 1);
  assert.equal(summary.successRate, 0.5);
  assert.equal(summary.resumeSelector, "alpha");
  assert.equal(summary.estimatedPrice, true);
  assert.equal(summary.totalPriceUsd, 8.6);
});

test("pricing helpers format session values for the exit panel", () => {
  assert.equal(estimateDirectTuiUsagePriceUsd({
    provider: "openai",
    model: "gpt-5.4",
    inputTokens: 1_000_000,
    outputTokens: 1_000_000,
  }), 10);
  assert.equal(formatDirectTuiTokenCount(1234567), "1,234,567");
  assert.equal(formatDirectTuiPercent(0.9832), "98.32%");
  assert.equal(formatDirectTuiUsd(42.5), "$42.50");
  assert.equal(formatDirectTuiUsd(undefined), "N/A");
});
