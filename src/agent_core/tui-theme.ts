export type TuiTone =
  | "accent"
  | "muted"
  | "surface"
  | "surfaceStrong"
  | "success"
  | "warning"
  | "danger"
  | "info";

export type TuiColorName =
  | "black"
  | "blackBright"
  | "gray"
  | "white"
  | "whiteBright"
  | "cyan"
  | "cyanBright"
  | "green"
  | "greenBright"
  | "yellow"
  | "yellowBright"
  | "red"
  | "redBright"
  | "magenta"
  | "magentaBright";

export interface TuiTheme {
  fontFamily: string;
  text: TuiColorName;
  textMuted: TuiColorName;
  mint: TuiColorName;
  mintSoft: TuiColorName;
  yellow: TuiColorName;
  red: TuiColorName;
  cyan: TuiColorName;
  violet: TuiColorName;
  line: TuiColorName;
  surface: TuiColorName;
  surfaceElevated: TuiColorName;
  border: TuiColorName;
  borderStrong: TuiColorName;
  accent: TuiColorName;
  palette: Record<TuiTone, TuiColorName>;
  limits: {
    maxLineLength: number;
    maxMetaItems: number;
  };
  layout: {
    framePaddingX: number;
    framePaddingY: number;
    panelPaddingX: number;
    panelPaddingY: number;
    panelGap: number;
    footerGap: number;
  };
  chrome: {
    borderStyle: "round";
    panelBorderStyle: "round";
  };
}

export const TUI_THEME: TuiTheme = {
  fontFamily: "\"JetBrains Mono\", \"SFMono-Regular\", \"Menlo\", \"Monaco\", monospace",
  text: "whiteBright",
  textMuted: "gray",
  mint: "cyanBright",
  mintSoft: "cyan",
  yellow: "yellowBright",
  red: "redBright",
  cyan: "cyanBright",
  violet: "magentaBright",
  line: "gray",
  surface: "blackBright",
  surfaceElevated: "blackBright",
  border: "gray",
  borderStrong: "whiteBright",
  accent: "cyanBright",
  palette: {
    accent: "cyanBright",
    muted: "gray",
    surface: "blackBright",
    surfaceStrong: "whiteBright",
    success: "cyanBright",
    warning: "yellowBright",
    danger: "redBright",
    info: "magentaBright",
  },
  limits: {
    maxLineLength: 96,
    maxMetaItems: 4,
  },
  layout: {
    framePaddingX: 1,
    framePaddingY: 0,
    panelPaddingX: 1,
    panelPaddingY: 0,
    panelGap: 1,
    footerGap: 1,
  },
  chrome: {
    borderStyle: "round",
    panelBorderStyle: "round",
  },
};

const TONE_TO_COLOR: Record<TuiTone, TuiColorName> = TUI_THEME.palette;

export function tuiColorForTone(tone: TuiTone): TuiColorName {
  return TONE_TO_COLOR[tone];
}

export function tuiCompactText(value: string, maxLength = TUI_THEME.limits.maxLineLength): string {
  const normalized = value.replace(/\s+/gu, " ").trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return `${normalized.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

export function tuiJoinMeta(values: readonly string[], separator = " · "): string {
  return values
    .map((value) => value.trim())
    .filter((value) => value.length > 0)
    .join(separator);
}

export function tuiLimitItems(values: readonly string[], limit = TUI_THEME.limits.maxMetaItems): string[] {
  if (limit <= 0 || values.length <= limit) {
    return [...values];
  }
  return [...values.slice(0, limit - 1), `+${values.length - (limit - 1)} more`];
}

export function tuiShortenPath(value: string, home = process.env.HOME): string {
  if (!home) {
    return value;
  }
  return value.startsWith(home) ? `~${value.slice(home.length)}` : value;
}

export function tuiPillText(label: string, tone: TuiTone = "muted"): { label: string; color: TuiColorName } {
  return {
    label,
    color: tuiColorForTone(tone),
  };
}

export function formatDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}
