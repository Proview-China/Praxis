export type MpViewerSubtab = "summary" | "records";

export function resolveMpViewerSubtab(value: string | undefined): MpViewerSubtab {
  return value === "records" ? "records" : "summary";
}

export function cycleMpViewerSubtab(current: MpViewerSubtab): MpViewerSubtab {
  return current === "summary" ? "records" : "summary";
}

export function buildMpViewerHints(subtab: MpViewerSubtab): string[] {
  if (subtab === "records") {
    return [
      "press TAB to switch panel",
      "press ← to previous page • press → to next page",
      "press ENTER to refresh current memory state",
      "press ESC to return to previous page",
    ];
  }
  return [
    "press TAB to switch panel",
    "press ← to scroll left • press → to scroll right",
    "press ENTER to refresh current memory state",
    "press ESC to return to previous page",
  ];
}
