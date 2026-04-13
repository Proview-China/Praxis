import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

function resolveUserHome(fallbackDir = process.cwd()): string {
  return process.env.HOME ?? process.env.USERPROFILE ?? fallbackDir;
}

export function resolveRaxcodeHome(fallbackDir = process.cwd()): string {
  return resolve(process.env.RAXCODE_HOME ?? join(resolveUserHome(fallbackDir), ".raxcode"));
}

export function resolveConfigRoot(fallbackDir = process.cwd()): string {
  return resolve(process.env.PRAXIS_CONFIG_ROOT ?? resolveRaxcodeHome(fallbackDir));
}

export function resolveStateRoot(fallbackDir = process.cwd()): string {
  return resolve(process.env.PRAXIS_STATE_ROOT ?? resolveRaxcodeHome(fallbackDir));
}

export function resolveWorkspaceRoot(fallbackDir = process.cwd()): string {
  return resolve(process.env.PRAXIS_WORKSPACE_ROOT ?? fallbackDir);
}

export function resolveAppRoot(fallbackDir = process.cwd()): string {
  return resolve(process.env.PRAXIS_APP_ROOT ?? fallbackDir);
}

export function resolveConfiguredLiveEnvPath(fallbackDir = process.cwd()): string {
  return resolve(process.env.PRAXIS_LIVE_ENV_FILE ?? join(resolveConfigRoot(fallbackDir), ".env"));
}

export function resolveAuthJsonPath(fallbackDir = process.cwd()): string {
  return resolve(resolveConfigRoot(fallbackDir), "auth.json");
}

export function resolveConfigJsonPath(fallbackDir = process.cwd()): string {
  return resolve(resolveConfigRoot(fallbackDir), "config.json");
}

export function resolveLegacyLiveEnvPath(startDir = process.cwd()): string {
  let current = resolve(startDir);

  while (true) {
    const candidate = resolve(current, ".env.local");
    if (existsSync(candidate)) {
      return candidate;
    }

    const parent = dirname(current);
    if (parent === current) {
      return resolve(startDir, ".env.local");
    }
    current = parent;
  }
}

export function resolveLiveEnvPath(startDir = process.cwd()): string {
  const configuredPath = resolveConfiguredLiveEnvPath(startDir);
  if (process.env.PRAXIS_LIVE_ENV_FILE || existsSync(configuredPath)) {
    return configuredPath;
  }
  return resolveLegacyLiveEnvPath(startDir);
}

export function resolveLiveReportsDir(fallbackDir = process.cwd()): string {
  return resolve(resolveStateRoot(fallbackDir), "live-reports");
}
