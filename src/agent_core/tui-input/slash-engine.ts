export interface PraxisSlashCommand {
  id: string;
  name: string;
  description?: string;
  aliases?: string[];
  hidden?: boolean;
}

export interface PraxisSlashSuggestion {
  id: string;
  command: PraxisSlashCommand;
  displayText: string;
  description?: string;
  score: number;
}

export interface PraxisSlashState {
  active: boolean;
  query: string;
  suggestions: PraxisSlashSuggestion[];
}

function normalizeSlashToken(value: string): string {
  return value.trim().replace(/^\//u, "").toLowerCase();
}

function commandMatchesQuery(command: PraxisSlashCommand, query: string): number | null {
  const normalizedQuery = normalizeSlashToken(query);
  const name = command.name.toLowerCase();

  if (normalizedQuery.length === 0) {
    return 10;
  }
  if (name === normalizedQuery) {
    return 100;
  }
  if (name.startsWith(normalizedQuery)) {
    return 80 - (name.length - normalizedQuery.length);
  }
  if (command.aliases?.some((alias) => alias.toLowerCase() === normalizedQuery)) {
    return 70;
  }
  if (command.aliases?.some((alias) => alias.toLowerCase().startsWith(normalizedQuery))) {
    return 60;
  }
  if (name.includes(normalizedQuery)) {
    return 30;
  }
  if (command.description?.toLowerCase().includes(normalizedQuery)) {
    return 10;
  }
  return null;
}

export function computeSlashState(
  input: string,
  commands: PraxisSlashCommand[],
): PraxisSlashState {
  if (!input.startsWith("/")) {
    return {
      active: false,
      query: "",
      suggestions: [],
    };
  }

  const firstToken = input.split(/\s+/u, 1)[0] ?? "/";
  const query = normalizeSlashToken(firstToken);
  const suggestions = commands
    .filter((command) => !command.hidden)
    .map((command) => {
      const score = commandMatchesQuery(command, query);
      if (score == null) {
        return null;
      }
      return {
        id: command.id,
        command,
        displayText: `/${command.name}`,
        description: command.description,
        score,
      } satisfies PraxisSlashSuggestion;
    })
    .filter((value): value is PraxisSlashSuggestion => value !== null)
    .sort((left, right) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }
      return left.command.name.localeCompare(right.command.name);
    });

  return {
    active: true,
    query,
    suggestions,
  };
}

export function applySlashSuggestion(
  input: string,
  suggestion: PraxisSlashSuggestion,
): {
  nextInput: string;
  nextCursorOffset: number;
} {
  const trimmedStart = input.match(/^\s*/u)?.[0] ?? "";
  const rest = input.trimStart().replace(/^\/\S*/u, "").replace(/^\s+/u, "");
  const nextInput = `${trimmedStart}/${suggestion.command.name}${rest.length > 0 ? ` ${rest}` : " "}`;
  return {
    nextInput,
    nextCursorOffset: nextInput.length,
  };
}

export const DEFAULT_PRAXIS_SLASH_COMMANDS: PraxisSlashCommand[] = [
  { id: "help", name: "help", description: "查看命令" },
  { id: "status", name: "status", description: "查看最近一轮 CMP / TAP / core 总览" },
  { id: "capabilities", name: "capabilities", description: "查看当前 TAP 池中已注册能力" },
  { id: "cmp", name: "cmp", description: "查看最近一轮 CMP 摘要" },
  { id: "tap", name: "tap", description: "查看当前 TAP 治理视图" },
  { id: "events", name: "events", description: "查看最近一轮 core run 事件类型" },
  { id: "history", name: "history", description: "查看当前 CLI 内部对话历史摘要" },
  { id: "exit", name: "exit", aliases: ["quit"], description: "退出" },
];
