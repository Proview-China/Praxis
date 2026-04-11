import { Box, Text } from "ink";
import type { ReactNode } from "react";

import {
  TUI_THEME,
  tuiColorForTone,
  tuiCompactText,
  tuiJoinMeta,
  tuiLimitItems,
  tuiPillText,
  tuiShortenPath,
  type TuiColorName,
  type TuiTone,
} from "./tui-theme.js";

export interface TuiTopBarProps {
  title: string;
  leftMeta?: readonly string[];
  rightMeta?: readonly string[];
  accent?: TuiColorName;
}

export interface TuiPanelProps {
  title: string;
  subtitle?: string;
  lines: readonly string[];
  emptyText?: string;
  footer?: ReactNode;
  accent?: TuiColorName;
  accentTone?: TuiTone;
}

export interface TuiToolbarItem {
  key: string;
  label: string;
  tone?: TuiTone;
}

export interface TuiToolbarProps {
  leftLabel?: string;
  items?: readonly TuiToolbarItem[];
  rightLabel?: string;
}

export interface TuiCommandPaletteProps {
  active?: string;
  items: readonly string[];
}

export interface TuiFooterBarProps {
  inputValue: string;
  utilityItems: readonly string[];
}

export interface TuiChromeFrameProps {
  header?: ReactNode;
  footer?: ReactNode;
  children: ReactNode;
}

export function TuiChromeFrame(props: TuiChromeFrameProps): JSX.Element {
  return (
    <Box flexDirection="column" paddingX={TUI_THEME.layout.framePaddingX} paddingY={TUI_THEME.layout.framePaddingY}>
      {props.header}
      <Box marginTop={TUI_THEME.layout.panelGap} flexDirection="column">
        {props.children}
      </Box>
      {props.footer ? <Box marginTop={TUI_THEME.layout.footerGap}>{props.footer}</Box> : null}
    </Box>
  );
}

export function TuiTopBar(props: TuiTopBarProps): JSX.Element {
  const leftMeta = tuiLimitItems([...(props.leftMeta ?? [])], TUI_THEME.limits.maxMetaItems);
  const rightMeta = tuiLimitItems([...(props.rightMeta ?? [])], TUI_THEME.limits.maxMetaItems);
  const accent = props.accent ?? TUI_THEME.cyan;

  return (
    <Box
      borderStyle={TUI_THEME.chrome.borderStyle}
      borderColor={accent}
      flexDirection="column"
      paddingX={TUI_THEME.layout.panelPaddingX}
      paddingY={TUI_THEME.layout.panelPaddingY}
    >
      <Box justifyContent="space-between">
        <Text color={accent}>{tuiCompactText(props.title, 48)}</Text>
        <Text color={TUI_THEME.textMuted}>{tuiJoinMeta(rightMeta)}</Text>
      </Box>
      {leftMeta.length > 0 ? <Text color={TUI_THEME.textMuted}>{tuiJoinMeta(leftMeta)}</Text> : null}
    </Box>
  );
}

export function TuiChromeHeader(props: Omit<TuiTopBarProps, "rightMeta"> & {
  subtitle?: string;
  status?: string;
  meta?: readonly string[];
  accentTone?: TuiTone;
}): JSX.Element {
  const meta = tuiLimitItems(
    [
      props.subtitle ? tuiCompactText(props.subtitle, 60) : "",
      ...(props.meta ?? []).map((value) => tuiCompactText(value, 42)),
    ],
  );
  const accent = props.accent ?? (props.accentTone ? tuiColorForTone(props.accentTone) : tuiColorForTone("accent"));

  return (
    <Box
      borderStyle={TUI_THEME.chrome.borderStyle}
      borderColor={accent}
      flexDirection="column"
      paddingX={TUI_THEME.layout.panelPaddingX}
      paddingY={TUI_THEME.layout.panelPaddingY}
    >
      <Box justifyContent="space-between">
        <Text color={accent}>{tuiCompactText(props.title, 48)}</Text>
        {props.status ? <Text color="gray">{tuiCompactText(props.status, 32)}</Text> : <Text color="gray"> </Text>}
      </Box>
      {meta.length > 0 ? <Text color="gray">{tuiJoinMeta(meta)}</Text> : null}
    </Box>
  );
}

export function TuiPanel(props: TuiPanelProps): JSX.Element {
  const accent = props.accent ?? tuiColorForTone(props.accentTone ?? "surfaceStrong");
  const clippedLines = props.lines.map((line) => tuiCompactText(line, TUI_THEME.limits.maxLineLength));

  return (
    <Box
      borderStyle={TUI_THEME.chrome.panelBorderStyle}
      borderColor={accent}
      flexDirection="column"
      paddingX={TUI_THEME.layout.panelPaddingX}
      paddingY={TUI_THEME.layout.panelPaddingY}
      marginBottom={TUI_THEME.layout.panelGap}
    >
      <Text color={accent}>{tuiCompactText(props.title, 36)}</Text>
      {props.subtitle ? <Text color="gray">{tuiCompactText(props.subtitle, 54)}</Text> : null}
      {clippedLines.length > 0 ? (
        clippedLines.map((line, index) => (
          <Text key={`${props.title}-${index}-${line}`} color={line.startsWith("  ") ? "gray" : undefined}>
            {line}
          </Text>
        ))
      ) : (
        <Text color="gray">{props.emptyText ?? "No data."}</Text>
      )}
      {props.footer ? <Box marginTop={1}>{props.footer}</Box> : null}
    </Box>
  );
}

export function TuiToolbar(props: TuiToolbarProps): JSX.Element {
  const items = props.items ?? [];

  return (
    <Box
      borderStyle={TUI_THEME.chrome.borderStyle}
      borderColor={TUI_THEME.line}
      justifyContent="space-between"
      paddingX={TUI_THEME.layout.panelPaddingX}
      paddingY={TUI_THEME.layout.panelPaddingY}
    >
      <Text color={TUI_THEME.textMuted}>{props.leftLabel ? tuiCompactText(props.leftLabel, 48) : " "}</Text>
      <Box>
        {items.length > 0 ? (
          items.map((item, index) => {
            const pill = tuiPillText(item.key, item.tone ?? "muted");
            return (
              <Text key={`${item.key}-${index}`} color={pill.color}>
                {index > 0 ? "  " : ""}
                [{pill.label}] {tuiCompactText(item.label, 28)}
              </Text>
            );
          })
        ) : (
          <Text color="gray">Ctrl+C: quit</Text>
        )}
      </Box>
      <Text color={TUI_THEME.textMuted}>{props.rightLabel ? tuiCompactText(props.rightLabel, 36) : " "}</Text>
    </Box>
  );
}

export function TuiWorkspaceBanner(props: {
  cwd: string;
  route?: string;
  model?: string;
  workspace?: string;
  status?: string;
}): JSX.Element {
  const meta = tuiLimitItems(
    [
      props.workspace ? `workspace ${props.workspace}` : "",
      `cwd ${tuiShortenPath(props.cwd)}`,
      props.route ? `route ${tuiShortenPath(props.route)}` : "",
      props.model ? `model ${props.model}` : "",
    ],
    4,
  );

  return (
    <TuiChromeHeader
      title={props.workspace ?? "Praxis TUI"}
      subtitle={tuiJoinMeta(meta)}
      status={props.status}
      accentTone="accent"
    />
  );
}

export function TuiCommandPalette(props: TuiCommandPaletteProps): JSX.Element {
  return (
    <Box
      borderStyle={TUI_THEME.chrome.panelBorderStyle}
      borderColor={TUI_THEME.cyan}
      flexDirection="column"
      width={22}
      paddingX={TUI_THEME.layout.panelPaddingX}
      paddingY={TUI_THEME.layout.panelPaddingY}
    >
      {props.items.map((item, index) => {
        const isActive = item.toLowerCase() === props.active?.toLowerCase();
        return (
          <Text key={`${item}-${index}`} color={isActive ? TUI_THEME.mint : TUI_THEME.textMuted}>
            {`${String(index + 1).padStart(2, "0")} ${item.toUpperCase()}`}
          </Text>
        );
      })}
    </Box>
  );
}

export function TuiFooterBar(props: TuiFooterBarProps): JSX.Element {
  const items = props.utilityItems.map((item, index) => ({
    key: String(index + 1).padStart(2, "0"),
    label: item,
    tone: index === 0 ? "success" as const : "muted" as const,
  }));

  return (
    <Box flexDirection="column">
      <Text color={TUI_THEME.line}>{"─".repeat(Math.max(32, Math.min(process.stdout.columns ?? 80, 120)))}</Text>
      <Box justifyContent="space-between">
        <Text color={TUI_THEME.mint}>{`> ${props.inputValue}`}</Text>
        <Box>
          {items.map((item, index) => (
            <Text key={item.key} color={tuiColorForTone(item.tone)}>
              {index > 0 ? "  " : ""}
              [{item.key}] {item.label}
            </Text>
          ))}
        </Box>
      </Box>
    </Box>
  );
}

export const TuiPanelCard = TuiPanel;

export type TuiHeaderProps = TuiTopBarProps;
export type TuiPanelCardProps = TuiPanelProps;
