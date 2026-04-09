import type { GitStatusEntry } from "./shared.js";
import { normalizeNewlines } from "./shared.js";

export function parseGitStatusEntries(output: string, maxEntries: number): {
  branch?: string;
  entries: GitStatusEntry[];
  truncated: boolean;
} {
  const lines = normalizeNewlines(output).split("\n").filter((line) => line.length > 0);
  const branch = lines[0]?.startsWith("## ") ? lines[0].slice(3) : undefined;
  const statusLines = branch ? lines.slice(1) : lines;
  const entries = statusLines.slice(0, maxEntries).map((line) => ({
    code: line.slice(0, 2),
    path: line.slice(3),
  }));
  return {
    branch,
    entries,
    truncated: statusLines.length > maxEntries,
  };
}

export function parseGitDiffFiles(output: string): string[] {
  const files = new Set<string>();
  for (const match of normalizeNewlines(output).matchAll(/^diff --git a\/(.+?) b\/.+$/gm)) {
    if (match[1]) {
      files.add(match[1]);
    }
  }
  return [...files];
}
