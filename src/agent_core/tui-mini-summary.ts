import { executeModelInference } from "./integrations/model-inference.js";
import { executeTapAgentStructuredOutput } from "./integrations/tap-agent-model.js";

export interface WebSearchMiniSummaryInput {
  sessionId: string;
  runId: string;
  title: string;
  intentLines: string[];
  resultLines: string[];
  metadataLines: string[];
}

export interface TuiMiniSummaryResult {
  title: string;
  lines: string[];
}

const TOOL_SUMMARY_TIMEOUT_MS = 1800;
const TOOL_SUMMARY_MODEL = "gpt-5.4-mini";
const TOOL_SUMMARY_SCHEMA = "tool-summary-websearch/v1";

function truncateJson(value: unknown, maxChars = 1200): string {
  const text = JSON.stringify(value);
  if (!text) {
    return "null";
  }
  return text.length <= maxChars ? text : `${text.slice(0, maxChars)}...`;
}

function buildWebSearchSummaryPrompt(input: WebSearchMiniSummaryInput): string {
  return [
    "Current family title:",
    input.title,
    "",
    "Current intent lines:",
    truncateJson(input.intentLines),
    "",
    "Current result lines:",
    truncateJson(input.resultLines),
    "",
    "Current metadata lines:",
    truncateJson(input.metadataLines),
  ].join("\n");
}

function parseMiniSummary(jsonValue: unknown): TuiMiniSummaryResult {
  if (!jsonValue || typeof jsonValue !== "object") {
    throw new Error("mini summary did not return an object");
  }
  const record = jsonValue as Record<string, unknown>;
  if (record.schemaVersion !== TOOL_SUMMARY_SCHEMA) {
    throw new Error("mini summary schemaVersion mismatch");
  }
  const title = typeof record.title === "string" ? record.title.trim() : "";
  const lines = Array.isArray(record.lines)
    ? record.lines.filter((line): line is string => typeof line === "string").map((line) => line.trim()).filter(Boolean)
    : [];
  if (!title || lines.length === 0) {
    throw new Error("mini summary omitted title or lines");
  }
  return {
    title,
    lines: lines.slice(0, 3),
  };
}

export async function refineWebSearchToolSummary(
  input: WebSearchMiniSummaryInput,
): Promise<TuiMiniSummaryResult | null> {
  const run = executeTapAgentStructuredOutput<TuiMiniSummaryResult>({
    executor: ({ intent }) => executeModelInference({ intent }),
    sessionId: input.sessionId,
    runId: input.runId,
    workerKind: "tui.tool-summary.websearch",
    route: {
      provider: "openai",
      model: TOOL_SUMMARY_MODEL,
      layer: "api",
      variant: "responses",
      maxOutputTokens: 220,
    },
    systemPrompt: [
      "Return one minified JSON object only.",
      "No markdown fences. No explanation outside JSON.",
      "You are a tiny non-reasoning terminal UI summarizer for WebSearch family output.",
      "English only.",
      "Do not invent facts.",
      "Keep the title concise.",
      "Keep 1 to 3 lines.",
      "Each line must be a short human-readable action/result sentence.",
      "Prefer preserving the concrete subject from the intent lines.",
      `Schema: {\"schemaVersion\":\"${TOOL_SUMMARY_SCHEMA}\",\"title\":\"WebSearch|WebSearch failed\",\"lines\":[\"short line\"]}`,
    ].join("\n"),
    userPrompt: buildWebSearchSummaryPrompt(input),
    parse: parseMiniSummary,
  });

  const result = await Promise.race([
    run,
    new Promise<null>((resolve) => {
      setTimeout(() => resolve(null), TOOL_SUMMARY_TIMEOUT_MS);
    }),
  ]);

  return result ?? null;
}
