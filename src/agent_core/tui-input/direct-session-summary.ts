import type {
  DirectTuiSessionExitSummary,
  DirectTuiSessionIndexRecord,
  DirectTuiSessionSnapshot,
  DirectTuiSessionUsageEntry,
} from "./direct-session-store.js";
import { buildDirectTuiResumeSelector } from "./direct-session-store.js";

interface OpenAIPricePerMillion {
  inputUsd: number;
  outputUsd: number;
}

const OPENAI_PRICE_TABLE: Record<string, OpenAIPricePerMillion> = {
  "gpt-5.4": {
    inputUsd: 2,
    outputUsd: 8,
  },
  "gpt-5.4-mini": {
    inputUsd: 0.4,
    outputUsd: 1.6,
  },
};

function normalizeModelKey(model?: string): string | undefined {
  if (!model) {
    return undefined;
  }
  const normalized = model.trim().toLowerCase();
  return normalized.length > 0 ? normalized : undefined;
}

export function estimateDirectTuiUsagePriceUsd(
  entry: Pick<DirectTuiSessionUsageEntry, "provider" | "model" | "inputTokens" | "outputTokens">,
): number | undefined {
  if ((entry.provider ?? "openai").trim().toLowerCase() !== "openai") {
    return undefined;
  }
  const pricing = normalizeModelKey(entry.model)
    ? OPENAI_PRICE_TABLE[normalizeModelKey(entry.model)!]
    : undefined;
  if (!pricing) {
    return undefined;
  }
  const inputTokens = typeof entry.inputTokens === "number" ? entry.inputTokens : 0;
  const outputTokens = typeof entry.outputTokens === "number" ? entry.outputTokens : 0;
  return ((inputTokens / 1_000_000) * pricing.inputUsd) + ((outputTokens / 1_000_000) * pricing.outputUsd);
}

export function buildDirectTuiSessionExitSummary(input: {
  snapshot: Pick<DirectTuiSessionSnapshot, "sessionId" | "name" | "usageLedger">;
  sessions: readonly Pick<DirectTuiSessionIndexRecord, "sessionId" | "name">[];
  generatedAt?: string;
}): DirectTuiSessionExitSummary {
  const usageEntries = input.snapshot.usageLedger ?? [];
  const totals = usageEntries.reduce((accumulator, entry) => {
    accumulator.inputTokens += typeof entry.inputTokens === "number" ? entry.inputTokens : 0;
    accumulator.outputTokens += typeof entry.outputTokens === "number" ? entry.outputTokens : 0;
    accumulator.thinkingTokens += typeof entry.thinkingTokens === "number" ? entry.thinkingTokens : 0;
    accumulator.requestCount += 1;
    if (entry.status === "success") {
      accumulator.successCount += 1;
    }
    const price = estimateDirectTuiUsagePriceUsd(entry);
    if (typeof price === "number") {
      accumulator.totalPriceUsd += price;
    } else if (entry.provider || entry.model) {
      accumulator.estimatedPrice = true;
    }
    if (entry.estimated) {
      accumulator.estimatedPrice = true;
    }
    return accumulator;
  }, {
    inputTokens: 0,
    outputTokens: 0,
    thinkingTokens: 0,
    requestCount: 0,
    successCount: 0,
    totalPriceUsd: 0,
    estimatedPrice: false,
  });
  const resumeSelector = buildDirectTuiResumeSelector({
    sessionId: input.snapshot.sessionId,
    name: input.snapshot.name,
  }, input.sessions);
  return {
    inputTokens: totals.inputTokens,
    outputTokens: totals.outputTokens,
    thinkingTokens: totals.thinkingTokens,
    requestCount: totals.requestCount,
    successCount: totals.successCount,
    successRate: totals.requestCount > 0 ? totals.successCount / totals.requestCount : 1,
    totalPriceUsd: totals.requestCount > 0 ? totals.totalPriceUsd : undefined,
    estimatedPrice: totals.estimatedPrice,
    resumeSelector,
    generatedAt: input.generatedAt ?? new Date().toISOString(),
  };
}

export function formatDirectTuiTokenCount(value: number): string {
  return new Intl.NumberFormat("en-US").format(Math.max(0, Math.round(value)));
}

export function formatDirectTuiPercent(value: number): string {
  return `${(Math.max(0, Math.min(1, value)) * 100).toFixed(2)}%`;
}

export function formatDirectTuiUsd(value?: number): string {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return "N/A";
  }
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: value >= 100 ? 0 : 2,
    maximumFractionDigits: value >= 100 ? 0 : 2,
  }).format(value);
}
