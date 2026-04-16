import assert from "node:assert/strict";
import test from "node:test";

import { buildTerminalTableBodyLines } from "./viewer-table-layout.js";

test("buildTerminalTableBodyLines renders a compact header, separator, and rows", () => {
  const lines = buildTerminalTableBodyLines({
    columns: [
      {
        key: "family",
        title: "Family",
        minWidth: 6,
        maxWidth: 10,
        value: (row: { family: string }) => row.family,
      },
      {
        key: "capability",
        title: "Capability Key",
        minWidth: 14,
        maxWidth: 24,
        value: (row: { capability: string }) => row.capability,
      },
      {
        key: "description",
        title: "Description",
        minWidth: 16,
        value: (row: { description: string }) => row.description,
      },
    ],
    rows: [{
      key: "row-1",
      data: {
        family: "mp",
        capability: "mp.search",
        description: "Retrieve memory records relevant to the current task.",
      },
    }],
    lineWidth: 72,
  });

  assert.equal(lines.length, 3);
  assert.match(lines[0]?.text ?? "", /Family\s+│\s+Capability Key\s+│\s+Description/u);
  assert.match(lines[1]?.text ?? "", /─┼─/u);
  assert.match(lines[2]?.text ?? "", /mp/u);
  assert.match(lines[2]?.text ?? "", /mp\.search/u);
});

test("buildTerminalTableBodyLines truncates flex columns on narrow widths", () => {
  const lines = buildTerminalTableBodyLines({
    columns: [
      {
        key: "memory",
        title: "Memory Ref",
        minWidth: 10,
        maxWidth: 14,
        shrinkPriority: 3,
        value: (row: { memory: string }) => row.memory,
      },
      {
        key: "summary",
        title: "Summary",
        minWidth: 12,
        shrinkPriority: 1,
        value: (row: { summary: string }) => row.summary,
      },
    ],
    rows: [{
      key: "row-1",
      data: {
        memory: "memory:abcdef123456",
        summary: "This is a very long memory summary that should be clipped.",
      },
    }],
    lineWidth: 34,
  });

  assert.equal(lines.length, 3);
  assert.match(lines[2]?.text ?? "", /…/u);
});

test("buildTerminalTableBodyLines renders explicit empty state", () => {
  interface EmptyCmpRow {
    lifecycle: string;
    ref: string;
  }

  const lines = buildTerminalTableBodyLines({
    columns: [
      {
        key: "lifecycle",
        title: "Lifecycle",
        minWidth: 9,
        value: (row: EmptyCmpRow) => row.lifecycle,
      },
      {
        key: "ref",
        title: "Section Ref",
        minWidth: 12,
        value: (row: EmptyCmpRow) => row.ref,
      },
    ],
    rows: [] as Array<{ key: string; data: EmptyCmpRow }>,
    lineWidth: 48,
    emptyText: "No CMP section records yet.",
    emptyTone: "warning",
  });

  assert.equal(lines.length, 3);
  assert.equal(lines[2]?.tone, "warning");
  assert.match(lines[2]?.text ?? "", /No CMP section records yet\./u);
});
