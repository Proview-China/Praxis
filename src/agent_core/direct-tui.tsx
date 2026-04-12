import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { open } from "node:fs/promises";
import { resolve } from "node:path";
import { Box, render, Text, useApp, useInput } from "ink";
import { memo, useEffect, useMemo, useRef, useState } from "react";
import stringWidth from "string-width";

import { loadOpenAILiveConfig } from "../rax/live-config.js";
import { applySurfaceEvent, createInitialSurfaceState } from "./surface/reducer.js";
import {
  selectTranscriptMessages,
} from "./surface/selectors.js";
import {
  createSurfaceMessage,
  createSurfaceOverlay,
  createSurfaceSession,
  createSurfaceTask,
  createSurfaceTurn,
  type SurfaceAppState,
  type SurfaceMessage,
} from "./surface/types.js";
import {
  applyTuiTextInputKey,
  createTuiTextInputState,
  setTuiTextInputValue,
} from "./tui-input/text-input.js";
import {
  applySlashSuggestion,
  computeSlashState,
  DEFAULT_PRAXIS_SLASH_COMMANDS,
} from "./tui-input/slash-engine.js";
import { TUI_THEME } from "./tui-theme.js";

type BackendStatus = "starting" | "ready" | "exited" | "failed";

interface LiveLogRecord {
  ts: string;
  event: string;
  turnIndex?: number;
  stage?: string;
  status?: string;
  label?: string;
  elapsedMs?: number;
  userMessage?: string;
  capabilityKey?: string | null;
  reason?: string;
  inputSummary?: string;
  core?: {
    answer?: string | {
      text?: string;
      truncated?: boolean;
      originalChars?: number;
    };
    dispatchStatus?: string;
    capabilityKey?: string;
    capabilityResultStatus?: string;
  };
  text?: string;
}

interface RenderLine {
  kind: SurfaceMessage["kind"] | "detail";
  text: string;
  segments?: Array<{
    text: string;
    color?: string;
  }>;
}

interface RenderBlock {
  key: string;
  lines: RenderLine[];
}

const DEFAULT_CONTEXT_WINDOW = 1_050_000;
const CONTEXT_BAR_WIDTH = 24;
const STARTUP_WORD = "RAXCODE";
const STARTUP_ANIMATION_INTERVAL_MS = 200;
const STARTUP_RAINBOW_BASE_COLORS = [
  "redBright",
  "yellow",
  "yellowBright",
  "greenBright",
  "cyanBright",
  "magenta",
  "magentaBright",
] as const;
const STARTUP_RAINBOW_COLORS = [
  ...STARTUP_RAINBOW_BASE_COLORS,
  ...STARTUP_RAINBOW_BASE_COLORS,
  ...STARTUP_RAINBOW_BASE_COLORS,
  "magentaBright",
] as const;

const composerCursorParking = {
  row: 1,
  column: 1,
  active: false,
};

const inkCursorAwareStdout = new Proxy(process.stdout, {
  get(target, property, receiver) {
    if (property === "write") {
      return (chunk: string | Uint8Array, ...args: unknown[]) => {
        const result = target.write(chunk as never, ...(args as []));
        if (composerCursorParking.active && target.isTTY) {
          target.write("\u001B[?25h");
          target.write(`\u001B[${composerCursorParking.row};${composerCursorParking.column}H`);
        }
        return result;
      };
    }
    return Reflect.get(target, property, receiver);
  },
});

const MAX_RENDER_LINES = 1000;
const MAX_DEBUG_LINE_CHARS = 180;

const STARTUP_LETTER_ART: Record<string, string[]> = {
  R: [
    "██████╗ ",
    "██╔══██╗",
    "██████╔╝",
    "██╔══██╗",
    "██║  ██║",
    "╚═╝  ╚═╝",
  ],
  A: [
    " █████╗ ",
    "██╔══██╗",
    "███████║",
    "██╔══██║",
    "██║  ██║",
    "╚═╝  ╚═╝",
  ],
  X: [
    "██╗  ██╗",
    "╚██╗██╔╝",
    " ╚███╔╝ ",
    " ██╔██╗ ",
    "██╔╝ ██╗",
    "╚═╝  ╚═╝",
  ],
  C: [
    " ██████╗",
    "██╔════╝",
    "██║     ",
    "██║     ",
    "╚██████╗",
    " ╚═════╝",
  ],
  O: [
    " ██████╗ ",
    "██╔═══██╗",
    "██║   ██║",
    "██║   ██║",
    "╚██████╔╝",
    " ╚═════╝ ",
  ],
  D: [
    "██████╗ ",
    "██╔══██╗",
    "██║  ██║",
    "██║  ██║",
    "██████╔╝",
    "╚═════╝ ",
  ],
  E: [
    "███████╗",
    "██╔════╝",
    "█████╗  ",
    "██╔══╝  ",
    "███████╗",
    "╚══════╝",
  ],
};

function stripAnsi(value: string): string {
  return value
    .replace(/\u001B\][^\u0007]*(?:\u0007|\u001B\\)/gu, "")
    .replace(/\u001B\[[0-?]*[ -/]*[@-~]/gu, "")
    .replace(/\u001B[@-Z\\-_]/gu, "");
}

function shortenPath(value: string): string {
  const home = process.env.HOME;
  if (home && value.startsWith(home)) {
    return `~${value.slice(home.length)}`;
  }
  return value;
}

function appendClipped<T>(previous: T[], next: T[], max = MAX_RENDER_LINES): T[] {
  const merged = [...previous, ...next];
  return merged.length <= max ? merged : merged.slice(merged.length - max);
}

function formatElapsedFromMs(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function extractTurnResultAnswer(record: LiveLogRecord): string | null {
  const answer = record.core?.answer;
  if (typeof answer === "string") {
    return answer.trim() || null;
  }
  if (answer && typeof answer === "object" && typeof answer.text === "string") {
    return answer.text.trim() || null;
  }
  return null;
}

function compactRuntimeText(text: string): string {
  const normalized = text.replace(/\s+/gu, " ").trim();
  if (normalized.length <= MAX_DEBUG_LINE_CHARS) {
    return normalized;
  }
  return `${normalized.slice(0, MAX_DEBUG_LINE_CHARS - 1).trimEnd()}…`;
}

function estimateTerminalWidth(text: string): number {
  let width = 0;
  for (const char of [...text]) {
    const codePoint = char.codePointAt(0) ?? 0;
    width += codePoint >= 0x1100 ? 2 : 1;
  }
  return width;
}

function splitComposerLines(value: string): string[] {
  const lines = value.split("\n");
  return lines.length > 0 ? lines : [""];
}

function measureComposerCursor(value: string, cursorOffset: number): { line: number; column: number } {
  const beforeCursor = value.slice(0, cursorOffset);
  const lines = beforeCursor.split("\n");
  return {
    line: Math.max(0, lines.length - 1),
    column: estimateTerminalWidth(lines.at(-1) ?? ""),
  };
}

function summarizeRuntimeEnvelope(text: string): string | null {
  try {
    const parsed = JSON.parse(text) as {
      action?: unknown;
      taskStatus?: unknown;
      responseText?: unknown;
      capabilityKey?: unknown;
      output?: unknown;
    };
    const action = typeof parsed.action === "string" ? parsed.action : undefined;
    const taskStatus = typeof parsed.taskStatus === "string" ? parsed.taskStatus : undefined;
    const capabilityKey = typeof parsed.capabilityKey === "string" ? parsed.capabilityKey : undefined;

    if (!action) {
      return null;
    }

    if (action === "reply") {
      return taskStatus ? `core reply · ${taskStatus}` : "core reply";
    }
    if (action === "tool" && capabilityKey) {
      return taskStatus ? `${capabilityKey} · ${taskStatus}` : capabilityKey;
    }

    return taskStatus ? `${action} · ${taskStatus}` : action;
  } catch {
    return null;
  }
}

function summarizeStatusText(text: string): string {
  const envelopeSummary = summarizeRuntimeEnvelope(text);
  if (envelopeSummary) {
    return envelopeSummary;
  }
  return compactRuntimeText(text);
}

function summarizeNonPrimaryMessage(message: SurfaceMessage): SurfaceMessage {
  if (message.kind === "assistant" || message.kind === "user") {
    return message;
  }
  return {
    ...message,
    text: summarizeStatusText(message.text),
  };
}

function computeVisibleLines<T>(
  lines: T[],
  viewportLineCount: number,
  scrollOffset: number,
): T[] {
  if (lines.length <= viewportLineCount) {
    return lines;
  }
  const end = Math.max(viewportLineCount, lines.length - scrollOffset);
  const start = Math.max(0, end - viewportLineCount);
  return lines.slice(start, end);
}

const graphemeSegmenter = new Intl.Segmenter("zh", { granularity: "grapheme" });

function splitGraphemes(text: string): string[] {
  return Array.from(graphemeSegmenter.segment(text), (segment) => segment.segment);
}

function wrapRenderText(text: string, maxWidth: number): string[] {
  if (text.length === 0) {
    return [" "];
  }
  if (maxWidth <= 0) {
    return [""];
  }

  const output: string[] = [];
  let current = "";
  let currentWidth = 0;

  for (const grapheme of splitGraphemes(text)) {
    const width = Math.max(1, stringWidth(grapheme));
    if (currentWidth > 0 && currentWidth + width > maxWidth) {
      output.push(current);
      current = grapheme;
      currentWidth = width;
      continue;
    }
    current += grapheme;
    currentWidth += width;
  }

  output.push(current);
  return output;
}

function buildAnimatedStartupWord(step: number): RenderLine[] {
  const visibleLetters = STARTUP_WORD.slice(0, Math.max(0, Math.min(step, STARTUP_WORD.length))).split("");
  const rows = Array.from({ length: 6 }, () => [] as Array<{ text: string; color?: string }>);
  const highlightedLetterIndex =
    step > 0 && step <= STARTUP_WORD.length
      ? visibleLetters.length - 1
      : -1;
  const showPoweredBy = step >= STARTUP_WORD.length;
  const rainbowIndex = Math.max(0, Math.min(
    STARTUP_RAINBOW_COLORS.length - 1,
    step - STARTUP_WORD.length,
  ));

  visibleLetters.forEach((letter, letterIndex) => {
    const glyph = STARTUP_LETTER_ART[letter];
    if (!glyph) {
      return;
    }
    const color = letterIndex === highlightedLetterIndex ? TUI_THEME.violet : undefined;
    for (let index = 0; index < rows.length; index += 1) {
      rows[index].push({
        text: `${glyph[index]} `,
        color,
      });
    }
  });

  if (showPoweredBy) {
    rows[0].push({ text: "powered by ", color: TUI_THEME.textMuted });
    rows[0].push({ text: "Praxis", color: STARTUP_RAINBOW_COLORS[rainbowIndex] });
  }

  if (step > STARTUP_WORD.length) {
    rows[5].push({
      text: "v0.1.0",
      color: TUI_THEME.textMuted,
    });
  }

  return rows.map((segments) => ({
    kind: "detail" as const,
    text: segments.map((segment) => segment.text).join(""),
    segments,
  }));
}

function expandRenderLinesForWidth(lines: RenderLine[], maxWidth: number): RenderLine[] {
  return lines.flatMap((line) => {
    if (line.segments) {
      return [line];
    }
    return wrapRenderText(line.text, maxWidth).map((segment) => ({
      kind: line.kind,
      text: segment,
    }));
  });
}

function renderMessagePrefix(kind: SurfaceMessage["kind"]): { label: string; color?: string } {
  switch (kind) {
    case "user":
      return { label: "[USR]", color: TUI_THEME.mint };
    case "assistant":
      return { label: "[SYS]", color: TUI_THEME.text };
    case "status":
      return { label: "[RUN]", color: TUI_THEME.mintSoft };
    case "tool_use":
      return { label: "[USE]", color: TUI_THEME.yellow };
    case "tool_result":
      return { label: "[RES]", color: TUI_THEME.yellow };
    case "error":
      return { label: "[ERR]", color: TUI_THEME.red };
    default:
      return { label: "[LOG]", color: TUI_THEME.textMuted };
  }
}

function createMessagePrefix(kind: SurfaceMessage["kind"]): string {
  return renderMessagePrefix(kind).label;
}

function flattenTranscript(messages: SurfaceMessage[]): RenderLine[] {
  return flattenTranscriptBlocks(messages).flatMap((block) => block.lines);
}

function flattenTranscriptBlocks(messages: SurfaceMessage[]): RenderBlock[] {
  const blocks: RenderBlock[] = [];
  for (const message of messages) {
    const displayMessage = summarizeNonPrimaryMessage(message);
    const chunks = displayMessage.text.split("\n");
    const lines: RenderLine[] = [];

    if (displayMessage.kind === "assistant" || displayMessage.kind === "user") {
      lines.push({
        kind: displayMessage.kind,
        text: createMessagePrefix(displayMessage.kind),
      });
      chunks.forEach((chunk) => {
        lines.push({
          kind: displayMessage.kind,
          text: chunk.length > 0 ? `  ${chunk}` : "",
        });
      });
    } else {
      chunks.forEach((chunk, index) => {
        lines.push({
          kind: displayMessage.kind,
          text: `${index === 0 ? `${createMessagePrefix(displayMessage.kind)} ` : "      "}${chunk}`,
        });
      });
    }

    lines.push({
      kind: "detail",
      text: "",
    });
    blocks.push({
      key: message.messageId,
      lines,
    });
  }
  return blocks;
}


function colorForRenderLine(kind: RenderLine["kind"]): string | undefined {
  switch (kind) {
    case "user":
      return TUI_THEME.mint;
    case "assistant":
      return TUI_THEME.text;
    case "status":
      return TUI_THEME.mintSoft;
    case "tool_use":
    case "tool_result":
      return TUI_THEME.yellow;
    case "error":
      return TUI_THEME.red;
    case "detail":
      return TUI_THEME.text;
    default:
      return TUI_THEME.textMuted;
  }
}

function createTurnId(turnIndex?: number): string {
  return `turn-${turnIndex ?? 0}`;
}

function createTaskId(record: LiveLogRecord): string {
  return `${record.stage ?? record.label ?? "stage"}:${record.turnIndex ?? 0}:${record.capabilityKey ?? "none"}`;
}

function formatStageStatus(record: LiveLogRecord, phase: "start" | "end"): string {
  const label = record.capabilityKey ?? record.label ?? record.stage ?? "stage";
  if (phase === "start") {
    return `${label} · running`;
  }
  if (record.status === "failed") {
    return `${label} · failed`;
  }
  return `${label} · ${record.status ?? "done"}`;
}

function estimateContextUnits(text: string): number {
  return Math.max(0, Math.ceil(text.length / 4));
}

function formatContextWindowLabel(size: number): string {
  if (size >= 1_000_000) {
    return `${(size / 1_000_000).toFixed(2)}M`;
  }
  if (size >= 1_000) {
    return `${(size / 1_000).toFixed(0)}K`;
  }
  return String(size);
}

function renderContextBar(used: number, total: number): string {
  const ratio = total <= 0 ? 0 : Math.max(0, Math.min(1, used / total));
  const filled = used > 0
    ? Math.max(1, Math.round(ratio * CONTEXT_BAR_WIDTH))
    : 0;
  return `${"█".repeat(filled)}${"░".repeat(Math.max(0, CONTEXT_BAR_WIDTH - filled))}`;
}

function applyScrollDelta(current: number, delta: number, max: number): number {
  return Math.max(0, Math.min(max, current + delta));
}

function parseMouseScrollDelta(inputText: string): number | null {
  // Ink strips the first ESC byte for some unhandled sequences, so mouse
  // reports can arrive as "[<64;..M", "<64;..M", or multiple reports glued
  // together in one chunk. Consume all of them before input handling.
  const matches = [...inputText.matchAll(/(?:\u001B)?\[?<(\d+);\d+;\d+[mM]/gu)];
  if (matches.length === 0) {
    return null;
  }

  let delta = 0;
  for (const match of matches) {
    const code = Number(match[1]);
    if (code === 64) {
      delta += 3;
    } else if (code === 65) {
      delta -= 3;
    }
  }
  return delta;
}

const TranscriptPane = memo(function TranscriptPane({
  visibleLines,
  viewportLineCount,
}: {
  visibleLines: RenderLine[];
  viewportLineCount: number;
}): JSX.Element {
  const fillerCount = Math.max(0, viewportLineCount - visibleLines.length);

  return (
    <Box flexDirection="column" flexGrow={1} flexShrink={1}>
      <Box flexDirection="column" height={viewportLineCount} flexGrow={1} flexShrink={1}>
        {visibleLines.map((line, index) => (
          <Text key={`body-${index}-${line.text}`} color={colorForRenderLine(line.kind)} wrap="truncate-end">
            {line.segments
              ? line.segments.map((segment, segmentIndex) => (
                <Text key={`body-${index}-${segmentIndex}-${segment.text}`} color={segment.color}>
                  {segment.text}
                </Text>
              ))
              : line.text}
          </Text>
        ))}
        {Array.from({ length: fillerCount }, (_, index) => (
          <Text key={`filler-${index}`}> </Text>
        ))}
      </Box>
    </Box>
  );
});


const ComposerPane = memo(function ComposerPane({
  showSlashMenu,
  commandPaletteItems,
  selectedSlashIndex,
  composerValue,
  composerLines,
  workspaceLabel,
  contextBar,
  contextPercent,
  contextWindowLabel,
  lineWidth,
}: {
  showSlashMenu: boolean;
  commandPaletteItems: Array<{ key: string; label: string; description?: string }>;
  selectedSlashIndex: number;
  composerValue: string;
  composerLines: string[];
  workspaceLabel: string;
  contextBar: string;
  contextPercent: string;
  contextWindowLabel: string;
  lineWidth: number;
}): JSX.Element {
  return (
    <Box marginTop={1} flexDirection="column">
      {showSlashMenu ? (
        <Box marginBottom={1} flexDirection="column">
          {commandPaletteItems.map((item, index) => {
            const active = index === selectedSlashIndex;
            return (
              <Text key={item.key} color={active ? TUI_THEME.mint : TUI_THEME.textMuted}>
                {`${String(index + 1).padStart(2, "0")} ${item.label}${item.description ? ` · ${item.description}` : ""}`}
              </Text>
            );
          })}
        </Box>
      ) : null}
      <Text color={TUI_THEME.line}>{"─".repeat(lineWidth)}</Text>
      {composerLines.map((line, index) => (
        <Text key={`composer-line-${index}`}>
          <Text color={TUI_THEME.mint}>{index === 0 ? ">> " : "   "}</Text>
          <Text color={TUI_THEME.text}>{line.length > 0 ? line : " "}</Text>
        </Text>
      ))}
      <Text color={TUI_THEME.line}>{"─".repeat(lineWidth)}</Text>
      <Text wrap="truncate-end">
        <Text color={TUI_THEME.textMuted}>WorkSpace: </Text>
        <Text color={TUI_THEME.text}>{workspaceLabel}</Text>
        <Text color={TUI_THEME.text}>    </Text>
        <Text color={TUI_THEME.textMuted}>Context </Text>
        <Text color={TUI_THEME.text}>{contextBar} </Text>
        <Text color={TUI_THEME.text}>{contextPercent} </Text>
        <Text color={TUI_THEME.textMuted}>of </Text>
        <Text color={TUI_THEME.text}>{contextWindowLabel}</Text>
      </Text>
    </Box>
  );
});

function PraxisDirectTuiApp(): JSX.Element {
  const { exit } = useApp();
  const config = useMemo(() => loadOpenAILiveConfig(), []);
  const supportsRawInput = Boolean(process.stdin.isTTY && typeof process.stdin.setRawMode === "function");
  const [backendStatus, setBackendStatus] = useState<BackendStatus>("starting");
  const [composerState, setComposerState] = useState(() => createTuiTextInputState());
  const [selectedSlashIndex, setSelectedSlashIndex] = useState(0);
  const [logPath, setLogPath] = useState<string | null>(null);
  const [scrollOffset, setScrollOffset] = useState(0);
  const [startupAnimationStep, setStartupAnimationStep] = useState(0);
  const [surfaceState, setSurfaceState] = useState<SurfaceAppState>(() => createInitialSurfaceState());
  const [terminalSize, setTerminalSize] = useState(() => ({
    rows: process.stdout.rows ?? 24,
    columns: process.stdout.columns ?? 80,
  }));
  const childRef = useRef<ChildProcessWithoutNullStreams | null>(null);
  const stdoutRemainderRef = useRef("");
  const stderrRemainderRef = useRef("");
  const processedLogByteOffsetRef = useRef(0);
  const sessionIdRef = useRef(`direct-${Date.now()}`);
  const previousTranscriptLineCountRef = useRef(0);

  const dispatchSurfaceEvent = (event: Record<string, unknown>) => {
    setSurfaceState((previous) => applySurfaceEvent(previous, event as never));
  };

  useEffect(() => {
    const startedAt = new Date().toISOString();
    dispatchSurfaceEvent({
      type: "session.started",
      at: startedAt,
      session: createSurfaceSession({
        sessionId: sessionIdRef.current,
        startedAt,
        updatedAt: startedAt,
        uiMode: "direct",
        workspaceLabel: process.cwd().split("/").slice(-1)[0] || process.cwd(),
        route: config.baseURL,
        transcriptMessageIds: [],
        taskIds: [],
      }),
    });
  }, [config.baseURL]);

  useEffect(() => {
    const handleResize = () => {
      setTerminalSize({
        rows: process.stdout.rows ?? 24,
        columns: process.stdout.columns ?? 80,
      });
    };
    process.stdout.on("resize", handleResize);
    return () => {
      process.stdout.off("resize", handleResize);
    };
  }, []);

  useEffect(() => {
    if (startupAnimationStep >= STARTUP_WORD.length + STARTUP_RAINBOW_COLORS.length) {
      return;
    }
    const timer = setInterval(() => {
      setStartupAnimationStep((previous) => {
        if (previous >= STARTUP_WORD.length + STARTUP_RAINBOW_COLORS.length) {
          return previous;
        }
        return previous + 1;
      });
    }, STARTUP_ANIMATION_INTERVAL_MS);
    return () => {
      clearInterval(timer);
    };
  }, [startupAnimationStep]);

  useEffect(() => {
    if (!process.stdout.isTTY) {
      return;
    }
    process.stdout.write("\u001B[?1000h\u001B[?1006h");
    return () => {
      process.stdout.write("\u001B[?1000l\u001B[?1006l");
    };
  }, []);

  useEffect(() => {
    dispatchSurfaceEvent({
      type: "composer.updated",
      at: new Date().toISOString(),
      composer: {
        value: "",
        buffer: "",
        cursorOffset: 0,
        disabled: backendStatus === "failed",
      },
    });
  }, [backendStatus]);

  useEffect(() => {
    const tsxBin = resolve(process.cwd(), "node_modules/.bin/tsx");
    const backendPath = resolve(process.cwd(), "src/agent_core/live-agent-chat.ts");
    const child = spawn(
      tsxBin,
      [backendPath, "--ui=direct"],
      {
        cwd: process.cwd(),
        env: process.env,
        stdio: ["pipe", "pipe", "pipe"],
      },
    );
    childRef.current = child;

    const flushChunk = (chunk: string, stream: "stdout" | "stderr") => {
      const clean = stripAnsi(chunk).replace(/\r/gu, "");
      const previousRemainder = stream === "stdout" ? stdoutRemainderRef.current : stderrRemainderRef.current;
      const combined = previousRemainder + clean;
      const parts = combined.split("\n");
      const remainder = parts.pop() ?? "";
      if (stream === "stdout") {
        stdoutRemainderRef.current = remainder;
      } else {
        stderrRemainderRef.current = remainder;
      }

      for (const rawLine of parts) {
        const line = rawLine.trimEnd();
        if (!line) {
          continue;
        }
        if (line.startsWith("log file: ")) {
          setLogPath(line.slice("log file: ".length).trim());
          setBackendStatus("ready");
          continue;
        }
        if (stream === "stderr") {
          const at = new Date().toISOString();
          dispatchSurfaceEvent({
            type: "error.reported",
            at,
            message: createSurfaceMessage({
              messageId: `stderr:${at}`,
              kind: "error",
              createdAt: at,
              text: line,
              status: "warning",
            }),
          });
        }
      }
    };

    child.stdout.on("data", (chunk: Buffer | string) => {
      flushChunk(typeof chunk === "string" ? chunk : chunk.toString("utf8"), "stdout");
    });
    child.stderr.on("data", (chunk: Buffer | string) => {
      flushChunk(typeof chunk === "string" ? chunk : chunk.toString("utf8"), "stderr");
    });
    child.on("error", (error) => {
      setBackendStatus("failed");
      const at = new Date().toISOString();
      dispatchSurfaceEvent({
        type: "error.reported",
        at,
        message: createSurfaceMessage({
          messageId: `spawn:${at}`,
          kind: "error",
          createdAt: at,
          text: `backend spawn failed: ${error.message}`,
        }),
      });
    });
    child.on("close", (code, signal) => {
      const stderrTail = stderrRemainderRef.current.trim();
      stdoutRemainderRef.current = "";
      stderrRemainderRef.current = "";
      if (stderrTail) {
        const at = new Date().toISOString();
        dispatchSurfaceEvent({
          type: "error.reported",
          at,
          message: createSurfaceMessage({
            messageId: `stderr-tail:${at}`,
            kind: "error",
            createdAt: at,
            text: stderrTail,
          }),
        });
      }
      setBackendStatus(code === 0 || signal === "SIGTERM" ? "exited" : "failed");
    });

    return () => {
      if (!child.killed) {
        child.kill("SIGTERM");
      }
    };
  }, []);

  useEffect(() => {
    if (!logPath) {
      return;
    }

    let cancelled = false;
    const tick = async () => {
      try {
        const handle = await open(logPath, "r");
        const stats = await handle.stat();
        const nextSize = stats.size;
        const currentOffset = processedLogByteOffsetRef.current;
        if (nextSize <= currentOffset) {
          await handle.close();
          return;
        }
        const chunkLength = nextSize - currentOffset;
        const buffer = Buffer.alloc(chunkLength);
        await handle.read(buffer, 0, chunkLength, currentOffset);
        await handle.close();
        if (cancelled) {
          return;
        }
        processedLogByteOffsetRef.current = nextSize;
        const raw = buffer.toString("utf8");
        const rows = raw.split("\n").filter((entry) => entry.trim().length > 0);

        for (const row of rows) {
          let record: LiveLogRecord;
          try {
            record = JSON.parse(row) as LiveLogRecord;
          } catch {
            continue;
          }

          const at = record.ts;
          const turnId = createTurnId(record.turnIndex);

          if (record.event === "turn_start") {
            dispatchSurfaceEvent({
              type: "turn.started",
              at,
              turn: createSurfaceTurn({
                turnId,
                sessionId: sessionIdRef.current,
                turnIndex: record.turnIndex ?? 0,
                status: "running",
                startedAt: at,
                updatedAt: at,
                outputMessageIds: [],
                taskIds: [],
              }),
            });
            if (record.userMessage?.trim()) {
              dispatchSurfaceEvent({
                type: "message.appended",
                at,
                message: createSurfaceMessage({
                  messageId: `user:${turnId}`,
                  sessionId: sessionIdRef.current,
                  turnId,
                  kind: "user",
                  text: record.userMessage.trim(),
                  createdAt: at,
                }),
              });
            }
            continue;
          }

          if (record.event === "stage_start") {
            dispatchSurfaceEvent({
              type: "task.upserted",
              at,
              task: createSurfaceTask({
                taskId: createTaskId(record),
                sessionId: sessionIdRef.current,
                turnId,
                kind: record.stage?.startsWith("cmp/")
                  ? "cmp_sync"
                  : (record.capabilityKey ? "capability_run" : "core_turn"),
                status: "running",
                title: record.capabilityKey ?? record.label ?? record.stage ?? "stage",
                summary: record.inputSummary ?? record.reason ?? record.label ?? record.stage,
                capabilityKey: record.capabilityKey ?? undefined,
                startedAt: at,
                updatedAt: at,
                foregroundable: true,
              }),
            });
            dispatchSurfaceEvent({
              type: "message.appended",
              at,
              message: createSurfaceMessage({
                messageId: `stage-start:${createTaskId(record)}:${at}`,
                sessionId: sessionIdRef.current,
                turnId,
                kind: "status",
                text: formatStageStatus(record, "start"),
                createdAt: at,
                capabilityKey: record.capabilityKey ?? undefined,
              }),
            });

            if (record.stage?.startsWith("cmp/")) {
              dispatchSurfaceEvent({
                type: "panel.updated",
                at,
                panel: "cmp",
                snapshot: {
                  summary: `${record.label ?? record.stage} running`,
                  readbackStatus: "running",
                  rows: [{
                    section: "health",
                    label: "stage",
                    value: record.stage,
                  }],
                },
              });
            }

            if (record.stage === "core/capability_bridge") {
              dispatchSurfaceEvent({
                type: "panel.updated",
                at,
                panel: "tap",
                snapshot: {
                  summary: record.capabilityKey
                    ? `capability running: ${record.capabilityKey}`
                    : "capability bridge running",
                  currentLayer: "runtime",
                  pendingHumanGateCount: 0,
                  blockingCapabilityKeys: [],
                },
              });
            }

            continue;
          }

          if (record.event === "stage_end") {
            dispatchSurfaceEvent({
              type: "task.completed",
              at,
              taskId: createTaskId(record),
              status: record.status === "failed" ? "failed" : "completed",
              summary: record.text ?? `${record.stage ?? "stage"} ${record.status ?? "completed"}`,
            });
            dispatchSurfaceEvent({
              type: "message.appended",
              at,
              message: createSurfaceMessage({
                messageId: `stage-end:${createTaskId(record)}:${at}`,
                sessionId: sessionIdRef.current,
                turnId,
                kind: record.status === "failed" ? "error" : "status",
                text: record.text ?? formatStageStatus(record, "end"),
                createdAt: at,
              }),
            });
            if (record.stage === "core/run") {
            }
            continue;
          }

          if (record.event === "turn_result") {
            const answer = extractTurnResultAnswer(record);
            if (answer) {
              dispatchSurfaceEvent({
                type: "message.appended",
                at,
                message: createSurfaceMessage({
                  messageId: `assistant:${turnId}`,
                  sessionId: sessionIdRef.current,
                  turnId,
                  kind: "assistant",
                  text: answer,
                  createdAt: at,
                  capabilityKey: record.core?.capabilityKey,
                  status: record.core?.capabilityResultStatus,
                }),
              });
            }
            dispatchSurfaceEvent({
              type: "turn.completed",
              at,
              turn: createSurfaceTurn({
                turnId,
                sessionId: sessionIdRef.current,
                turnIndex: record.turnIndex ?? 0,
                status: "completed",
                startedAt: at,
                updatedAt: at,
                outputMessageIds: [],
                taskIds: [],
              }),
            });
            dispatchSurfaceEvent({
              type: "panel.updated",
              at,
              panel: "core",
              snapshot: {
                runId: turnId,
                runStatus: "completed",
                dispatchStatus: record.core?.dispatchStatus,
                taskStatus: "completed",
                capabilityKey: record.core?.capabilityKey,
                eventTypes: ["turn_result"],
              },
            });
            continue;
          }

          if (record.event === "stream_text" && typeof record.text === "string" && record.text.trim()) {
            dispatchSurfaceEvent({
              type: "message.appended",
              at,
              message: createSurfaceMessage({
                messageId: `stream:${turnId}:${at}`,
                sessionId: sessionIdRef.current,
                turnId,
                kind: "status",
                text: record.text,
                createdAt: at,
                status: "streaming",
              }),
            });
          }
        }
      } catch {
        // startup races are expected
      }
    };

    void tick();
    const timer = setInterval(() => {
      void tick();
    }, 350);

    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, [logPath]);

  const submitInput = () => {
    const message = composerState.value.trim();
    if (!message) {
      return;
    }
    const child = childRef.current;
    if (!child || child.killed || backendStatus === "failed") {
      const at = new Date().toISOString();
      dispatchSurfaceEvent({
        type: "error.reported",
        at,
        message: createSurfaceMessage({
          messageId: `submit-error:${at}`,
          kind: "error",
          createdAt: at,
          text: "backend unavailable, cannot send message",
        }),
      });
      return;
    }
    child.stdin.write(`${message}\n`);
    setComposerState(createTuiTextInputState());
    setScrollOffset(0);
  };

  useInput((inputText, key) => {
    const mouseScrollDelta = parseMouseScrollDelta(inputText);
    if (mouseScrollDelta !== null) {
      if (mouseScrollDelta !== 0) {
        setScrollOffset((previous) => applyScrollDelta(previous, mouseScrollDelta, maxScrollOffset));
      }
      return;
    }

    if (key.ctrl && inputText === "c") {
      const child = childRef.current;
      if (child && !child.killed) {
        child.stdin.write("/exit\n");
      }
      exit();
      return;
    }

    if (key.escape) {
      if (showSlashMenu) {
        setSelectedSlashIndex(0);
        return;
      }
      return;
    }

    if (showSlashMenu && !composerState.value.includes("\n")) {
      if (key.upArrow) {
        setSelectedSlashIndex((previous) =>
          slashState.suggestions.length === 0
            ? 0
            : (previous - 1 + slashState.suggestions.length) % slashState.suggestions.length);
        return;
      }
      if (key.downArrow) {
        setSelectedSlashIndex((previous) =>
          slashState.suggestions.length === 0
            ? 0
            : (previous + 1) % slashState.suggestions.length);
        return;
      }
    }

    if (key.upArrow) {
      const inputResult = applyTuiTextInputKey(composerState, inputText, key);
      const movedInsideComposer =
        composerState.value.includes("\n")
        && (
          inputResult.nextState.cursorOffset !== composerState.cursorOffset
          || inputResult.nextState.value !== composerState.value
        );
      if (movedInsideComposer) {
        setComposerState(inputResult.nextState);
        return;
      }
      setScrollOffset((previous) => applyScrollDelta(previous, 1, maxScrollOffset));
      return;
    }

    if (key.downArrow) {
      const inputResult = applyTuiTextInputKey(composerState, inputText, key);
      const movedInsideComposer =
        composerState.value.includes("\n")
        && (
          inputResult.nextState.cursorOffset !== composerState.cursorOffset
          || inputResult.nextState.value !== composerState.value
        );
      if (movedInsideComposer) {
        setComposerState(inputResult.nextState);
        return;
      }
      setScrollOffset((previous) => applyScrollDelta(previous, -1, maxScrollOffset));
      return;
    }

    if (key.pageUp) {
      setScrollOffset((previous) => applyScrollDelta(previous, Math.max(6, Math.floor(transcriptViewportLineCount / 2)), maxScrollOffset));
      return;
    }

    if (key.pageDown) {
      setScrollOffset((previous) => applyScrollDelta(previous, -Math.max(6, Math.floor(transcriptViewportLineCount / 2)), maxScrollOffset));
      return;
    }

    if (showSlashMenu) {
      if (key.tab || key.return) {
        const selectedSuggestion = slashState.suggestions[selectedSlashIndex];
        if (selectedSuggestion) {
          const applied = applySlashSuggestion(composerState.value, selectedSuggestion);
          setComposerState((previous) =>
            setTuiTextInputValue(previous, applied.nextInput, applied.nextCursorOffset));
          if (!key.return) {
            return;
          }
          if (composerState.value.trim() !== applied.nextInput.trim()) {
            return;
          }
        }
      }
    }

    const inputResult = applyTuiTextInputKey(composerState, inputText, key);
    if (inputResult.submit) {
      submitInput();
      return;
    }
    if (inputResult.handled) {
      setComposerState(inputResult.nextState);
      if (!inputResult.nextState.value.trimStart().startsWith("/")) {
        setSelectedSlashIndex(0);
      }
    }
  }, {
    isActive: supportsRawInput,
  });

  const transcriptMessages = useMemo(
    () => selectTranscriptMessages(surfaceState),
    [surfaceState],
  );
  const terminalRows = terminalSize.rows;
  const terminalColumns = terminalSize.columns;
  const transcriptLineWidth = Math.max(1, terminalColumns - 2);
  const composerLines = splitComposerLines(composerState.value);
  const startupPreludeLines = useMemo<RenderLine[]>(
    () => [
      ...buildAnimatedStartupWord(startupAnimationStep),
      {
        kind: "detail",
        text: "GPT-5.4 with high effort",
        segments: [
          { text: "GPT-5.4", color: TUI_THEME.text },
          { text: " with ", color: TUI_THEME.textMuted },
          { text: "high", color: TUI_THEME.text },
          { text: " effort", color: TUI_THEME.textMuted },
        ],
      },
      {
        kind: "detail",
        text: `WorkSpace: ${shortenPath(process.cwd())}`,
        segments: [
          { text: "WorkSpace: ", color: TUI_THEME.textMuted },
          { text: shortenPath(process.cwd()), color: TUI_THEME.text },
        ],
      },
      { kind: "detail", text: "" },
    ],
    [startupAnimationStep],
  );
  const startupPreludeExpandedLines = useMemo(
    () => expandRenderLinesForWidth(startupPreludeLines, transcriptLineWidth),
    [startupPreludeLines, transcriptLineWidth],
  );
  const transcriptLines = useMemo(
    () => flattenTranscript(transcriptMessages),
    [transcriptMessages],
  );
  const slashState = useMemo(
    () => computeSlashState(composerState.value, DEFAULT_PRAXIS_SLASH_COMMANDS),
    [composerState.value],
  );
  useEffect(() => {
    setSelectedSlashIndex((previous) => {
      if (slashState.suggestions.length === 0) {
        return 0;
      }
      return Math.min(previous, slashState.suggestions.length - 1);
    });
  }, [slashState.suggestions.length]);
  const commandPaletteItems = useMemo(
    () => slashState.suggestions.map((suggestion) => ({
      key: suggestion.displayText,
      label: suggestion.displayText,
      description: suggestion.description,
    })),
    [slashState.suggestions],
  );
  const showSlashMenu = slashState.active && slashState.suggestions.length > 0;
  const footerLineCount =
    (showSlashMenu ? commandPaletteItems.length + 1 : 0)
    + 1
    + composerLines.length
    + 1
    + 1
    + 1;
  const transcriptViewportLineCount = Math.max(6, terminalRows - footerLineCount);
  const transcriptScrollLines = useMemo(
    () => [...startupPreludeExpandedLines, ...expandRenderLinesForWidth(transcriptLines, transcriptLineWidth)],
    [startupPreludeExpandedLines, transcriptLineWidth, transcriptLines],
  );
  const maxScrollOffset = Math.max(0, transcriptScrollLines.length - transcriptViewportLineCount);
  useEffect(() => {
    const previous = previousTranscriptLineCountRef.current;
    const next = transcriptScrollLines.length;
    if (scrollOffset > 0 && next > previous) {
      setScrollOffset((current) => Math.min(maxScrollOffset, current + (next - previous)));
    }
    previousTranscriptLineCountRef.current = next;
  }, [maxScrollOffset, scrollOffset, transcriptScrollLines.length]);
  useEffect(() => {
    if (scrollOffset > maxScrollOffset) {
      setScrollOffset(maxScrollOffset);
    }
  }, [maxScrollOffset, scrollOffset]);
  const visibleTranscriptLines = useMemo(
    () => computeVisibleLines(transcriptScrollLines, transcriptViewportLineCount, scrollOffset),
    [scrollOffset, transcriptScrollLines, transcriptViewportLineCount],
  );
  const cwdLabel = shortenPath(process.cwd());
  const contextWindowSize = DEFAULT_CONTEXT_WINDOW;
  const estimatedContextUsed = useMemo(
    () =>
      transcriptMessages.reduce((sum, message) => sum + estimateContextUnits(message.text), 0)
      + estimateContextUnits(composerState.value),
    [composerState.value, transcriptMessages],
  );
  const contextRatio = Math.max(0, Math.min(1, estimatedContextUsed / contextWindowSize));
  const contextPercent = estimatedContextUsed === 0
    ? "0%"
    : contextRatio < 0.01
      ? "<1%"
      : `${Math.round(contextRatio * 100)}%`;
  const contextBar = useMemo(
    () => renderContextBar(estimatedContextUsed, contextWindowSize),
    [estimatedContextUsed, contextWindowSize],
  );
  const contextWindowLabel = formatContextWindowLabel(contextWindowSize);
  const composerCursor = measureComposerCursor(composerState.value, composerState.cursorOffset);
  const composerCursorRow = Math.max(
    1,
    terminalRows - 2 - ((composerLines.length - 1) - composerCursor.line),
  );
  const composerCursorColumn = Math.max(1, 5 + composerCursor.column);
  composerCursorParking.row = composerCursorRow;
  composerCursorParking.column = composerCursorColumn;
  composerCursorParking.active = true;

  useEffect(() => {
    composerCursorParking.active = true;
    return () => {
      composerCursorParking.active = false;
    };
  }, []);

  return (
    <Box flexDirection="column" paddingX={1} height={terminalRows}>
      <TranscriptPane
        visibleLines={visibleTranscriptLines}
        viewportLineCount={transcriptViewportLineCount}
      />
      <ComposerPane
        showSlashMenu={showSlashMenu}
        commandPaletteItems={commandPaletteItems}
        selectedSlashIndex={selectedSlashIndex}
        composerValue={composerState.value}
        composerLines={composerLines}
        workspaceLabel={cwdLabel}
        contextBar={contextBar}
        contextPercent={contextPercent}
        contextWindowLabel={contextWindowLabel}
        lineWidth={Math.max(1, terminalColumns - 2)}
      />
    </Box>
  );
}

render(<PraxisDirectTuiApp />, {
  stdout: inkCursorAwareStdout,
  stdin: process.stdin,
  stderr: process.stderr,
});
