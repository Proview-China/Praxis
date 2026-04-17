import stringWidth from "string-width";

import type { PraxisSlashPanelBodyLine, PraxisSlashPanelFieldTone } from "./slash-panels.js";

export interface MpSummaryTableRow {
  subtitle: string;
  content: string;
  abnormal?: boolean;
}

export interface MpSummaryTableSection {
  title: string;
  titleTone?: PraxisSlashPanelFieldTone;
  rows: MpSummaryTableRow[];
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

function padTextToWidth(text: string, width: number, align: "left" | "center" = "left"): string {
  const normalized = truncateTextToWidth(text, width);
  const remaining = Math.max(0, width - stringWidth(normalized));
  if (align === "center") {
    const left = Math.floor(remaining / 2);
    const right = remaining - left;
    return `${" ".repeat(left)}${normalized}${" ".repeat(right)}`;
  }
  return `${normalized}${" ".repeat(remaining)}`;
}

function sliceTextByDisplayWidth(text: string, offset: number, width: number): string {
  if (width <= 0) {
    return "";
  }
  const graphemes = [...text];
  let current = 0;
  let output = "";
  for (const grapheme of graphemes) {
    const graphemeWidth = Math.max(1, stringWidth(grapheme));
    const next = current + graphemeWidth;
    if (next <= offset) {
      current = next;
      continue;
    }
    if (current >= offset + width) {
      break;
    }
    if (next > offset + width) {
      break;
    }
    output += grapheme;
    current = next;
  }
  const remaining = Math.max(0, width - stringWidth(output));
  return `${output}${" ".repeat(remaining)}`;
}

function sliceSegmentsByDisplayWidth(
  segments: NonNullable<PraxisSlashPanelBodyLine["segments"]>,
  offset: number,
  width: number,
): NonNullable<PraxisSlashPanelBodyLine["segments"]> {
  if (width <= 0) {
    return [{ text: "" }];
  }
  let current = 0;
  const visible: NonNullable<PraxisSlashPanelBodyLine["segments"]> = [];
  for (const segment of segments) {
    let segmentText = "";
    for (const grapheme of [...segment.text]) {
      const graphemeWidth = Math.max(1, stringWidth(grapheme));
      const next = current + graphemeWidth;
      if (next <= offset) {
        current = next;
        continue;
      }
      if (current >= offset + width || next > offset + width) {
        break;
      }
      segmentText += grapheme;
      current = next;
    }
    if (segmentText.length > 0) {
      visible.push({
        text: segmentText,
        tone: segment.tone,
      });
    }
    if (current >= offset + width) {
      break;
    }
  }
  const visibleWidth = visible.reduce((sum, segment) => sum + stringWidth(segment.text), 0);
  if (visibleWidth < width) {
    visible.push({ text: " ".repeat(width - visibleWidth) });
  }
  return visible;
}

function resolveSectionWidths(sections: MpSummaryTableSection[]): Array<{
  titleWidth: number;
  subtitleWidth: number;
  contentWidth: number;
  sectionWidth: number;
}> {
  return sections.map((section) => {
    const subtitleWidth = Math.max(
      10,
      ...section.rows.map((row) => stringWidth(row.subtitle)),
    );
    const contentWidth = Math.max(
      16,
      ...section.rows.map((row) => stringWidth(row.content)),
    );
    const sectionWidth = Math.max(
      stringWidth(section.title),
      subtitleWidth + 3 + contentWidth,
    );
    return {
      titleWidth: stringWidth(section.title),
      subtitleWidth,
      contentWidth,
      sectionWidth,
    };
  });
}

export function buildMpSummaryTableLines(input: {
  sections: MpSummaryTableSection[];
  lineWidth: number;
  scrollX: number;
  indent?: number;
}): {
  lines: PraxisSlashPanelBodyLine[];
  meta: {
    scrollX: number;
    maxScrollX: number;
    totalWidth: number;
    viewportWidth: number;
  };
} {
  const indent = " ".repeat(input.indent ?? 4);
  const viewportWidth = Math.max(24, input.lineWidth - indent.length);
  const widths = resolveSectionWidths(input.sections);
  const maxRows = Math.max(0, ...input.sections.map((section) => section.rows.length));
  const titleRow = input.sections.map((section, index) =>
    padTextToWidth(section.title, widths[index]?.sectionWidth ?? stringWidth(section.title), "center"),
  ).join(" │ ");
  const separatorRow = widths.map((section) => "─".repeat(section.sectionWidth)).join("─┼─");
  const dataRows = Array.from({ length: maxRows }, (_, rowIndex) =>
    input.sections.map((section, sectionIndex) => {
      const row = section.rows[rowIndex];
      const width = widths[sectionIndex];
      if (!row || !width) {
        return " ".repeat(width?.sectionWidth ?? 0);
      }
      return `${padTextToWidth(row.subtitle, width.subtitleWidth)} │ ${padTextToWidth(row.content, width.contentWidth)}`;
    }).join(" │ "),
  );
  const fullRows = [titleRow, separatorRow, ...dataRows];
  const totalWidth = Math.max(...fullRows.map((row) => stringWidth(row)), 0);
  const maxScrollX = Math.max(0, totalWidth - viewportWidth);
  const scrollX = Math.max(0, Math.min(input.scrollX, maxScrollX));

  const lines: PraxisSlashPanelBodyLine[] = fullRows.map((row, index) => {
    if (index === 0) {
      const segments: NonNullable<PraxisSlashPanelBodyLine["segments"]> = [{ text: indent }];
      input.sections.forEach((section, sectionIndex) => {
        const width = widths[sectionIndex]?.sectionWidth ?? stringWidth(section.title);
        segments.push({
          text: padTextToWidth(section.title, width, "center"),
          tone: "danger",
        });
        if (sectionIndex < input.sections.length - 1) {
          segments.push({ text: " │ ", tone: "info" });
        }
      });
      const visibleSegments = sliceSegmentsByDisplayWidth(segments, scrollX, viewportWidth + indent.length);
      return {
        text: visibleSegments.map((segment) => segment.text).join(""),
        segments: visibleSegments,
      };
    }
    if (index === 1) {
      return {
        text: `${indent}${sliceTextByDisplayWidth(row, scrollX, viewportWidth)}`,
        tone: "info",
      };
    }
    const dataIndex = index - 2;
    const segments: NonNullable<PraxisSlashPanelBodyLine["segments"]> = [{ text: indent }];
    input.sections.forEach((section, sectionIndex) => {
      const width = widths[sectionIndex];
      const currentRow = section.rows[dataIndex];
      if (!width) {
        return;
      }
      if (!currentRow) {
        segments.push({ text: " ".repeat(width.sectionWidth) });
      } else {
        segments.push({
          text: padTextToWidth(currentRow.subtitle, width.subtitleWidth),
          tone: "orange",
        });
        segments.push({ text: " │ ", tone: "info" });
        segments.push({
          text: padTextToWidth(currentRow.content, width.contentWidth),
          tone: currentRow.abnormal ? "danger" : undefined,
        });
      }
      if (sectionIndex < input.sections.length - 1) {
        segments.push({ text: " │ ", tone: "info" });
      }
    });
    const visibleSegments = sliceSegmentsByDisplayWidth(segments, scrollX, viewportWidth + indent.length);
    return {
      text: visibleSegments.map((segment) => segment.text).join(""),
      segments: visibleSegments,
    };
  });

  return {
    lines,
    meta: {
      scrollX,
      maxScrollX,
      totalWidth,
      viewportWidth,
    },
  };
}
