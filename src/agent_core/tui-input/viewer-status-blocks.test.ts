import assert from "node:assert/strict";
import test from "node:test";

import {
  buildViewerStatusBlockLines,
  buildViewerStatusGridLines,
  isViewerStatusTextAbnormal,
  isViewerStatusValueAbnormal,
  parseViewerAssignmentEntries,
  parseViewerRoleEntries,
} from "./viewer-status-blocks.js";

test("parseViewerAssignmentEntries splits compact readiness values into stacked entries", () => {
  assert.deepEqual(
    parseViewerAssignmentEntries("object=ready loop=ready llm=ready infra=ready final=ready"),
    [
      { key: "object", value: "ready", abnormal: false },
      { key: "loop", value: "ready", abnormal: false },
      { key: "llm", value: "ready", abnormal: false },
      { key: "infra", value: "ready", abnormal: false },
      { key: "final", value: "ready", abnormal: false },
    ],
  );
});

test("parseViewerRoleEntries derives role status and marks idle unknown as abnormal", () => {
  assert.deepEqual(
    parseViewerRoleEntries([
      "icma: count=0 stage=idle live=unknown",
      "checker: count=2 stage=checked live=succeeded",
    ]),
    [
      { key: "icma", value: "idle/unknown", abnormal: true },
      { key: "checker", value: "checked/succeeded", abnormal: false },
    ],
  );
});

test("status heuristics treat unknown and degraded as abnormal but ready as healthy", () => {
  assert.equal(isViewerStatusValueAbnormal("ready"), false);
  assert.equal(isViewerStatusValueAbnormal("idle/unknown"), true);
  assert.equal(isViewerStatusTextAbnormal("CMP five-agent runtime has roles without observed activity yet."), true);
  assert.equal(isViewerStatusTextAbnormal("LanceDB-backed MP memory records are available."), false);
});

test("buildViewerStatusBlockLines colors the label and abnormal values separately", () => {
  const lines = buildViewerStatusBlockLines({
    label: "Ready",
    labelTone: "pink",
    entries: [
      { key: "object", value: "ready", abnormal: false },
      { key: "loop", value: "degraded", abnormal: true },
    ],
    lineWidth: 60,
  });

  assert.equal(lines.length, 3);
  assert.equal(lines[0]?.segments?.[1]?.tone, "pink");
  assert.equal(lines[1]?.segments?.[2]?.tone, undefined);
  assert.equal(lines[2]?.segments?.[2]?.tone, "danger");
  assert.match(lines[1]?.text ?? "", /object=ready/u);
  assert.match(lines[2]?.text ?? "", /loop=degraded/u);
});

test("buildViewerStatusGridLines packs viewer entries horizontally when width allows", () => {
  const lines = buildViewerStatusGridLines({
    label: "Route",
    labelTone: "info",
    entries: [
      { key: "delivery_status", value: "available", abnormal: false },
      { key: "source_class", value: "cmp_seeded_memory", abnormal: false },
      { key: "candidate_intake", value: "2", abnormal: false },
      { key: "rejected", value: "1", abnormal: true },
    ],
    lineWidth: 100,
  });

  assert.equal(lines.length, 3);
  assert.equal(lines[0]?.segments?.[1]?.tone, "info");
  assert.match(lines[1]?.text ?? "", /delivery_status=available/u);
  assert.match(lines[1]?.text ?? "", /source_class=cmp_seeded_memory/u);
  assert.match(lines[2]?.text ?? "", /candidate_intake=2/u);
  assert.match(lines[2]?.text ?? "", /rejected=1/u);
});
