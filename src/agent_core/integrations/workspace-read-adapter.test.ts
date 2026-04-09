import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";

import { createCapabilityLease } from "../capability-invocation/capability-lease.js";
import { createCapabilityInvocationPlan } from "../capability-invocation/capability-plan.js";
import { createGoalSource } from "../goal/goal-source.js";
import { createAgentCoreRuntime } from "../runtime.js";
import type { CapabilityCallIntent } from "../types/index.js";
import { createAgentCapabilityProfile } from "../ta-pool-types/index.js";
import {
  createWorkspaceReadCapabilityAdapter,
  registerFirstClassToolingBaselineCapabilities,
} from "./workspace-read-adapter.js";

async function createWorkspaceFixture() {
  const root = await mkdtemp(path.join(tmpdir(), "praxis-workspace-read-"));
  await mkdir(path.join(root, "src"), { recursive: true });
  await mkdir(path.join(root, "docs"), { recursive: true });
  await writeFile(
    path.join(root, "src", "sample.ts"),
    [
      "export function answer() {",
      "  return 42;",
      "}",
      "",
      "export const meaning = answer();",
      "",
    ].join("\n"),
    "utf8",
  );
  await writeFile(
    path.join(root, "src", "consumer.ts"),
    [
      "import { answer } from './sample.js';",
      "",
      "export function ask() {",
      "  return answer();",
      "}",
      "",
    ].join("\n"),
    "utf8",
  );
  await writeFile(
    path.join(root, "docs", "guide.md"),
    "# Guide\n\nThis is the docs fixture.\n",
    "utf8",
  );
  await writeFile(
    path.join(root, "docs", "multibyte.md"),
    "你好世界，reviewer baseline。\n",
    "utf8",
  );
  await writeFile(path.join(root, "README.md"), "# Fixture\n", "utf8");
  return root;
}

test("workspace read adapter reads scoped code snippets with line ranges", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.read",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-read-1",
      sessionId: "session-code-read-1",
      runId: "run-code-read-1",
      capabilityKey: "code.read",
      input: {
        path: "src/sample.ts",
        operation: "read_lines",
        lineStart: 1,
        lineEnd: 2,
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-read-1",
    },
  );
  const lease = createCapabilityLease(
    {
      capabilityId: "cap-code-read-1",
      bindingId: "binding-code-read-1",
      generation: 1,
      plan,
    },
    {
      idFactory: () => "lease-code-read-1",
      clock: {
        now: () => new Date("2026-03-24T10:00:00.000Z"),
      },
    },
  );

  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);

  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { path: string }).path, "src/sample.ts");
  assert.match((envelope.output as { content: string }).content, /return 42/);
});

test("workspace read adapter blocks docs.read from escaping into code scope", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "docs.read",
    allowedPathPatterns: ["docs", "docs/**", "README.md", "*.md"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-docs-read-1",
      sessionId: "session-docs-read-1",
      runId: "run-docs-read-1",
      capabilityKey: "docs.read",
      input: {
        path: "src/sample.ts",
        operation: "read_file",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-docs-read-1",
    },
  );
  const lease = createCapabilityLease(
    {
      capabilityId: "cap-docs-read-1",
      bindingId: "binding-docs-read-1",
      generation: 1,
      plan,
    },
    {
      idFactory: () => "lease-docs-read-1",
      clock: {
        now: () => new Date("2026-03-24T10:05:00.000Z"),
      },
    },
  );

  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);

  assert.equal(envelope.status, "blocked");
  assert.equal(envelope.error?.code, "workspace_read_path_not_allowed");
});

test("workspace read adapter truncates multibyte content by byte budget and clears prepared state after execution", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "docs.read",
    allowedPathPatterns: ["docs", "docs/**", "*.md"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-docs-read-utf8-1",
      sessionId: "session-docs-read-utf8-1",
      runId: "run-docs-read-utf8-1",
      capabilityKey: "docs.read",
      input: {
        path: "docs/multibyte.md",
        operation: "read_file",
        maxBytes: 7,
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-docs-read-utf8-1",
    },
  );
  const lease = createCapabilityLease(
    {
      capabilityId: "cap-docs-read-utf8-1",
      bindingId: "binding-docs-read-utf8-1",
      generation: 1,
      plan,
    },
    {
      idFactory: () => "lease-docs-read-utf8-1",
      clock: {
        now: () => new Date("2026-03-24T10:07:00.000Z"),
      },
    },
  );

  const prepared = await adapter.prepare(plan, lease);
  const firstEnvelope = await adapter.execute(prepared);
  const secondEnvelope = await adapter.execute(prepared);

  assert.equal(firstEnvelope.status, "partial");
  assert.equal(
    Buffer.byteLength(
      (firstEnvelope.output as { content: string }).content,
      "utf8",
    ) <= 7,
    true,
  );
  assert.equal(firstEnvelope.metadata?.readOnly, true);
  assert.equal(firstEnvelope.metadata?.scopeKind, "workspace-docs");
  assert.equal(secondEnvelope.status, "failed");
  assert.equal(
    secondEnvelope.error?.code,
    "workspace_read_prepared_input_missing",
  );
});

test("workspace read adapter supports code.ls for bounded directory listing", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.ls",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-ls-1",
      sessionId: "session-code-ls-1",
      runId: "run-code-ls-1",
      capabilityKey: "code.ls",
      input: {
        path: "src",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-ls-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-ls-1",
    bindingId: "binding-code-ls-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-ls-1",
    clock: { now: () => new Date("2026-04-09T00:00:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { operation?: string }).operation, "list_dir");
  assert.equal(
    (envelope.output as { entries?: Array<{ name: string }> }).entries?.some((entry) => entry.name === "sample.ts"),
    true,
  );
});

test("workspace read adapter supports code.glob pattern discovery", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.glob",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-glob-1",
      sessionId: "session-code-glob-1",
      runId: "run-code-glob-1",
      capabilityKey: "code.glob",
      input: {
        path: "src",
        pattern: "src/**/*.ts",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-glob-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-glob-1",
    bindingId: "binding-code-glob-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-glob-1",
    clock: { now: () => new Date("2026-04-09T00:01:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.deepEqual((envelope.output as { matches?: string[] }).matches, ["src/consumer.ts", "src/sample.ts"]);
});

test("workspace read adapter supports code.grep with bounded content hits", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.grep",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-grep-1",
      sessionId: "session-code-grep-1",
      runId: "run-code-grep-1",
      capabilityKey: "code.grep",
      input: {
        path: "src",
        pattern: "answer",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-grep-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-grep-1",
    bindingId: "binding-code-grep-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-grep-1",
    clock: { now: () => new Date("2026-04-09T00:02:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal(
    (envelope.output as { matches?: Array<{ path: string }> }).matches?.some((entry) => entry.path === "src/sample.ts"),
    true,
  );
});

test("workspace read adapter supports code.read_many via include globs", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.read_many",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-read-many-1",
      sessionId: "session-code-read-many-1",
      runId: "run-code-read-many-1",
      capabilityKey: "code.read_many",
      input: {
        path: "src",
        include: ["src/**/*.ts"],
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-read-many-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-read-many-1",
    bindingId: "binding-code-read-many-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-read-many-1",
    clock: { now: () => new Date("2026-04-09T00:03:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { count?: number }).count, 2);
  assert.equal(
    (envelope.output as { documents?: Array<{ path: string }> }).documents?.some((entry) => entry.path === "src/sample.ts"),
    true,
  );
});

test("workspace read adapter supports code.symbol_search via TypeScript workspace symbol search", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.symbol_search",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-symbol-search-1",
      sessionId: "session-code-symbol-search-1",
      runId: "run-code-symbol-search-1",
      capabilityKey: "code.symbol_search",
      input: {
        path: ".",
        query: "answer",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-symbol-search-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-symbol-search-1",
    bindingId: "binding-code-symbol-search-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-symbol-search-1",
    clock: { now: () => new Date("2026-04-09T00:04:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { backend?: string }).backend, "typescript-language-service");
  assert.equal((envelope.output as { matches?: Array<{ name: string }> }).matches?.[0]?.name, "answer");
});

test("workspace read adapter supports code.lsp document symbols", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.lsp",
    allowedPathPatterns: ["src", "src/**"],
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-lsp-doc-1",
      sessionId: "session-code-lsp-doc-1",
      runId: "run-code-lsp-doc-1",
      capabilityKey: "code.lsp",
      input: {
        path: "src/sample.ts",
        operation: "document_symbol",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-lsp-doc-1",
    },
  );
  const prepared = await adapter.prepare(plan, createCapabilityLease({
    capabilityId: "cap-code-lsp-doc-1",
    bindingId: "binding-code-lsp-doc-1",
    generation: 1,
    plan,
  }, {
    idFactory: () => "lease-code-lsp-doc-1",
    clock: { now: () => new Date("2026-04-09T00:05:00.000Z") },
  }));
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { symbols?: Array<{ name: string }> }).symbols?.[0]?.name, "answer");
});

test("workspace read adapter supports code.lsp definitions and references", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const adapter = createWorkspaceReadCapabilityAdapter({
    workspaceRoot,
    capabilityKey: "code.lsp",
    allowedPathPatterns: ["src", "src/**"],
  });

  const definitionPlan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-lsp-def-1",
      sessionId: "session-code-lsp-def-1",
      runId: "run-code-lsp-def-1",
      capabilityKey: "code.lsp",
      input: {
        path: "src/consumer.ts",
        operation: "definition",
        line: 4,
        character: 10,
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-lsp-def-1",
    },
  );
  const definitionPrepared = await adapter.prepare(definitionPlan, createCapabilityLease({
    capabilityId: "cap-code-lsp-def-1",
    bindingId: "binding-code-lsp-def-1",
    generation: 1,
    plan: definitionPlan,
  }, {
    idFactory: () => "lease-code-lsp-def-1",
    clock: { now: () => new Date("2026-04-09T00:06:00.000Z") },
  }));
  const definitionEnvelope = await adapter.execute(definitionPrepared);
  assert.equal(definitionEnvelope.status, "success");
  assert.equal((definitionEnvelope.output as { definitions?: Array<{ path: string }> }).definitions?.[0]?.path, "src/sample.ts");

  const referencesPlan = createCapabilityInvocationPlan(
    {
      intentId: "intent-code-lsp-refs-1",
      sessionId: "session-code-lsp-refs-1",
      runId: "run-code-lsp-refs-1",
      capabilityKey: "code.lsp",
      input: {
        path: "src/sample.ts",
        operation: "references",
        line: 1,
        character: 17,
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan-code-lsp-refs-1",
    },
  );
  const referencesPrepared = await adapter.prepare(referencesPlan, createCapabilityLease({
    capabilityId: "cap-code-lsp-refs-1",
    bindingId: "binding-code-lsp-refs-1",
    generation: 1,
    plan: referencesPlan,
  }, {
    idFactory: () => "lease-code-lsp-refs-1",
    clock: { now: () => new Date("2026-04-09T00:07:00.000Z") },
  }));
  const referencesEnvelope = await adapter.execute(referencesPrepared);
  assert.equal(referencesEnvelope.status, "success");
  assert.equal(
    (referencesEnvelope.output as { references?: Array<{ path: string }> }).references?.some((entry) => entry.path === "src/consumer.ts"),
    true,
  );
});

test("workspace read baseline registration lets TAP dispatch docs.read through the pooled baseline path", async () => {
  const workspaceRoot = await createWorkspaceFixture();
  const runtime = createAgentCoreRuntime({
    taProfile: createAgentCapabilityProfile({
      profileId: "profile.workspace-read-baseline",
      agentClass: "reviewer",
      baselineCapabilities: ["docs.read", "code.read"],
    }),
  });
  const registration = registerFirstClassToolingBaselineCapabilities({
    runtime,
    workspaceRoot,
  });

  const session = runtime.createSession();
  const goal = runtime.createCompiledGoal(
    createGoalSource({
      goalId: "goal-workspace-read-baseline",
      sessionId: session.sessionId,
      userInput: "Use docs.read through the TAP baseline.",
    }),
  );
  const created = await runtime.createRun({
    sessionId: session.sessionId,
    goal,
  });
  const intent: CapabilityCallIntent = {
    intentId: "intent-workspace-read-baseline-1",
    sessionId: session.sessionId,
    runId: created.run.runId,
    kind: "capability_call",
    createdAt: "2026-03-24T10:10:00.000Z",
    priority: "normal",
    request: {
      requestId: "request-workspace-read-baseline-1",
      intentId: "intent-workspace-read-baseline-1",
      sessionId: session.sessionId,
      runId: created.run.runId,
      capabilityKey: "docs.read",
      input: {
        path: "docs/guide.md",
        operation: "read_file",
      },
      priority: "normal",
    },
  };

  const result = await runtime.dispatchCapabilityIntentViaTaPool(intent, {
    agentId: "reviewer-agent",
    requestedTier: "B0",
    mode: "standard",
    reason:
      "Reviewer baseline should read project docs without review friction.",
  });

  assert.equal(result.status, "dispatched");
  assert.equal(result.grant?.capabilityKey, "docs.read");
  assert.deepEqual(
    registration.capabilityKeys,
    ["code.read", "code.ls", "code.glob", "code.grep", "code.read_many", "code.symbol_search", "code.lsp", "docs.read"],
  );
  assert.deepEqual(
    registration.descriptors.map((entry) => entry.capabilityKey),
    ["code.read", "code.ls", "code.glob", "code.grep", "code.read_many", "code.symbol_search", "code.lsp", "docs.read"],
  );
  assert.equal(
    registration.descriptors.find((entry) => entry.capabilityKey === "docs.read")?.scopeKind,
    "workspace-docs",
  );
  await new Promise((resolve) => setTimeout(resolve, 30));
  const resultEvent = runtime
    .readRunEvents(created.run.runId)
    .find((entry) => entry.event.type === "capability.result_received");
  assert.ok(resultEvent);
  assert.equal(resultEvent?.event.metadata?.scopeKind, "workspace-docs");
  assert.equal(resultEvent?.event.metadata?.readOnly, true);
});
