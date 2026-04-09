import { spawn } from "node:child_process";
import { appendFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

import { createCapabilityResultEnvelope } from "../../capability-result/index.js";
import type { TapToolingBaselineCapabilityKey } from "../../capability-package/index.js";
import type {
  CommandExecutionResult,
  NormalizedCommandInput,
  NormalizedRepoWriteEntry,
  ShellSessionRuntimeState,
  TodoEntry,
} from "./shared.js";

export const SHELL_SESSION_RUNTIME = new Map<string, ShellSessionRuntimeState>();
export const WRITE_TODOS_RUNTIME = new Map<string, TodoEntry[]>();

let shellSessionSequence = 0;

export function createShellSessionId(): string {
  shellSessionSequence += 1;
  return `shell-session-${shellSessionSequence}`;
}

export function createDefaultRepoWriteHandler() {
  return async (entries: NormalizedRepoWriteEntry[]): Promise<Array<Record<string, unknown>>> => {
    const results: Array<Record<string, unknown>> = [];
    for (const entry of entries) {
      if (entry.createParents) {
        await mkdir(path.dirname(entry.absolutePath), { recursive: true });
      }

      if (entry.mode === "mkdir") {
        await mkdir(entry.absolutePath, { recursive: true });
        results.push({
          mode: entry.mode,
          path: entry.relativeWorkspacePath,
        });
        continue;
      }

      if (entry.content === undefined) {
        throw new Error(`Repo write entry ${entry.relativeWorkspacePath} is missing content.`);
      }

      if (entry.mode === "append_text") {
        await appendFile(entry.absolutePath, entry.content, "utf8");
      } else {
        await writeFile(entry.absolutePath, entry.content, "utf8");
      }

      results.push({
        mode: entry.mode,
        path: entry.relativeWorkspacePath,
        bytesWritten: Buffer.byteLength(entry.content),
      });
    }
    return results;
  };
}

export function createDefaultCommandRunner() {
  return async (input: NormalizedCommandInput): Promise<CommandExecutionResult> => {
    return await new Promise<CommandExecutionResult>((resolve, reject) => {
      const child = spawn(input.command, input.args, {
        cwd: input.cwd,
        env: input.env ? { ...process.env, ...input.env } : process.env,
        stdio: ["ignore", "pipe", "pipe"],
      });

      let stdout = "";
      let stderr = "";
      let timedOut = false;
      const timer = setTimeout(() => {
        timedOut = true;
        child.kill("SIGTERM");
        setTimeout(() => {
          child.kill("SIGKILL");
        }, 250).unref();
      }, input.timeoutMs);

      child.stdout?.on("data", (chunk) => {
        stdout += chunk.toString();
      });
      child.stderr?.on("data", (chunk) => {
        stderr += chunk.toString();
      });
      child.on("error", (error) => {
        clearTimeout(timer);
        reject(error);
      });
      child.on("close", (exitCode, signal) => {
        clearTimeout(timer);
        resolve({
          exitCode,
          signal,
          stdout,
          stderr,
          timedOut,
        });
      });
    });
  };
}

export const DEFAULT_RESTRICTED_COMMAND_DENY_PATTERNS = [
  /^sudo$/i,
  /^rm$/i,
  /^dd$/i,
  /^mkfs/i,
];

export const DEFAULT_RESTRICTED_ARG_DENY_PATTERNS = [
  /^-rf$/,
  /^--no-preserve-root$/,
  /^--hard$/,
];

export const DEFAULT_TEST_COMMAND_ALLOWLIST = new Set([
  "npm",
  "pnpm",
  "yarn",
  "bun",
  "npx",
  "tsx",
  "vitest",
  "jest",
  "node",
]);

const SEARCH_COMMANDS = new Set(["rg", "grep", "find", "fd", "ag", "ack"]);
const READ_COMMANDS = new Set(["cat", "sed", "head", "tail", "less", "more"]);
const LIST_COMMANDS = new Set(["ls", "tree", "du"]);
const WRITE_COMMANDS = new Set(["cp", "mv", "touch", "mkdir", "ln"]);

export function summarizeCommand(
  command: string,
  args: string[],
  capabilityKey: TapToolingBaselineCapabilityKey,
): {
  summary: string;
  kind: "search" | "read" | "list" | "write" | "test" | "general";
} {
  const base = path.basename(command);
  const joined = [base, ...args].join(" ").trim();
  if (capabilityKey === "test.run") {
    return {
      summary: joined || base,
      kind: "test",
    };
  }
  if (SEARCH_COMMANDS.has(base)) {
    return { summary: joined || base, kind: "search" };
  }
  if (READ_COMMANDS.has(base)) {
    return { summary: joined || base, kind: "read" };
  }
  if (LIST_COMMANDS.has(base)) {
    return { summary: joined || base, kind: "list" };
  }
  if (WRITE_COMMANDS.has(base)) {
    return { summary: joined || base, kind: "write" };
  }
  return { summary: joined || base, kind: "general" };
}

export function trimCommandOutput(
  value: string,
  maxChars: number,
): { text: string; truncated: boolean; originalChars: number } {
  if (value.length <= maxChars) {
    return {
      text: value,
      truncated: false,
      originalChars: value.length,
    };
  }
  const head = Math.max(0, Math.floor(maxChars * 0.65));
  const tail = Math.max(0, maxChars - head - 32);
  return {
    text: `${value.slice(0, head)}\n...[truncated ${value.length - head - tail} chars]...\n${value.slice(Math.max(head, value.length - tail))}`,
    truncated: true,
    originalChars: value.length,
  };
}

async function waitForMs(value: number | undefined): Promise<void> {
  if (!value || value <= 0) {
    return;
  }
  await new Promise((resolve) => setTimeout(resolve, value));
}

export function drainSessionOutput(state: ShellSessionRuntimeState) {
  const stdout = trimCommandOutput(state.stdoutBuffer, state.maxOutputChars);
  const stderr = trimCommandOutput(state.stderrBuffer, state.maxOutputChars);
  state.stdoutBuffer = "";
  state.stderrBuffer = "";
  return { stdout, stderr };
}

export async function runSimpleCommand(
  commandRunner: (input: NormalizedCommandInput) => Promise<CommandExecutionResult>,
  input: NormalizedCommandInput,
) {
  return await commandRunner(input);
}

export function createGitCommandInput(params: {
  cwd: { absolutePath: string; relativeWorkspacePath: string };
  capabilityKey: "git.status" | "git.diff" | "git.commit" | "git.push" | "code.diff";
  args: string[];
  maxOutputChars: number;
}): NormalizedCommandInput {
  const summary = summarizeCommand("git", params.args, "shell.restricted");
  return {
    command: "git",
    args: params.args,
    cwd: params.cwd.absolutePath,
    relativeWorkspaceCwd: params.cwd.relativeWorkspacePath,
    timeoutMs: 15_000,
    runInBackground: false,
    tty: false,
    maxOutputChars: params.maxOutputChars,
    commandSummary: summary.summary,
    commandKind: summary.kind,
  };
}

export async function waitForShellSessionWindow(
  state: ShellSessionRuntimeState,
  yieldTimeMs?: number,
) {
  await waitForMs(yieldTimeMs ?? 0);
}

export function buildShellSessionEnvelope(params: {
  preparedId: string;
  state: ShellSessionRuntimeState;
  action: "start" | "poll" | "write" | "terminate";
}) {
  const drained = drainSessionOutput(params.state);
  const output = {
    sessionId: params.state.sessionId,
    action: params.action,
    state: params.state.closedAt === undefined ? "running" : params.state.exitCode === 0 ? "completed" : "failed",
    running: params.state.closedAt === undefined,
    completed: params.state.closedAt !== undefined,
    stdout: drained.stdout.text,
    stderr: drained.stderr.text,
    stdoutTruncated: drained.stdout.truncated,
    stderrTruncated: drained.stderr.truncated,
    stdoutChars: drained.stdout.originalChars,
    stderrChars: drained.stderr.originalChars,
    exitCode: params.state.exitCode,
    signal: params.state.signal,
    cwd: params.state.relativeWorkspaceCwd,
    commandSummary: params.state.commandSummary,
    commandKind: params.state.commandKind,
  };

  if ((params.state.exitCode ?? 0) !== 0 && params.action !== "terminate") {
    return createCapabilityResultEnvelope({
      executionId: params.preparedId,
      status: "failed",
      output,
      error: {
        code: "shell_session_non_zero_exit",
        message: `shell.session exited with code ${String(params.state.exitCode)}.`,
      },
      metadata: {
        capabilityKey: "shell.session",
        runtimeKind: "local-tooling",
        commandSummary: params.state.commandSummary,
        commandKind: params.state.commandKind,
      },
    });
  }

  return createCapabilityResultEnvelope({
    executionId: params.preparedId,
    status: "success",
    output,
    metadata: {
      capabilityKey: "shell.session",
      runtimeKind: "local-tooling",
      commandSummary: params.state.commandSummary,
      commandKind: params.state.commandKind,
    },
  });
}
