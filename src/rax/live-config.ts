import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

import {
  resolveAuthJsonPath,
  resolveConfigJsonPath,
  resolveLiveEnvPath,
} from "../runtime-paths.js";

export interface OpenAILiveConfig {
  apiKey: string;
  baseURL: string;
  model: string;
  reasoningEffort?: string;
  contextWindowTokens?: number;
}

export interface AnthropicLiveConfig {
  apiKey: string;
  baseURL: string;
  model: string;
  contextWindowTokens?: number;
}

export interface DeepMindLiveConfig {
  apiKey: string;
  baseURL: string;
  model: string;
  contextWindowTokens?: number;
}

export interface LiveProviderConfig {
  openai: OpenAILiveConfig;
  anthropic: AnthropicLiveConfig;
  anthropicAlt?: AnthropicLiveConfig;
  deepmind: DeepMindLiveConfig;
}

type JsonRecord = Record<string, unknown>;

function normalizeOpenAIBaseURL(input: string): string {
  const url = new URL(input);
  if (url.pathname === "/" || url.pathname === "") {
    url.pathname = "/v1";
  }
  return url.toString().replace(/\/$/u, "");
}

function parseEnvFile(filePath: string): Record<string, string> {
  let contents = "";
  try {
    contents = readFileSync(filePath, "utf8");
  } catch (error) {
    if (error && typeof error === "object" && "code" in error && error.code === "ENOENT") {
      return {};
    }
    throw error;
  }
  const variables: Record<string, string> = {};

  for (const rawLine of contents.split(/\r?\n/u)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separator = line.indexOf("=");
    if (separator === -1) {
      continue;
    }

    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    variables[key] = value;
  }

  return variables;
}

function parseJsonFile(filePath: string): JsonRecord {
  let contents = "";
  try {
    contents = readFileSync(filePath, "utf8");
  } catch (error) {
    if (error && typeof error === "object" && "code" in error && error.code === "ENOENT") {
      return {};
    }
    throw error;
  }

  const parsed = JSON.parse(contents) as unknown;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`Expected JSON object in ${filePath}`);
  }
  return parsed as JsonRecord;
}

function asJsonRecord(value: unknown): JsonRecord | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  return value as JsonRecord;
}

function readNestedString(root: JsonRecord, ...pathSegments: string[]): string | undefined {
  let current: unknown = root;
  for (const segment of pathSegments) {
    const record = asJsonRecord(current);
    if (!record) {
      return undefined;
    }
    current = record[segment];
  }
  return typeof current === "string" && current.trim().length > 0 ? current.trim() : undefined;
}

function readNestedPositiveInteger(root: JsonRecord, ...pathSegments: string[]): number | undefined {
  let current: unknown = root;
  for (const segment of pathSegments) {
    const record = asJsonRecord(current);
    if (!record) {
      return undefined;
    }
    current = record[segment];
  }
  return typeof current === "number" && Number.isInteger(current) && current > 0 ? current : undefined;
}

function readJsonProviderValues(startDir = process.cwd()): Record<string, string> {
  const auth = parseJsonFile(resolveAuthJsonPath(startDir));
  const config = parseJsonFile(resolveConfigJsonPath(startDir));
  const values: Record<string, string> = {};

  const applyString = (targetKey: string, value: string | undefined) => {
    if (value) {
      values[targetKey] = value;
    }
  };
  const applyPositiveInteger = (targetKey: string, value: number | undefined) => {
    if (typeof value === "number") {
      values[targetKey] = String(value);
    }
  };

  applyString("OPENAI_API_KEY", readNestedString(auth, "openai", "apiKey"));
  applyString("OPENAI_BASE_URL", readNestedString(config, "openai", "baseURL"));
  applyString("OPENAI_MODEL", readNestedString(config, "openai", "model"));
  applyString("OPENAI_REASONING_EFFORT", readNestedString(config, "openai", "reasoningEffort"));
  applyPositiveInteger("OPENAI_CONTEXT_WINDOW_TOKENS", readNestedPositiveInteger(config, "openai", "contextWindowTokens"));

  applyString("ANTHROPIC_API_KEY", readNestedString(auth, "anthropic", "apiKey"));
  applyString("ANTHROPIC_BASE_URL", readNestedString(config, "anthropic", "baseURL"));
  applyString("ANTHROPIC_MODEL", readNestedString(config, "anthropic", "model"));
  applyPositiveInteger("ANTHROPIC_CONTEXT_WINDOW_TOKENS", readNestedPositiveInteger(config, "anthropic", "contextWindowTokens"));

  applyString("ANTHROPIC_ALT_API_KEY", readNestedString(auth, "anthropicAlt", "apiKey"));
  applyString("ANTHROPIC_ALT_BASE_URL", readNestedString(config, "anthropicAlt", "baseURL"));
  applyString("ANTHROPIC_ALT_MODEL", readNestedString(config, "anthropicAlt", "model"));
  applyPositiveInteger("ANTHROPIC_ALT_CONTEXT_WINDOW_TOKENS", readNestedPositiveInteger(config, "anthropicAlt", "contextWindowTokens"));

  applyString("DEEPMIND_API_KEY", readNestedString(auth, "deepmind", "apiKey"));
  applyString("DEEPMIND_BASE_URL", readNestedString(config, "deepmind", "baseURL"));
  applyString("DEEPMIND_MODEL", readNestedString(config, "deepmind", "model"));
  applyPositiveInteger("DEEPMIND_CONTEXT_WINDOW_TOKENS", readNestedPositiveInteger(config, "deepmind", "contextWindowTokens"));

  return values;
}

function mergeProcessEnv(values: Record<string, string>): Record<string, string> {
  const merged = { ...values };

  for (const [key, value] of Object.entries(process.env)) {
    if (typeof value === "string" && value.length > 0) {
      merged[key] = value;
    }
  }

  return merged;
}

function requireField(source: Record<string, string>, field: string): string {
  const value = source[field];
  if (!value) {
    throw new Error(`Missing required live smoke config field: ${field}`);
  }
  return value;
}

function readPositiveIntegerField(source: Record<string, string>, field: string): number | undefined {
  const raw = source[field];
  if (!raw) {
    return undefined;
  }
  const parsed = Number.parseInt(raw, 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : undefined;
}

function readMergedLiveValues(
  envPath = resolveLiveEnvPath(),
): Record<string, string> {
  const envValues = parseEnvFile(envPath);
  const jsonValues = readJsonProviderValues();
  const mergedBase = process.env.PRAXIS_LIVE_ENV_FILE
    ? { ...jsonValues, ...envValues }
    : { ...envValues, ...jsonValues };
  return mergeProcessEnv(mergedBase);
}

export function loadOpenAILiveConfig(
  envPath = resolveLiveEnvPath()
): OpenAILiveConfig {
  const values = readMergedLiveValues(envPath);
  return {
    apiKey: requireField(values, "OPENAI_API_KEY"),
    baseURL: normalizeOpenAIBaseURL(requireField(values, "OPENAI_BASE_URL")),
    model: requireField(values, "OPENAI_MODEL"),
    reasoningEffort: values.OPENAI_REASONING_EFFORT,
    contextWindowTokens: readPositiveIntegerField(values, "OPENAI_CONTEXT_WINDOW_TOKENS"),
  };
}

export function loadLiveProviderConfig(
  envPath = resolveLiveEnvPath()
): LiveProviderConfig {
  const values = readMergedLiveValues(envPath);

  const anthropicAltConfigured =
    values.ANTHROPIC_ALT_API_KEY !== undefined &&
    values.ANTHROPIC_ALT_BASE_URL !== undefined &&
    values.ANTHROPIC_ALT_MODEL !== undefined;

  return {
    openai: {
      apiKey: requireField(values, "OPENAI_API_KEY"),
      baseURL: normalizeOpenAIBaseURL(requireField(values, "OPENAI_BASE_URL")),
      model: requireField(values, "OPENAI_MODEL"),
      reasoningEffort: values.OPENAI_REASONING_EFFORT,
      contextWindowTokens: readPositiveIntegerField(values, "OPENAI_CONTEXT_WINDOW_TOKENS"),
    },
    anthropic: {
      apiKey: requireField(values, "ANTHROPIC_API_KEY"),
      baseURL: requireField(values, "ANTHROPIC_BASE_URL"),
      model: requireField(values, "ANTHROPIC_MODEL"),
      contextWindowTokens: readPositiveIntegerField(values, "ANTHROPIC_CONTEXT_WINDOW_TOKENS"),
    },
    anthropicAlt: anthropicAltConfigured
      ? {
          apiKey: requireField(values, "ANTHROPIC_ALT_API_KEY"),
          baseURL: requireField(values, "ANTHROPIC_ALT_BASE_URL"),
          model: requireField(values, "ANTHROPIC_ALT_MODEL"),
          contextWindowTokens: readPositiveIntegerField(values, "ANTHROPIC_ALT_CONTEXT_WINDOW_TOKENS"),
        }
      : undefined,
    deepmind: {
      apiKey: requireField(values, "DEEPMIND_API_KEY"),
      baseURL: requireField(values, "DEEPMIND_BASE_URL"),
      model: requireField(values, "DEEPMIND_MODEL"),
      contextWindowTokens: readPositiveIntegerField(values, "DEEPMIND_CONTEXT_WINDOW_TOKENS"),
    }
  };
}
