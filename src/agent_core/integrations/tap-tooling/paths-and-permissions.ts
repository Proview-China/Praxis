import path from "node:path";

import type { AccessRequestScope } from "../../ta-pool-types/index.js";
import { matchPathPattern } from "./shared.js";

export function assertOperationAllowed(
  scope: AccessRequestScope | undefined,
  operationCandidates: string[],
): void {
  if (!scope?.allowedOperations || scope.allowedOperations.length === 0) {
    return;
  }

  if (!operationCandidates.some((candidate) => scope.allowedOperations?.includes(candidate))) {
    throw new Error(
      `Granted scope does not allow any of the required operations: ${operationCandidates.join(", ")}.`,
    );
  }
}

export function resolvePathWithinWorkspace(params: {
  workspaceRoot: string;
  candidatePath: string;
  scope?: AccessRequestScope;
  operationCandidates: string[];
  label: string;
}): { absolutePath: string; relativeWorkspacePath: string } {
  const workspaceRoot = path.resolve(params.workspaceRoot);
  const resolved = path.resolve(workspaceRoot, params.candidatePath);
  const relative = path.relative(workspaceRoot, resolved);
  if (!relative || relative === "") {
    const workspaceRelative = "workspace/";
    if (params.scope?.pathPatterns?.length) {
      const allowed = params.scope.pathPatterns.some((pattern) =>
        matchPathPattern(workspaceRelative, pattern)
      );
      if (!allowed) {
        throw new Error(
          `${params.label} ${params.candidatePath} is outside the granted workspace path patterns.`,
        );
      }
    }
    assertOperationAllowed(params.scope, params.operationCandidates);
    return {
      absolutePath: resolved,
      relativeWorkspacePath: ".",
    };
  }

  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`${params.label} ${params.candidatePath} escapes the workspace root.`);
  }

  const workspaceRelative = `workspace/${relative.split(path.sep).join("/")}`;
  if (params.scope?.denyPatterns?.some((pattern) => matchPathPattern(workspaceRelative, pattern))) {
    throw new Error(`${params.label} ${params.candidatePath} is denied by the granted scope.`);
  }
  if (params.scope?.pathPatterns?.length) {
    const allowed = params.scope.pathPatterns.some((pattern) =>
      matchPathPattern(workspaceRelative, pattern)
    );
    if (!allowed) {
      throw new Error(
        `${params.label} ${params.candidatePath} is outside the granted workspace path patterns.`,
      );
    }
  }

  assertOperationAllowed(params.scope, params.operationCandidates);
  return {
    absolutePath: resolved,
    relativeWorkspacePath: relative.split(path.sep).join("/"),
  };
}
