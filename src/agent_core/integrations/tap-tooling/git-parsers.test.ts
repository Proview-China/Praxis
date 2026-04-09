import assert from "node:assert/strict";
import test from "node:test";

import { parseGitDiffFiles, parseGitStatusEntries } from "./git-parsers.js";

test("parseGitStatusEntries keeps branch metadata and truncation signal", () => {
  const parsed = parseGitStatusEntries(
    [
      "## integrate/dev-master-cmp...origin/integrate/dev-master-cmp",
      " M src/index.ts",
      "?? src/new-file.ts",
    ].join("\n"),
    1,
  );

  assert.equal(parsed.branch, "integrate/dev-master-cmp...origin/integrate/dev-master-cmp");
  assert.deepEqual(parsed.entries, [
    {
      code: " M",
      path: "src/index.ts",
    },
  ]);
  assert.equal(parsed.truncated, true);
});

test("parseGitDiffFiles extracts unique file paths from unified diff", () => {
  const files = parseGitDiffFiles(
    [
      "diff --git a/src/a.ts b/src/a.ts",
      "index 0000000..1111111 100644",
      "--- a/src/a.ts",
      "+++ b/src/a.ts",
      "diff --git a/src/b.ts b/src/b.ts",
      "index 2222222..3333333 100644",
      "--- a/src/b.ts",
      "+++ b/src/b.ts",
      "diff --git a/src/a.ts b/src/a.ts",
    ].join("\n"),
  );

  assert.deepEqual(files, ["src/a.ts", "src/b.ts"]);
});
