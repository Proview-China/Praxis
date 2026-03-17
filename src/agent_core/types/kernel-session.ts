export type SessionId = string;
export type RunId = string;
export type CheckpointId = string;
export type JournalCursor = string;
export type KernelVersion = number;

export const SESSION_STATUSES = [
  "idle",
  "active",
  "paused",
  "archived"
] as const;
export type SessionStatus = (typeof SESSION_STATUSES)[number];

export interface SessionHeader {
  sessionId: SessionId;
  status: SessionStatus;
  activeRunId?: RunId;
  runIds: RunId[];
  lastCheckpointRef?: CheckpointId;
  lastJournalCursor?: JournalCursor;
  version: KernelVersion;
  createdAt: string;
  updatedAt: string;
  coldLogRef?: string;
  metadata?: Record<string, unknown>;
}
