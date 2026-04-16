import {
  existsSync,
  mkdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { isAbsolute, join, resolve } from "node:path";

import {
  resolveSessionsDir,
  resolveWorkspaceRaxodeSessionsDir,
} from "../../runtime-paths.js";

export interface DirectTuiSessionMessageRecord {
  messageId: string;
  kind: string;
  text: string;
  createdAt: string;
  turnId?: string;
  status?: string;
  updatedAt?: string;
  metadata?: Record<string, unknown>;
  capabilityKey?: string;
  title?: string;
  errorCode?: string;
}

export interface DirectTuiSessionUsageEntry {
  requestId: string;
  turnId?: string;
  kind: "core_action" | "core_model" | "core_turn" | "session";
  provider?: string;
  model?: string;
  reasoningEffort?: string;
  status: "success" | "failed" | "blocked" | "cancelled";
  inputTokens?: number;
  outputTokens?: number;
  thinkingTokens?: number;
  startedAt: string;
  endedAt: string;
  estimated?: boolean;
  errorCode?: string;
}

export interface DirectTuiSessionExitSummary {
  inputTokens: number;
  outputTokens: number;
  thinkingTokens: number;
  requestCount: number;
  successCount: number;
  successRate: number;
  totalPriceUsd?: number;
  estimatedPrice: boolean;
  resumeSelector: string;
  generatedAt: string;
}

export interface DirectTuiAgentSnapshot {
  agentId: string;
  name: string;
  kind: "core" | "task";
  status: string;
  summary: string;
  createdAt: string;
  updatedAt: string;
  sourceTaskId?: string;
  capabilityKey?: string;
}

export interface DirectTuiAgentRegistryRecord extends DirectTuiAgentSnapshot {
  workspace: string;
  lastSessionId?: string;
}

export interface DirectTuiSessionSnapshot {
  schemaVersion: 1;
  sessionId: string;
  agentId: string;
  name: string;
  workspace: string;
  route: string;
  model: string;
  createdAt: string;
  updatedAt: string;
  selectedAgentId?: string;
  agents: DirectTuiAgentSnapshot[];
  agentLabels?: Record<string, string>;
  compiledInitPreamble?: string;
  initArtifactPath?: string;
  messages: DirectTuiSessionMessageRecord[];
  usageLedger?: DirectTuiSessionUsageEntry[];
  exitSummary?: DirectTuiSessionExitSummary;
}

export interface DirectTuiDialogueTurnRecord {
  role: "user" | "assistant";
  text: string;
}

export interface DirectTuiSessionIndexRecord {
  sessionId: string;
  agentId?: string;
  name: string;
  workspace: string;
  route: string;
  model: string;
  createdAt: string;
  updatedAt: string;
  selectedAgentId?: string;
  lastAssistantText?: string;
  messageCount: number;
  exitSummaryPreview?: Pick<
    DirectTuiSessionExitSummary,
    "successRate" | "requestCount" | "totalPriceUsd" | "resumeSelector" | "generatedAt"
  >;
}

interface DirectTuiSessionIndexFile {
  schemaVersion: 1;
  sessions: DirectTuiSessionIndexRecord[];
}

interface DirectTuiAgentRegistryFile {
  schemaVersion: 1;
  agents: DirectTuiAgentRegistryRecord[];
}

function isUsableWorkspacePath(value: string): boolean {
  if (!value || !isAbsolute(value) || /[\u0000-\u001f\u007f-\u009f\uFFFD]/u.test(value)) {
    return false;
  }
  try {
    return statSync(value).isDirectory();
  } catch {
    return false;
  }
}

function sanitizeWorkspacePath(workspace: string | undefined, fallbackDir: string): string {
  if (typeof workspace === "string") {
    const trimmed = workspace.trim();
    if (isUsableWorkspacePath(trimmed)) {
      return trimmed;
    }
  }
  return resolve(fallbackDir);
}

function resolveWorkspaceSessionsDir(fallbackDir = process.cwd()): string {
  return resolveWorkspaceRaxodeSessionsDir(fallbackDir);
}

function resolveLegacySessionsDir(fallbackDir = process.cwd()): string {
  return resolveSessionsDir(fallbackDir);
}

function ensureSessionsDir(fallbackDir = process.cwd()): string {
  const directory = resolveWorkspaceSessionsDir(fallbackDir);
  mkdirSync(directory, { recursive: true });
  return directory;
}

function indexPath(fallbackDir = process.cwd(), legacy = false): string {
  const directory = legacy ? resolveLegacySessionsDir(fallbackDir) : ensureSessionsDir(fallbackDir);
  return join(directory, legacy ? "direct-tui-index.json" : "index.json");
}

function snapshotPath(sessionId: string, fallbackDir = process.cwd(), legacy = false): string {
  const directory = legacy ? resolveLegacySessionsDir(fallbackDir) : ensureSessionsDir(fallbackDir);
  return join(directory, `${encodeURIComponent(sessionId)}.json`);
}

export function resolveDirectTuiSessionSnapshotPath(
  sessionId: string,
  fallbackDir = process.cwd(),
): string {
  return snapshotPath(sessionId, fallbackDir);
}

function normalizeDirectTuiSessionSelector(selector: string): string {
  return selector.trim().toLowerCase();
}

function agentsPath(fallbackDir = process.cwd(), legacy = false): string {
  const directory = legacy ? resolveLegacySessionsDir(fallbackDir) : ensureSessionsDir(fallbackDir);
  return join(directory, "direct-tui-agents.json");
}

function loadIndexFile(fallbackDir = process.cwd()): DirectTuiSessionIndexFile {
  const workspacePath = indexPath(fallbackDir);
  if (!existsSync(workspacePath)) {
    const legacyPath = indexPath(fallbackDir, true);
    if (!existsSync(legacyPath)) {
      return {
        schemaVersion: 1,
        sessions: [],
      };
    }
    const parsed = JSON.parse(readFileSync(legacyPath, "utf8")) as Partial<DirectTuiSessionIndexFile>;
    return {
      schemaVersion: 1,
      sessions: Array.isArray(parsed.sessions)
        ? parsed.sessions.filter((entry): entry is DirectTuiSessionIndexRecord =>
          Boolean(entry)
          && typeof entry === "object"
          && typeof (entry as DirectTuiSessionIndexRecord).sessionId === "string"
          && typeof (entry as DirectTuiSessionIndexRecord).workspace === "string"
          && (entry as DirectTuiSessionIndexRecord).workspace === fallbackDir)
        : [],
    };
  }
  const parsed = JSON.parse(readFileSync(workspacePath, "utf8")) as Partial<DirectTuiSessionIndexFile>;
  return {
    schemaVersion: 1,
    sessions: Array.isArray(parsed.sessions) ? parsed.sessions : [],
  };
}

function writeIndexFile(file: DirectTuiSessionIndexFile, fallbackDir = process.cwd()): void {
  writeFileSync(indexPath(fallbackDir), `${JSON.stringify(file, null, 2)}\n`, "utf8");
}

export function listDirectTuiSessions(fallbackDir = process.cwd()): DirectTuiSessionIndexRecord[] {
  return loadIndexFile(fallbackDir).sessions
    .map((record) => {
      if (record.agentId) {
        return record;
      }
      const snapshot = loadDirectTuiSessionSnapshot(record.sessionId, fallbackDir);
      return {
        ...record,
        agentId: snapshot?.agentId,
      };
    })
    .slice()
    .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
}

export function buildDirectTuiResumeSelector(
  session: Pick<DirectTuiSessionIndexRecord, "sessionId" | "name">,
  sessions: readonly Pick<DirectTuiSessionIndexRecord, "sessionId" | "name">[],
): string {
  const normalizedName = session.name.trim();
  if (!normalizedName || /\s/u.test(normalizedName)) {
    return session.sessionId;
  }
  const sameNameCount = sessions.filter((entry) => entry.name.trim() === normalizedName).length;
  return sameNameCount === 1 ? normalizedName : session.sessionId;
}

export function resolveDirectTuiSessionSelection(
  selector: string | undefined,
  fallbackDir = process.cwd(),
): {
  status: "selected" | "not_found" | "ambiguous" | "empty";
  selector?: string;
  session?: DirectTuiSessionIndexRecord;
  candidates?: DirectTuiSessionIndexRecord[];
} {
  const sessions = listDirectTuiSessions(fallbackDir);
  if (!selector || selector.trim().length === 0) {
    return { status: "empty" };
  }
  const normalizedSelector = normalizeDirectTuiSessionSelector(selector);
  const exactId = sessions.find((entry) => entry.sessionId.toLowerCase() === normalizedSelector);
  if (exactId) {
    return {
      status: "selected",
      selector: exactId.sessionId,
      session: exactId,
    };
  }
  const exactNameMatches = sessions.filter((entry) =>
    normalizeDirectTuiSessionSelector(entry.name) === normalizedSelector);
  if (exactNameMatches.length === 1) {
    return {
      status: "selected",
      selector: exactNameMatches[0]?.name,
      session: exactNameMatches[0],
    };
  }
  if (exactNameMatches.length > 1) {
    return {
      status: "ambiguous",
      selector,
      candidates: exactNameMatches,
    };
  }
  const idPrefixMatches = sessions.filter((entry) => entry.sessionId.toLowerCase().startsWith(normalizedSelector));
  if (idPrefixMatches.length === 1) {
    return {
      status: "selected",
      selector,
      session: idPrefixMatches[0],
    };
  }
  if (idPrefixMatches.length > 1) {
    return {
      status: "ambiguous",
      selector,
      candidates: idPrefixMatches,
    };
  }
  const namePrefixMatches = sessions.filter((entry) =>
    normalizeDirectTuiSessionSelector(entry.name).startsWith(normalizedSelector));
  if (namePrefixMatches.length === 1) {
    return {
      status: "selected",
      selector,
      session: namePrefixMatches[0],
    };
  }
  if (namePrefixMatches.length > 1) {
    return {
      status: "ambiguous",
      selector,
      candidates: namePrefixMatches,
    };
  }
  return {
    status: "not_found",
    selector,
  };
}

function loadAgentsFile(fallbackDir = process.cwd()): DirectTuiAgentRegistryFile {
  const workspacePath = agentsPath(fallbackDir);
  if (!existsSync(workspacePath)) {
    const legacyPath = agentsPath(fallbackDir, true);
    if (!existsSync(legacyPath)) {
      return {
        schemaVersion: 1,
        agents: [],
      };
    }
    const parsed = JSON.parse(readFileSync(legacyPath, "utf8")) as Partial<DirectTuiAgentRegistryFile>;
    return {
      schemaVersion: 1,
      agents: Array.isArray(parsed.agents)
        ? parsed.agents.filter((entry): entry is DirectTuiAgentRegistryRecord =>
          Boolean(entry)
          && typeof entry === "object"
          && typeof (entry as DirectTuiAgentRegistryRecord).agentId === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).workspace === "string"
          && (entry as DirectTuiAgentRegistryRecord).workspace === fallbackDir
          && typeof (entry as DirectTuiAgentRegistryRecord).name === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).kind === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).status === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).summary === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).createdAt === "string"
          && typeof (entry as DirectTuiAgentRegistryRecord).updatedAt === "string")
        : [],
    };
  }
  const parsed = JSON.parse(readFileSync(workspacePath, "utf8")) as Partial<DirectTuiAgentRegistryFile>;
  return {
    schemaVersion: 1,
    agents: Array.isArray(parsed.agents)
      ? parsed.agents.filter((entry): entry is DirectTuiAgentRegistryRecord =>
        Boolean(entry)
        && typeof entry === "object"
        && typeof (entry as DirectTuiAgentRegistryRecord).agentId === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).name === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).kind === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).status === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).summary === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).workspace === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).createdAt === "string"
        && typeof (entry as DirectTuiAgentRegistryRecord).updatedAt === "string")
      : [],
  };
}

function writeAgentsFile(file: DirectTuiAgentRegistryFile, fallbackDir = process.cwd()): void {
  writeFileSync(agentsPath(fallbackDir), `${JSON.stringify(file, null, 2)}\n`, "utf8");
}

export function listDirectTuiAgents(fallbackDir = process.cwd()): DirectTuiAgentRegistryRecord[] {
  return loadAgentsFile(fallbackDir).agents
    .slice()
    .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
}

export function saveDirectTuiAgent(
  agent: DirectTuiAgentRegistryRecord,
  fallbackDir = process.cwd(),
): void {
  const normalizedAgent: DirectTuiAgentRegistryRecord = {
    ...agent,
    workspace: sanitizeWorkspacePath(agent.workspace, fallbackDir),
  };
  const file = loadAgentsFile(fallbackDir);
  const nextAgents = file.agents.filter((entry) => entry.agentId !== normalizedAgent.agentId);
  nextAgents.push(normalizedAgent);
  writeAgentsFile({
    schemaVersion: 1,
    agents: nextAgents,
  }, fallbackDir);
}

export function renameDirectTuiAgent(
  agentId: string,
  name: string,
  fallbackDir = process.cwd(),
): void {
  const file = loadAgentsFile(fallbackDir);
  const nextAgents = file.agents.map((agent) => agent.agentId === agentId
    ? {
      ...agent,
      name,
      updatedAt: new Date().toISOString(),
    }
    : agent);
  writeAgentsFile({
    schemaVersion: 1,
    agents: nextAgents,
  }, fallbackDir);
}

export function loadDirectTuiSessionSnapshot(
  sessionId: string,
  fallbackDir = process.cwd(),
): DirectTuiSessionSnapshot | null {
  const workspacePath = snapshotPath(sessionId, fallbackDir);
  const legacyPath = snapshotPath(sessionId, fallbackDir, true);
  const filePath = existsSync(workspacePath)
    ? workspacePath
    : (existsSync(legacyPath) ? legacyPath : null);
  if (!filePath) {
    return null;
  }
  const parsed = JSON.parse(readFileSync(filePath, "utf8")) as Partial<DirectTuiSessionSnapshot>;
  const workspace = sanitizeWorkspacePath(
    typeof parsed.workspace === "string" ? parsed.workspace : undefined,
    fallbackDir,
  );
  if (filePath === legacyPath && workspace !== resolve(fallbackDir)) {
    return null;
  }
  return {
    schemaVersion: 1,
    sessionId,
    agentId: typeof parsed.agentId === "string" && parsed.agentId.trim()
      ? parsed.agentId
      : (typeof parsed.selectedAgentId === "string" && parsed.selectedAgentId.trim()
        ? parsed.selectedAgentId
        : `agent.core:main`),
    name: typeof parsed.name === "string" && parsed.name.trim() ? parsed.name : sessionId,
    workspace,
    route: typeof parsed.route === "string" ? parsed.route : "",
    model: typeof parsed.model === "string" ? parsed.model : "",
    createdAt: typeof parsed.createdAt === "string" ? parsed.createdAt : new Date().toISOString(),
    updatedAt: typeof parsed.updatedAt === "string" ? parsed.updatedAt : new Date().toISOString(),
    selectedAgentId: typeof parsed.selectedAgentId === "string" ? parsed.selectedAgentId : undefined,
    agents: Array.isArray(parsed.agents)
      ? parsed.agents.filter((entry): entry is DirectTuiAgentSnapshot =>
        Boolean(entry)
        && typeof entry === "object"
        && typeof (entry as DirectTuiAgentSnapshot).agentId === "string"
        && typeof (entry as DirectTuiAgentSnapshot).name === "string"
        && typeof (entry as DirectTuiAgentSnapshot).kind === "string"
        && typeof (entry as DirectTuiAgentSnapshot).status === "string"
        && typeof (entry as DirectTuiAgentSnapshot).summary === "string"
        && typeof (entry as DirectTuiAgentSnapshot).createdAt === "string"
        && typeof (entry as DirectTuiAgentSnapshot).updatedAt === "string")
      : [],
    agentLabels: parsed.agentLabels && typeof parsed.agentLabels === "object" ? parsed.agentLabels as Record<string, string> : undefined,
    compiledInitPreamble: typeof parsed.compiledInitPreamble === "string" ? parsed.compiledInitPreamble : undefined,
    initArtifactPath: typeof parsed.initArtifactPath === "string" ? parsed.initArtifactPath : undefined,
    messages: Array.isArray(parsed.messages)
      ? parsed.messages.flatMap((entry) => {
        if (
          !entry
          || typeof entry !== "object"
          || typeof (entry as DirectTuiSessionMessageRecord).messageId !== "string"
          || typeof (entry as DirectTuiSessionMessageRecord).kind !== "string"
          || typeof (entry as DirectTuiSessionMessageRecord).text !== "string"
          || typeof (entry as DirectTuiSessionMessageRecord).createdAt !== "string"
        ) {
          return [];
        }
        const record = entry as DirectTuiSessionMessageRecord;
        return [{
          messageId: record.messageId,
          kind: record.kind,
          text: record.text,
          createdAt: record.createdAt,
          turnId: typeof record.turnId === "string" ? record.turnId : undefined,
          status: typeof record.status === "string" ? record.status : undefined,
          updatedAt: typeof record.updatedAt === "string" ? record.updatedAt : undefined,
          metadata: record.metadata && typeof record.metadata === "object"
            ? { ...record.metadata }
            : undefined,
          capabilityKey: typeof record.capabilityKey === "string" ? record.capabilityKey : undefined,
          title: typeof record.title === "string" ? record.title : undefined,
          errorCode: typeof record.errorCode === "string" ? record.errorCode : undefined,
        }];
      })
      : [],
    usageLedger: Array.isArray(parsed.usageLedger)
      ? parsed.usageLedger.flatMap((entry): DirectTuiSessionUsageEntry[] => {
        if (
          !entry
          || typeof entry !== "object"
          || typeof (entry as DirectTuiSessionUsageEntry).requestId !== "string"
          || typeof (entry as DirectTuiSessionUsageEntry).kind !== "string"
          || typeof (entry as DirectTuiSessionUsageEntry).status !== "string"
          || typeof (entry as DirectTuiSessionUsageEntry).startedAt !== "string"
          || typeof (entry as DirectTuiSessionUsageEntry).endedAt !== "string"
        ) {
          return [];
        }
        const record = entry as DirectTuiSessionUsageEntry;
        return [{
          requestId: record.requestId,
          turnId: typeof record.turnId === "string" ? record.turnId : undefined,
          kind: record.kind,
          provider: typeof record.provider === "string" ? record.provider : undefined,
          model: typeof record.model === "string" ? record.model : undefined,
          reasoningEffort: typeof record.reasoningEffort === "string" ? record.reasoningEffort : undefined,
          status: record.status,
          inputTokens: typeof record.inputTokens === "number" ? record.inputTokens : undefined,
          outputTokens: typeof record.outputTokens === "number" ? record.outputTokens : undefined,
          thinkingTokens: typeof record.thinkingTokens === "number" ? record.thinkingTokens : undefined,
          startedAt: record.startedAt,
          endedAt: record.endedAt,
          estimated: record.estimated === true,
          errorCode: typeof record.errorCode === "string" ? record.errorCode : undefined,
        }];
      })
      : [],
    exitSummary: parsed.exitSummary && typeof parsed.exitSummary === "object"
      ? (() => {
        const summary = parsed.exitSummary as Partial<DirectTuiSessionExitSummary>;
        if (
          typeof summary.inputTokens !== "number"
          || typeof summary.outputTokens !== "number"
          || typeof summary.thinkingTokens !== "number"
          || typeof summary.requestCount !== "number"
          || typeof summary.successCount !== "number"
          || typeof summary.successRate !== "number"
          || typeof summary.estimatedPrice !== "boolean"
          || typeof summary.resumeSelector !== "string"
          || typeof summary.generatedAt !== "string"
        ) {
          return undefined;
        }
        return {
          inputTokens: summary.inputTokens,
          outputTokens: summary.outputTokens,
          thinkingTokens: summary.thinkingTokens,
          requestCount: summary.requestCount,
          successCount: summary.successCount,
          successRate: summary.successRate,
          totalPriceUsd: typeof summary.totalPriceUsd === "number" ? summary.totalPriceUsd : undefined,
          estimatedPrice: summary.estimatedPrice,
          resumeSelector: summary.resumeSelector,
          generatedAt: summary.generatedAt,
        } satisfies DirectTuiSessionExitSummary;
      })()
      : undefined,
  };
}

export function restoreDirectTuiDialogueTurnsFromSnapshot(
  snapshot: DirectTuiSessionSnapshot,
): DirectTuiDialogueTurnRecord[] {
  return snapshot.messages.flatMap((message): DirectTuiDialogueTurnRecord[] => {
    if ((message.kind !== "user" && message.kind !== "assistant") || message.text.trim().length === 0) {
      return [];
    }
    return [{
      role: message.kind,
      text: message.text,
    }];
  });
}

export function resolveDirectTuiSnapshotTurnIndex(
  snapshot: DirectTuiSessionSnapshot,
): number {
  const turnIndices = snapshot.messages.flatMap((message) => {
    if (typeof message.turnId !== "string") {
      return [];
    }
    const match = message.turnId.match(/^turn-(\d+)$/u);
    if (!match) {
      return [];
    }
    const value = Number.parseInt(match[1] ?? "", 10);
    return Number.isFinite(value) ? [value] : [];
  });
  if (turnIndices.length > 0) {
    return Math.max(...turnIndices);
  }
  return snapshot.messages.filter((message) => message.kind === "user").length;
}

export function saveDirectTuiSessionSnapshot(
  snapshot: DirectTuiSessionSnapshot,
  fallbackDir = process.cwd(),
): void {
  const normalizedSnapshot: DirectTuiSessionSnapshot = {
    ...snapshot,
    workspace: sanitizeWorkspacePath(snapshot.workspace, fallbackDir),
    agents: snapshot.agents.slice(),
  };
  if (normalizedSnapshot.agentLabels && Object.keys(normalizedSnapshot.agentLabels).length === 0) {
    delete normalizedSnapshot.agentLabels;
  }
  writeFileSync(snapshotPath(snapshot.sessionId, fallbackDir), `${JSON.stringify(normalizedSnapshot, null, 2)}\n`, "utf8");
  const index = loadIndexFile(fallbackDir);
  const record: DirectTuiSessionIndexRecord = {
    sessionId: snapshot.sessionId,
    agentId: snapshot.agentId,
    name: snapshot.name,
    workspace: snapshot.workspace,
    route: snapshot.route,
    model: snapshot.model,
    createdAt: snapshot.createdAt,
    updatedAt: snapshot.updatedAt,
    selectedAgentId: snapshot.selectedAgentId,
    lastAssistantText: [...snapshot.messages].reverse().find((message) => message.kind === "assistant")?.text,
    messageCount: snapshot.messages.length,
    exitSummaryPreview: snapshot.exitSummary
      ? {
        successRate: snapshot.exitSummary.successRate,
        requestCount: snapshot.exitSummary.requestCount,
        totalPriceUsd: snapshot.exitSummary.totalPriceUsd,
        resumeSelector: snapshot.exitSummary.resumeSelector,
        generatedAt: snapshot.exitSummary.generatedAt,
      }
      : undefined,
  };
  const nextSessions = index.sessions.filter((entry) => entry.sessionId !== snapshot.sessionId);
  nextSessions.push(record);
  writeIndexFile({
    schemaVersion: 1,
    sessions: nextSessions,
  }, fallbackDir);
}

export function renameDirectTuiSession(
  sessionId: string,
  name: string,
  fallbackDir = process.cwd(),
): void {
  const snapshot = loadDirectTuiSessionSnapshot(sessionId, fallbackDir);
  if (!snapshot) {
    return;
  }
  saveDirectTuiSessionSnapshot({
    ...snapshot,
    name,
    updatedAt: new Date().toISOString(),
  }, fallbackDir);
}
