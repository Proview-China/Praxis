import stringWidth from "string-width";

import type { PraxisSlashPanelBodyLine, PraxisSlashPanelFieldTone } from "./slash-panels.js";

export interface ViewerStatusEntry {
  key?: string;
  value: string;
  abnormal?: boolean;
}

const POSITIVE_STATUS_VALUES = new Set([
  "ready",
  "healthy",
  "succeeded",
  "success",
  "available",
  "aligned",
  "fresh",
  "served",
  "bootstrapped",
  "observed",
  "active",
  "running",
]);

const NEGATIVE_STATUS_PATTERN = /\b(degraded|failed|error|blocked|missing|unknown|idle|empty|unavailable|stale|fallback|pending)\b/iu;
const NEGATIVE_TEXT_PATTERN = /\b(degraded|failed|error|blocked|missing|unknown|idle|empty|unavailable|stale|fallback|pending|not observed|without observed activity)\b/iu;

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

function padTextToWidth(text: string, width: number): string {
  const normalized = truncateTextToWidth(text, width);
  const remaining = Math.max(0, width - stringWidth(normalized));
  return `${normalized}${" ".repeat(remaining)}`;
}

function normalizeStatusText(value: string): string {
  return value.replace(/\s+/gu, " ").trim();
}

export function isViewerStatusValueAbnormal(value: string): boolean {
  const normalized = normalizeStatusText(value).toLowerCase();
  if (POSITIVE_STATUS_VALUES.has(normalized)) {
    return false;
  }
  if (normalized.includes("/")) {
    const parts = normalized.split("/").map((part) => part.trim()).filter(Boolean);
    if (parts.length > 0) {
      const hasNegative = parts.some((part) => NEGATIVE_STATUS_PATTERN.test(part));
      if (hasNegative) {
        return true;
      }
      const hasPositive = parts.some((part) => POSITIVE_STATUS_VALUES.has(part));
      return !hasPositive;
    }
  }
  return NEGATIVE_STATUS_PATTERN.test(normalized);
}

export function isViewerStatusTextAbnormal(value: string): boolean {
  return NEGATIVE_TEXT_PATTERN.test(normalizeStatusText(value));
}

export function parseViewerAssignmentEntries(value: string): ViewerStatusEntry[] {
  const normalized = normalizeStatusText(value);
  if (!normalized) {
    return [];
  }
  const delimiter = normalized.includes(",")
    ? ","
    : /\S+[=:]\S+(?:\s+\S+[=:]\S+)+/u.test(normalized)
      ? " "
      : null;
  const parts = delimiter === ","
    ? normalized.split(",").map((part) => part.trim()).filter(Boolean)
    : delimiter === " "
      ? normalized.split(/\s+/u).map((part) => part.trim()).filter(Boolean)
      : [normalized];
  return parts.flatMap((part) => {
    const match = /^([^:=]+)\s*[:=]\s*(.+)$/u.exec(part);
    if (!match) {
      return [];
    }
    const key = match[1]?.trim();
    const entryValue = match[2]?.trim();
    if (!key || !entryValue) {
      return [];
    }
    return [{
      key,
      value: entryValue,
      abnormal: isViewerStatusValueAbnormal(entryValue),
    }];
  });
}

export function parseViewerRoleEntries(roleLines: string[] | undefined): ViewerStatusEntry[] {
  if (!roleLines || roleLines.length === 0) {
    return [];
  }
  return roleLines.flatMap((line) => {
    const [roleText, rest = ""] = line.split(":", 2);
    const role = roleText.trim();
    if (!role) {
      return [];
    }
    const stage = /stage=([^ ·]+)/u.exec(rest)?.[1]?.trim();
    const live = /live=([^ ·]+)/u.exec(rest)?.[1]?.trim();
    const directValue = rest.trim();
    const value = stage && live
      ? `${stage}/${live}`
      : stage
        ? stage
        : live
          ? live
          : directValue;
    return [{
      key: role,
      value: value || "unknown",
      abnormal: live
        ? isViewerStatusValueAbnormal(live)
        : isViewerStatusTextAbnormal(value || "unknown"),
    }];
  });
}

export function buildViewerStatusBlockLines(params: {
  label: string;
  labelTone: PraxisSlashPanelFieldTone;
  entries: ViewerStatusEntry[];
  lineWidth: number;
  emptyValue?: string;
  entryIndent?: number;
}): PraxisSlashPanelBodyLine[] {
  const entryIndent = " ".repeat(params.entryIndent ?? 6);
  const availableWidth = Math.max(16, params.lineWidth - entryIndent.length);
  const entries = params.entries.length > 0
    ? params.entries
    : params.emptyValue
      ? [{ value: params.emptyValue, abnormal: false }]
      : [];
  const lines: PraxisSlashPanelBodyLine[] = [{
    text: `    ${params.label}`,
    segments: [
      { text: "    " },
      { text: params.label, tone: params.labelTone },
    ],
  }];
  for (const entry of entries) {
    if (entry.key) {
      const valueTone: PraxisSlashPanelFieldTone | undefined = entry.abnormal ? "danger" : undefined;
      const renderedValue = truncateTextToWidth(normalizeStatusText(entry.value), Math.max(8, availableWidth - stringWidth(`${entry.key}=`)));
      lines.push({
        text: `${entryIndent}${entry.key}=${renderedValue}`,
        segments: [
          { text: entryIndent },
          { text: `${entry.key}=`, tone: undefined },
          { text: renderedValue, tone: valueTone },
        ],
      });
      continue;
    }
    const renderedValue = truncateTextToWidth(normalizeStatusText(entry.value), availableWidth);
    lines.push({
      text: `${entryIndent}${renderedValue}`,
      segments: [
        { text: entryIndent },
        { text: renderedValue, tone: entry.abnormal ? "danger" : undefined },
      ],
    });
  }
  return lines;
}

export function buildViewerStatusGridLines(params: {
  label: string;
  labelTone: PraxisSlashPanelFieldTone;
  entries: ViewerStatusEntry[];
  lineWidth: number;
  emptyValue?: string;
  entryIndent?: number;
  columnCount?: number;
  columnGap?: number;
}): PraxisSlashPanelBodyLine[] {
  const entryIndent = " ".repeat(params.entryIndent ?? 6);
  const entries = params.entries.length > 0
    ? params.entries
    : params.emptyValue
      ? [{ value: params.emptyValue, abnormal: false }]
      : [];
  const lines: PraxisSlashPanelBodyLine[] = [{
    text: `    ${params.label}`,
    segments: [
      { text: "    " },
      { text: params.label, tone: params.labelTone },
    ],
  }];
  if (entries.length === 0) {
    return lines;
  }
  const requestedColumns = params.columnCount ?? (params.lineWidth >= 92 ? 2 : 1);
  const columns = Math.max(1, Math.min(requestedColumns, entries.length));
  const gap = Math.max(2, params.columnGap ?? 4);
  const availableWidth = Math.max(16, params.lineWidth - entryIndent.length);
  const columnWidth = columns <= 1
    ? availableWidth
    : Math.max(14, Math.floor((availableWidth - gap * (columns - 1)) / columns));

  for (let index = 0; index < entries.length; index += columns) {
    const rowEntries = entries.slice(index, index + columns);
    const rowSegments: PraxisSlashPanelBodyLine["segments"] = [{ text: entryIndent }];
    let rowText = entryIndent;
    rowEntries.forEach((entry, entryIndex) => {
      const prefix = entry.key ? `${entry.key}=` : "";
      const valueWidth = Math.max(6, columnWidth - stringWidth(prefix));
      const renderedValue = truncateTextToWidth(normalizeStatusText(entry.value), valueWidth);
      const renderedText = padTextToWidth(`${prefix}${renderedValue}`, columnWidth);
      rowText += renderedText;
      if (entry.key) {
        rowSegments.push({ text: prefix });
      }
      rowSegments.push({
        text: entry.key ? padTextToWidth(renderedValue, columnWidth - stringWidth(prefix)) : renderedText,
        tone: entry.abnormal ? "danger" : undefined,
      });
      if (entryIndex < rowEntries.length - 1) {
        const spacer = " ".repeat(gap);
        rowText += spacer;
        rowSegments.push({ text: spacer });
      }
    });
    lines.push({
      text: rowText,
      segments: rowSegments,
    });
  }
  return lines;
}
