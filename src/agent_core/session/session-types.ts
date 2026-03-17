import type { CheckpointId, JournalCursor, RunId, SessionHeader, SessionId, SessionStatus } from "../types/index.js";

export interface CreateSessionInput {
  sessionId?: SessionId;
  status?: SessionStatus;
  activeRunId?: RunId;
  runIds?: RunId[];
  lastCheckpointRef?: CheckpointId;
  lastJournalCursor?: JournalCursor;
  coldLogRef?: string;
  metadata?: Record<string, unknown>;
}

export interface SessionHeaderPatch {
  status?: SessionStatus;
  activeRunId?: RunId | undefined;
  lastCheckpointRef?: CheckpointId | undefined;
  lastJournalCursor?: JournalCursor | undefined;
  coldLogRef?: string | undefined;
  metadata?: Record<string, unknown>;
}

export interface AttachRunInput {
  sessionId: SessionId;
  runId: RunId;
  makeActive?: boolean;
}

export interface MarkCheckpointInput {
  sessionId: SessionId;
  checkpointId: CheckpointId;
  journalCursor?: JournalCursor;
}

export interface SessionColdLogRecord {
  sessionId: SessionId;
  coldLogRef: string;
  header: SessionHeader;
  archivedAt: string;
}

export interface SessionEvictionResult {
  sessionId: SessionId;
  coldLogRef: string;
  archivedAt: string;
}

export interface SessionManagerClock {
  now(): Date;
}

export interface SessionManagerIdFactory {
  createSessionId(): SessionId;
  createColdLogRef(sessionId: SessionId): string;
}
