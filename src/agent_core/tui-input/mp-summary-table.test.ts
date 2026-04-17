import assert from "node:assert/strict";
import test from "node:test";

import { buildMpSummaryTableLines } from "./mp-summary-table.js";

test("buildMpSummaryTableLines renders grouped summary sections as a wide table", () => {
  const rendered = buildMpSummaryTableLines({
    sections: [
      {
        title: "Route",
        rows: [
          { subtitle: "delivery_status", content: "available" },
          { subtitle: "source_class", content: "cmp_seeded_memory" },
        ],
      },
      {
        title: "Flow",
        rows: [
          { subtitle: "status", content: "ready" },
          { subtitle: "retrieval", content: "ready" },
        ],
      },
    ],
    lineWidth: 120,
    scrollX: 0,
  });

  const joined = rendered.lines.map((line) => line.text).join("\n");
  assert.match(joined, /Route/u);
  assert.match(joined, /Flow/u);
  assert.match(joined, /delivery_status/u);
  assert.match(joined, /cmp_seeded_memory/u);
  assert.equal(rendered.lines[0]?.segments?.[1]?.tone, "danger");
  assert.equal(rendered.lines[2]?.segments?.[1]?.tone, "orange");
  assert.equal(rendered.meta.scrollX, 0);
});

test("buildMpSummaryTableLines supports horizontal slicing when the table is wider than the viewport", () => {
  const rendered = buildMpSummaryTableLines({
    sections: [
      {
        title: "Route",
        rows: [
          { subtitle: "governance_reason", content: "repo-memory bootstrap fallback remains enabled while MP-native routing is being strengthened" },
        ],
      },
      {
        title: "Issue",
        rows: [
          { subtitle: "message", content: "No LanceDB memory records were found for the current project." },
        ],
      },
    ],
    lineWidth: 50,
    scrollX: 20,
  });

  assert.ok(rendered.meta.maxScrollX > 0);
  assert.equal(rendered.meta.scrollX, 20);
  assert.equal(rendered.lines[0]?.text.length > 0, true);
});
