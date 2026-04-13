import assert from "node:assert/strict";
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { loadLiveProviderConfig, loadOpenAILiveConfig } from "./live-config.js";

async function writeEnvFile(contents: string): Promise<string> {
  const rootDir = await mkdtemp(path.join(os.tmpdir(), "praxis-live-config-"));
  const envPath = path.join(rootDir, ".env.local");
  await writeFile(envPath, contents, "utf8");
  return envPath;
}

test("loadLiveProviderConfig reads .env.local values when no process overrides are set", async () => {
  const envPath = await writeEnvFile(`
OPENAI_API_KEY=test-openai
OPENAI_BASE_URL=https://example.com
OPENAI_MODEL=gpt-5.4
ANTHROPIC_API_KEY=test-anthropic
ANTHROPIC_BASE_URL=https://anthropic.example.com
ANTHROPIC_MODEL=claude-opus-4-6-thinking
DEEPMIND_API_KEY=test-deepmind
DEEPMIND_BASE_URL=https://deepmind.example.com
DEEPMIND_MODEL=gemini-3.1-pro-preview
  `.trim());

  const originalEnv = {
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_MODEL: process.env.OPENAI_MODEL
  };

  try {
    delete process.env.PRAXIS_LIVE_ENV_FILE;
    delete process.env.OPENAI_MODEL;

    const config = loadLiveProviderConfig(envPath);

    assert.equal(config.openai.model, "gpt-5.4");
    assert.equal(config.openai.baseURL, "https://example.com/v1");
    assert.equal(config.anthropic.model, "claude-opus-4-6-thinking");
    assert.equal(config.deepmind.model, "gemini-3.1-pro-preview");
  } finally {
    if (originalEnv.PRAXIS_LIVE_ENV_FILE === undefined) {
      delete process.env.PRAXIS_LIVE_ENV_FILE;
    } else {
      process.env.PRAXIS_LIVE_ENV_FILE = originalEnv.PRAXIS_LIVE_ENV_FILE;
    }
    if (originalEnv.OPENAI_MODEL === undefined) {
      delete process.env.OPENAI_MODEL;
    } else {
      process.env.OPENAI_MODEL = originalEnv.OPENAI_MODEL;
    }
  }
});

test("loadLiveProviderConfig lets process env override .env.local values", async () => {
  const envPath = await writeEnvFile(`
OPENAI_API_KEY=test-openai
OPENAI_BASE_URL=https://example.com
OPENAI_MODEL=gpt-5.4
ANTHROPIC_API_KEY=test-anthropic
ANTHROPIC_BASE_URL=https://anthropic.example.com
ANTHROPIC_MODEL=claude-opus-4.6-thinking
DEEPMIND_API_KEY=test-deepmind
DEEPMIND_BASE_URL=https://deepmind.example.com
DEEPMIND_MODEL=gemini-3-flash
  `.trim());

  const originalEnv = {
    OPENAI_MODEL: process.env.OPENAI_MODEL,
    ANTHROPIC_MODEL: process.env.ANTHROPIC_MODEL,
    DEEPMIND_BASE_URL: process.env.DEEPMIND_BASE_URL
  };

  try {
    process.env.OPENAI_MODEL = "gpt-5";
    process.env.ANTHROPIC_MODEL = "claude-opus-4-6-thinking";
    process.env.DEEPMIND_BASE_URL = "https://viewpro.top/v1beta/models";

    const config = loadLiveProviderConfig(envPath);

    assert.equal(config.openai.model, "gpt-5");
    assert.equal(config.anthropic.model, "claude-opus-4-6-thinking");
    assert.equal(config.deepmind.baseURL, "https://viewpro.top/v1beta/models");
  } finally {
    if (originalEnv.OPENAI_MODEL === undefined) {
      delete process.env.OPENAI_MODEL;
    } else {
      process.env.OPENAI_MODEL = originalEnv.OPENAI_MODEL;
    }
    if (originalEnv.ANTHROPIC_MODEL === undefined) {
      delete process.env.ANTHROPIC_MODEL;
    } else {
      process.env.ANTHROPIC_MODEL = originalEnv.ANTHROPIC_MODEL;
    }
    if (originalEnv.DEEPMIND_BASE_URL === undefined) {
      delete process.env.DEEPMIND_BASE_URL;
    } else {
      process.env.DEEPMIND_BASE_URL = originalEnv.DEEPMIND_BASE_URL;
    }
  }
});

test("loadLiveProviderConfig can run from process env only when the env file is absent", () => {
  const originalEnv = {
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    ANTHROPIC_BASE_URL: process.env.ANTHROPIC_BASE_URL,
    ANTHROPIC_MODEL: process.env.ANTHROPIC_MODEL,
    DEEPMIND_API_KEY: process.env.DEEPMIND_API_KEY,
    DEEPMIND_BASE_URL: process.env.DEEPMIND_BASE_URL,
    DEEPMIND_MODEL: process.env.DEEPMIND_MODEL
  };

  try {
    process.env.PRAXIS_LIVE_ENV_FILE = path.join(os.tmpdir(), "praxis-missing-live-config.env");
    process.env.OPENAI_API_KEY = "test-openai";
    process.env.OPENAI_BASE_URL = "https://openai.example.com";
    process.env.OPENAI_MODEL = "gpt-5.4";
    process.env.ANTHROPIC_API_KEY = "test-anthropic";
    process.env.ANTHROPIC_BASE_URL = "https://anthropic.example.com";
    process.env.ANTHROPIC_MODEL = "claude-opus-4-6-thinking";
    process.env.DEEPMIND_API_KEY = "test-deepmind";
    process.env.DEEPMIND_BASE_URL = "https://deepmind.example.com";
    process.env.DEEPMIND_MODEL = "gemini-3.1-pro-preview";

    const config = loadLiveProviderConfig();

    assert.equal(config.openai.baseURL, "https://openai.example.com/v1");
    assert.equal(config.anthropic.baseURL, "https://anthropic.example.com");
    assert.equal(config.deepmind.model, "gemini-3.1-pro-preview");
  } finally {
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});

test("loadOpenAILiveConfig only requires the OpenAI fields", async () => {
  const envPath = await writeEnvFile(`
OPENAI_API_KEY=test-openai
OPENAI_BASE_URL=https://openai.example.com
OPENAI_MODEL=gpt-5.4
  `.trim());

  const originalEnv = {
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    DEEPMIND_API_KEY: process.env.DEEPMIND_API_KEY,
  };

  try {
    process.env.PRAXIS_LIVE_ENV_FILE = envPath;
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_BASE_URL;
    delete process.env.OPENAI_MODEL;
    delete process.env.ANTHROPIC_API_KEY;
    delete process.env.DEEPMIND_API_KEY;

    const config = loadOpenAILiveConfig();

    assert.equal(config.apiKey, "test-openai");
    assert.equal(config.baseURL, "https://openai.example.com/v1");
    assert.equal(config.model, "gpt-5.4");
  } finally {
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});

test("loadOpenAILiveConfig walks upward to the nearest parent .env.local", async () => {
  const rootDir = await mkdtemp(path.join(os.tmpdir(), "praxis-live-config-parent-"));
  const nestedDir = path.join(rootDir, "a", "b", "c");
  await mkdir(nestedDir, { recursive: true });
  await writeFile(path.join(rootDir, ".env.local"), [
    "OPENAI_API_KEY=test-openai-parent",
    "OPENAI_BASE_URL=https://openai.parent.example.com",
    "OPENAI_MODEL=gpt-5.4",
  ].join("\n"), "utf8");

  const originalCwd = process.cwd();
  const originalEnv = {
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
  };

  try {
    process.chdir(nestedDir);
    delete process.env.PRAXIS_LIVE_ENV_FILE;
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_BASE_URL;
    delete process.env.OPENAI_MODEL;

    const config = loadOpenAILiveConfig();

    assert.equal(config.apiKey, "test-openai-parent");
    assert.equal(config.baseURL, "https://openai.parent.example.com/v1");
    assert.equal(config.model, "gpt-5.4");
  } finally {
    process.chdir(originalCwd);
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});

test("loadOpenAILiveConfig prefers ~/.raxcode/.env over workspace .env.local", async () => {
  const rootDir = await mkdtemp(path.join(os.tmpdir(), "praxis-live-config-home-"));
  const workspaceDir = path.join(rootDir, "workspace");
  const raxcodeHome = path.join(rootDir, ".raxcode");
  await mkdir(workspaceDir, { recursive: true });
  await mkdir(raxcodeHome, { recursive: true });
  await writeFile(path.join(workspaceDir, ".env.local"), [
    "OPENAI_API_KEY=workspace-openai",
    "OPENAI_BASE_URL=https://workspace.example.com",
    "OPENAI_MODEL=gpt-workspace",
  ].join("\n"), "utf8");
  await writeFile(path.join(raxcodeHome, ".env"), [
    "OPENAI_API_KEY=home-openai",
    "OPENAI_BASE_URL=https://home.example.com",
    "OPENAI_MODEL=gpt-home",
  ].join("\n"), "utf8");

  const originalCwd = process.cwd();
  const originalEnv = {
    RAXCODE_HOME: process.env.RAXCODE_HOME,
    PRAXIS_CONFIG_ROOT: process.env.PRAXIS_CONFIG_ROOT,
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
  };

  try {
    process.chdir(workspaceDir);
    process.env.RAXCODE_HOME = raxcodeHome;
    delete process.env.PRAXIS_CONFIG_ROOT;
    delete process.env.PRAXIS_LIVE_ENV_FILE;
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_BASE_URL;
    delete process.env.OPENAI_MODEL;

    const config = loadOpenAILiveConfig();

    assert.equal(config.apiKey, "home-openai");
    assert.equal(config.baseURL, "https://home.example.com/v1");
    assert.equal(config.model, "gpt-home");
  } finally {
    process.chdir(originalCwd);
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});

test("loadLiveProviderConfig reads ~/.raxcode/auth.json and config.json as the global primary source", async () => {
  const rootDir = await mkdtemp(path.join(os.tmpdir(), "praxis-live-config-json-"));
  const workspaceDir = path.join(rootDir, "workspace");
  const raxcodeHome = path.join(rootDir, ".raxcode");
  await mkdir(workspaceDir, { recursive: true });
  await mkdir(raxcodeHome, { recursive: true });
  await writeFile(path.join(raxcodeHome, "auth.json"), JSON.stringify({
    openai: { apiKey: "json-openai-key" },
    anthropic: { apiKey: "json-anthropic-key" },
    deepmind: { apiKey: "json-deepmind-key" },
  }, null, 2), "utf8");
  await writeFile(path.join(raxcodeHome, "config.json"), JSON.stringify({
    openai: {
      baseURL: "https://json-openai.example.com",
      model: "gpt-json",
      reasoningEffort: "high",
      contextWindowTokens: 321000,
    },
    anthropic: {
      baseURL: "https://json-anthropic.example.com",
      model: "claude-json",
      contextWindowTokens: 222000,
    },
    deepmind: {
      baseURL: "https://json-deepmind.example.com",
      model: "gemini-json",
      contextWindowTokens: 111000,
    },
  }, null, 2), "utf8");

  const originalCwd = process.cwd();
  const originalEnv = {
    RAXCODE_HOME: process.env.RAXCODE_HOME,
    PRAXIS_CONFIG_ROOT: process.env.PRAXIS_CONFIG_ROOT,
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    ANTHROPIC_BASE_URL: process.env.ANTHROPIC_BASE_URL,
    ANTHROPIC_MODEL: process.env.ANTHROPIC_MODEL,
    DEEPMIND_API_KEY: process.env.DEEPMIND_API_KEY,
    DEEPMIND_BASE_URL: process.env.DEEPMIND_BASE_URL,
    DEEPMIND_MODEL: process.env.DEEPMIND_MODEL,
  };

  try {
    process.chdir(workspaceDir);
    process.env.RAXCODE_HOME = raxcodeHome;
    delete process.env.PRAXIS_CONFIG_ROOT;
    delete process.env.PRAXIS_LIVE_ENV_FILE;
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_BASE_URL;
    delete process.env.OPENAI_MODEL;
    delete process.env.ANTHROPIC_API_KEY;
    delete process.env.ANTHROPIC_BASE_URL;
    delete process.env.ANTHROPIC_MODEL;
    delete process.env.DEEPMIND_API_KEY;
    delete process.env.DEEPMIND_BASE_URL;
    delete process.env.DEEPMIND_MODEL;

    const config = loadLiveProviderConfig();

    assert.equal(config.openai.apiKey, "json-openai-key");
    assert.equal(config.openai.baseURL, "https://json-openai.example.com/v1");
    assert.equal(config.openai.model, "gpt-json");
    assert.equal(config.openai.reasoningEffort, "high");
    assert.equal(config.openai.contextWindowTokens, 321000);
    assert.equal(config.anthropic.apiKey, "json-anthropic-key");
    assert.equal(config.anthropic.model, "claude-json");
    assert.equal(config.deepmind.apiKey, "json-deepmind-key");
    assert.equal(config.deepmind.model, "gemini-json");
  } finally {
    process.chdir(originalCwd);
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});

test("explicit PRAXIS_LIVE_ENV_FILE overrides ~/.raxcode auth.json and config.json", async () => {
  const rootDir = await mkdtemp(path.join(os.tmpdir(), "praxis-live-config-json-explicit-"));
  const raxcodeHome = path.join(rootDir, ".raxcode");
  await mkdir(raxcodeHome, { recursive: true });
  await writeFile(path.join(raxcodeHome, "auth.json"), JSON.stringify({
    openai: { apiKey: "json-openai-key" },
  }, null, 2), "utf8");
  await writeFile(path.join(raxcodeHome, "config.json"), JSON.stringify({
    openai: {
      baseURL: "https://json-openai.example.com",
      model: "gpt-json",
    },
  }, null, 2), "utf8");

  const explicitEnvPath = await writeEnvFile(`
OPENAI_API_KEY=explicit-openai-key
OPENAI_BASE_URL=https://explicit-openai.example.com
OPENAI_MODEL=gpt-explicit
  `.trim());

  const originalEnv = {
    RAXCODE_HOME: process.env.RAXCODE_HOME,
    PRAXIS_LIVE_ENV_FILE: process.env.PRAXIS_LIVE_ENV_FILE,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL,
    OPENAI_MODEL: process.env.OPENAI_MODEL,
  };

  try {
    process.env.RAXCODE_HOME = raxcodeHome;
    process.env.PRAXIS_LIVE_ENV_FILE = explicitEnvPath;
    delete process.env.OPENAI_API_KEY;
    delete process.env.OPENAI_BASE_URL;
    delete process.env.OPENAI_MODEL;

    const config = loadOpenAILiveConfig();

    assert.equal(config.apiKey, "explicit-openai-key");
    assert.equal(config.baseURL, "https://explicit-openai.example.com/v1");
    assert.equal(config.model, "gpt-explicit");
  } finally {
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
});
