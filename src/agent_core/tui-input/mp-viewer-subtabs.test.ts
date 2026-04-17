import assert from "node:assert/strict";
import test from "node:test";

import {
  buildMpViewerHints,
  cycleMpViewerSubtab,
  resolveMpViewerSubtab,
} from "./mp-viewer-subtabs.js";

test("resolveMpViewerSubtab defaults to summary and keeps records when requested", () => {
  assert.equal(resolveMpViewerSubtab(undefined), "summary");
  assert.equal(resolveMpViewerSubtab("summary"), "summary");
  assert.equal(resolveMpViewerSubtab("records"), "records");
  assert.equal(resolveMpViewerSubtab("other"), "summary");
});

test("cycleMpViewerSubtab toggles between summary and records", () => {
  assert.equal(cycleMpViewerSubtab("summary"), "records");
  assert.equal(cycleMpViewerSubtab("records"), "summary");
});

test("buildMpViewerHints keeps summary and records hints distinct", () => {
  assert.deepEqual(buildMpViewerHints("summary"), [
    "press TAB to switch panel",
    "press ← to scroll left • press → to scroll right",
    "press ENTER to refresh current memory state",
    "press ESC to return to previous page",
  ]);
  assert.deepEqual(buildMpViewerHints("records"), [
    "press TAB to switch panel",
    "press ← to previous page • press → to next page",
    "press ENTER to refresh current memory state",
    "press ESC to return to previous page",
  ]);
});
