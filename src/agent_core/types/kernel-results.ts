import type { RunId, SessionId } from "./kernel-session.js";

export const KERNEL_RESULT_STATUSES = [
  "success",
  "partial",
  "failed",
  "blocked",
  "timeout",
  "cancelled"
] as const;
export type KernelResultStatus = (typeof KERNEL_RESULT_STATUSES)[number];

export type KernelResultSource = "kernel" | "model" | "capability";

export interface KernelError {
  code: string;
  message: string;
  retryable?: boolean;
  details?: Record<string, unknown>;
}

export interface KernelResultArtifact {
  id: string;
  kind: string;
  ref?: string;
  metadata?: Record<string, unknown>;
}

export interface KernelResult {
  resultId: string;
  sessionId: SessionId;
  runId: RunId;
  source: KernelResultSource;
  status: KernelResultStatus;
  output?: unknown;
  artifacts?: KernelResultArtifact[];
  evidence?: unknown[];
  error?: KernelError;
  emittedAt: string;
  correlationId?: string;
  metadata?: Record<string, unknown>;
}

export interface CapabilityPortResponse {
  requestId: string;
  intentId: string;
  sessionId: SessionId;
  runId: RunId;
  status: "accepted" | "queued" | "running" | "completed" | "failed" | "timed_out" | "cancelled";
  result?: KernelResult;
  output?: unknown;
  artifacts?: KernelResultArtifact[];
  evidence?: unknown[];
  error?: KernelError;
  completedAt?: string;
  metadata?: Record<string, unknown>;
}
