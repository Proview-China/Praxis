import stringWidth from "string-width";

import type { PraxisSlashPanelBodyLine, PraxisSlashPanelFieldTone } from "./slash-panels.js";

export interface TerminalTableColumn<Row> {
  key: string;
  title: string;
  minWidth: number;
  maxWidth?: number;
  align?: "left" | "right";
  shrinkPriority?: number;
  growPriority?: number;
  value: (row: Row) => string;
}

export interface TerminalTableRow<Row> {
  key: string;
  data: Row;
  tone?: PraxisSlashPanelFieldTone;
}

interface ResolvedTerminalTableColumn<Row> extends TerminalTableColumn<Row> {
  width: number;
}

function truncateTextToWidth(text: string, maxWidth: number): string {
  if (maxWidth <= 0) {
    return "";
  }
  if (stringWidth(text) <= maxWidth) {
    return text;
  }
  let output = "";
  for (const char of [...text]) {
    if (stringWidth(output + char) > Math.max(0, maxWidth - 1)) {
      break;
    }
    output += char;
  }
  return `${output}…`;
}

function padTextToWidth(text: string, width: number, align: "left" | "right" = "left"): string {
  const normalized = truncateTextToWidth(text, width);
  const padding = " ".repeat(Math.max(0, width - stringWidth(normalized)));
  return align === "right" ? `${padding}${normalized}` : `${normalized}${padding}`;
}

function resolveColumnWidths<Row>(
  columns: TerminalTableColumn<Row>[],
  rows: TerminalTableRow<Row>[],
  availableWidth: number,
): Array<ResolvedTerminalTableColumn<Row>> {
  const widths = columns.map((column) => {
    const measuredValues = rows.map((row) => stringWidth(column.value(row.data)));
    const desiredWidth = Math.max(stringWidth(column.title), ...measuredValues);
    const maxWidth = column.maxWidth ?? Math.max(column.minWidth, desiredWidth);
    return {
      ...column,
      width: Math.max(column.minWidth, Math.min(desiredWidth, maxWidth)),
    };
  });

  const separatorWidth = Math.max(0, (columns.length - 1) * 3);
  let totalWidth = widths.reduce((sum, column) => sum + column.width, 0) + separatorWidth;
  let overflow = Math.max(0, totalWidth - availableWidth);

  if (overflow > 0) {
    const shrinkableColumns = widths
      .slice()
      .sort((left, right) => (left.shrinkPriority ?? 0) - (right.shrinkPriority ?? 0));
    for (const column of shrinkableColumns) {
      if (overflow <= 0) {
        break;
      }
      const current = widths.find((candidate) => candidate.key === column.key);
      if (!current) {
        continue;
      }
      const shrinkable = current.width - current.minWidth;
      if (shrinkable <= 0) {
        continue;
      }
      const applied = Math.min(shrinkable, overflow);
      current.width -= applied;
      overflow -= applied;
    }
  }

  totalWidth = widths.reduce((sum, column) => sum + column.width, 0) + separatorWidth;
  let remaining = Math.max(0, availableWidth - totalWidth);
  if (remaining > 0) {
    const growableColumns = widths
      .slice()
      .sort((left, right) => (left.growPriority ?? 0) - (right.growPriority ?? 0));
    while (remaining > 0 && growableColumns.length > 0) {
      let grew = false;
      for (const column of growableColumns) {
        const current = widths.find((candidate) => candidate.key === column.key);
        if (!current) {
          continue;
        }
        const maxWidth = current.maxWidth ?? availableWidth;
        if (current.width >= maxWidth) {
          continue;
        }
        current.width += 1;
        remaining -= 1;
        grew = true;
        if (remaining <= 0) {
          break;
        }
      }
      if (!grew) {
        break;
      }
    }
  }

  return widths;
}

export function buildTerminalTableBodyLines<Row>(params: {
  columns: TerminalTableColumn<Row>[];
  rows: TerminalTableRow<Row>[];
  lineWidth: number;
  indent?: number;
  emptyText?: string;
  emptyTone?: PraxisSlashPanelFieldTone;
}): PraxisSlashPanelBodyLine[] {
  const indent = " ".repeat(params.indent ?? 4);
  const availableWidth = Math.max(24, params.lineWidth - indent.length);
  const columns = resolveColumnWidths(params.columns, params.rows, availableWidth);
  const header = columns.map((column) => padTextToWidth(column.title, column.width, column.align)).join(" │ ");
  const separator = columns.map((column) => "─".repeat(column.width)).join("─┼─");

  const lines: PraxisSlashPanelBodyLine[] = [
    { text: `${indent}${header}`, tone: "info" },
    { text: `${indent}${separator}`, tone: "info" },
  ];

  if (params.rows.length === 0) {
    lines.push({
      text: `${indent}${truncateTextToWidth(params.emptyText ?? "No rows available.", availableWidth)}`,
      tone: params.emptyTone,
    });
    return lines;
  }

  for (const row of params.rows) {
    const rowText = columns
      .map((column) => padTextToWidth(column.value(row.data), column.width, column.align))
      .join(" │ ");
    lines.push({
      text: `${indent}${rowText}`,
      tone: row.tone,
    });
  }
  return lines;
}
