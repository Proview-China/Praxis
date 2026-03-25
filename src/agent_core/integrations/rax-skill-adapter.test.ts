import assert from "node:assert/strict";
import test from "node:test";

import type { PreparedInvocation } from "../../rax/contracts.js";
import type {
  SkillActivationPlan,
  SkillContainer,
  SkillMountResult,
  SkillUseResult,
} from "../../rax/index.js";
import { createCapabilityLease } from "../capability-invocation/capability-lease.js";
import { createCapabilityInvocationPlan } from "../capability-invocation/capability-plan.js";
import {
  createCapabilityPackage,
  createCapabilityPackageActivationSpecRef,
} from "../capability-package/index.js";
import {
  createActivationFactoryResolver,
  materializeActivationRegistration,
} from "../ta-pool-runtime/index.js";
import { createPoolActivationSpec } from "../ta-pool-types/index.js";
import {
  createRaxSkillActivationFactory,
  createRaxSkillCapabilityAdapter,
  RAX_SKILL_ACTIVATION_FACTORY_REFS,
  registerRaxSkillCapabilityFamily,
} from "./rax-skill-adapter.js";

function createContainer(): SkillContainer {
  return {
    descriptor: {
      id: "skill_browser",
      name: "Browser Skill",
      description: "Drive a browser workflow.",
      version: "v1",
      tags: ["browser"],
      triggers: ["open page"],
      source: {
        kind: "local",
        rootDir: "/skills/browser",
        entryPath: "/skills/browser/SKILL.md",
      },
    },
    source: {
      kind: "local",
      rootDir: "/skills/browser",
      entryPath: "/skills/browser/SKILL.md",
    },
    entry: {
      path: "/skills/browser/SKILL.md",
      content: "# Browser Skill",
    },
    resources: [],
    helpers: [],
    bindings: {},
    policy: {
      invocationMode: "auto",
      requiresApproval: false,
      riskLevel: "low",
      sourceTrust: "local",
    },
    loading: {
      metadata: "always",
      entry: "on-activate",
      resources: "on-demand",
      helpers: "on-demand",
    },
    ledger: {
      discoverCount: 0,
      activationCount: 0,
    },
  };
}

function createActivation(provider: SkillActivationPlan["provider"]): SkillActivationPlan {
  return {
    provider,
    mode: provider === "anthropic" ? "anthropic-sdk-filesystem" : provider === "deepmind" ? "google-adk-local" : "openai-local-shell",
    layer: "agent",
    officialCarrier:
      provider === "anthropic"
        ? "anthropic-sdk-filesystem-skill"
        : provider === "deepmind"
          ? "google-adk-skill-toolset"
          : "openai-shell-environment",
    composeStrategy:
      provider === "anthropic" || provider === "deepmind"
        ? "runtime-only"
        : "payload-merge",
    composeNotes:
      provider === "anthropic"
        ? "Anthropic filesystem skills currently require the SDK runtime path instead of payload-merge composition."
        : provider === "deepmind"
          ? "Google ADK skill carriers currently require an ADK runtime path instead of payload-merge composition."
          : "OpenAI shell skill carriers can currently be merged into Responses generation requests.",
    payload: {},
    entry: {
      path: "/skills/browser/SKILL.md",
      content: "# Browser Skill",
    },
    resources: [],
    helpers: [],
  } as SkillActivationPlan;
}

function createInvocation(provider: "openai" | "anthropic" | "deepmind"): PreparedInvocation<Record<string, unknown>> {
  return {
    key: "skill.use",
    provider,
    model: "gpt-5.4",
    layer: "agent",
    adapterId: "skill.adapter",
    sdk: {
      packageName: "@test/skill",
      entrypoint: "skill.use",
    },
    payload: {},
  };
}

function createSkillCapabilityPackage(
  capabilityKey: "skill.use" | "skill.mount" | "skill.prepare",
) {
  const activationSpec = createPoolActivationSpec({
    targetPool: "ta-capability-pool",
    activationMode: "activate_after_verify",
    registerOrReplace: "register_or_replace",
    generationStrategy: "create_next_generation",
    drainStrategy: "graceful",
    manifestPayload: {
      capabilityKey,
      capabilityId: `capability:${capabilityKey}:1`,
      version: "1.0.0",
      generation: 1,
      kind: "tool",
      description: `Fixture package for ${capabilityKey}.`,
      supportsPrepare: true,
      routeHints: [
        { key: "capability_family", value: "skill" },
        { key: "skill_action", value: capabilityKey.replace("skill.", "") },
      ],
    },
    bindingPayload: {
      adapterId: "rax.skill.adapter",
      runtimeKind: "rax-skill",
      capabilityKey,
    },
    adapterFactoryRef: RAX_SKILL_ACTIVATION_FACTORY_REFS[capabilityKey],
  });

  return createCapabilityPackage({
    manifest: {
      capabilityKey,
      capabilityKind: "tool",
      tier: "B1",
      version: "1.0.0",
      generation: 1,
      description: `Fixture package for ${capabilityKey}.`,
      dependencies: ["rax.skill"],
      tags: ["skill", "tap", "rax"],
      routeHints: [
        { key: "runtime", value: "rax-skill" },
        { key: "capability_family", value: "skill" },
        { key: "skill_action", value: capabilityKey.replace("skill.", "") },
      ],
      supportedPlatforms: ["linux", "macos", "windows"],
    },
    adapter: {
      adapterId: "rax.skill.adapter",
      runtimeKind: "rax-skill",
      supports: [capabilityKey],
      prepare: {
        ref: `fixture:${capabilityKey}:prepare`,
      },
      execute: {
        ref: `fixture:${capabilityKey}:execute`,
      },
      resultMapping: {
        successStatuses: ["success"],
        artifactKinds: ["tool"],
      },
    },
    policy: {
      defaultBaseline: {
        grantedTier: "B1",
        mode: "standard",
        scope: {
          allowedOperations: [capabilityKey],
        },
      },
      recommendedMode: "standard",
      riskLevel: "normal",
      defaultScope: {
        allowedOperations: [capabilityKey],
      },
      reviewRequirements: ["allow_with_constraints"],
      safetyFlags: [],
      humanGateRequirements: [],
    },
    builder: {
      builderId: `builder:${capabilityKey}:fixture`,
      buildStrategy: "mount-existing-runtime",
      requiresNetwork: false,
      requiresInstall: false,
      requiresSystemWrite: false,
      allowedWorkdirScope: ["workspace/**"],
      activationSpecRef: createCapabilityPackageActivationSpecRef(activationSpec),
      replayCapability: "re_review_then_dispatch",
    },
    verification: {
      smokeEntry: `fixture:${capabilityKey}:smoke`,
      healthEntry: `fixture:${capabilityKey}:health`,
      successCriteria: ["returns a capability result envelope"],
      failureSignals: ["fixture failed"],
      evidenceOutput: ["capability-result-envelope"],
    },
    usage: {
      usageDocRef: "docs/fixtures/rax-skill-adapter.md",
      bestPractices: ["Fixture only."],
      knownLimits: ["Fixture only."],
      exampleInvocations: [
        {
          exampleId: `fixture.${capabilityKey}`,
          capabilityKey,
          operation: capabilityKey,
          input: {
            provider: "openai",
            model: "gpt-5.4",
          },
        },
      ],
    },
    lifecycle: {
      installStrategy: "fixture",
      replaceStrategy: "fixture",
      rollbackStrategy: "fixture",
      deprecateStrategy: "fixture",
      cleanupStrategy: "fixture",
      generationPolicy: "create_next_generation",
    },
    activationSpec,
    replayPolicy: "re_review_then_dispatch",
    metadata: {
      bundleId: `bundle:${capabilityKey}:fixture`,
      provisionId: `provision:${capabilityKey}:fixture`,
    },
  });
}

test("rax skill adapter supports skill.use plan with normalized route context", () => {
  const adapter = createRaxSkillCapabilityAdapter({
    skill: {} as never,
  });

  const plan = {
    planId: "plan_001",
    intentId: "intent_001",
    sessionId: "session_001",
    runId: "run_001",
    capabilityKey: "skill.use",
    operation: "skill.use",
    input: {
      route: {
        provider: "openai",
        model: "gpt-5.4",
        layer: "agent",
      },
      source: "/skills/browser",
    },
    priority: "high" as const,
  };

  assert.equal(adapter.supports(plan), true);
});

test("rax skill adapter supports skill.use plans that attach a remote skill reference", () => {
  const adapter = createRaxSkillCapabilityAdapter({
    skill: {} as never,
  });

  const plan = {
    planId: "plan_ref_001",
    intentId: "intent_ref_001",
    sessionId: "session_ref_001",
    runId: "run_ref_001",
    capabilityKey: "skill.use",
    operation: "skill.use",
    input: {
      route: {
        provider: "anthropic",
        model: "claude-opus-4-6-thinking",
        layer: "api",
      },
      reference: {
        id: "pptx",
        version: "latest",
      },
      mode: "anthropic-api-managed",
      details: {
        type: "anthropic",
      },
    },
    priority: "high" as const,
  };

  assert.equal(adapter.supports(plan), true);
});

test("rax skill adapter prepare builds a direct prepared call for skill.use", async () => {
  const adapter = createRaxSkillCapabilityAdapter({
    skill: {} as never,
  });

  const plan = {
    planId: "plan_001",
    intentId: "intent_001",
    sessionId: "session_001",
    runId: "run_001",
    capabilityKey: "skill.use",
    operation: "skill.use",
    input: {
      provider: "openai",
      model: "gpt-5.4",
      layer: "agent",
      source: "/skills/browser",
    },
    priority: "normal" as const,
    idempotencyKey: "skill:browser:use",
  };

  const lease = {
    leaseId: "lease_001",
    capabilityId: "skill.use",
    bindingId: "binding_001",
    generation: 1,
    grantedAt: "2026-03-18T00:00:00.000Z",
    priority: "normal" as const,
    preparedCacheKey: "prepared:skill:browser:use",
  };

  const prepared = await adapter.prepare(plan, lease);
  assert.equal(prepared.bindingId, "binding_001");
  assert.equal(prepared.executionMode, "direct");
  assert.equal(prepared.cacheKey, "prepared:skill:browser:use");
});

test("rax skill adapter execute maps skill.use and returns sanitized output", async () => {
  const container = createContainer();
  const facade = {
    skill: {
      async use(): Promise<SkillUseResult> {
        return {
          container,
          activation: createActivation("openai"),
          invocation: createInvocation("openai"),
        };
      },
      mount(): SkillMountResult {
        throw new Error("mount should not be called in this test");
      },
      prepare(): PreparedInvocation<Record<string, unknown>> {
        throw new Error("prepare should not be called in this test");
      },
    },
  };

  const adapter = createRaxSkillCapabilityAdapter(facade);
  const plan = {
    planId: "plan_001",
    intentId: "intent_001",
    sessionId: "session_001",
    runId: "run_001",
    capabilityKey: "skill.use",
    operation: "skill.use",
    input: {
      provider: "openai",
      model: "gpt-5.4",
      layer: "agent",
      source: "/skills/browser",
      includeResources: true,
    },
    priority: "normal" as const,
  };
  const lease = {
    leaseId: "lease_001",
    capabilityId: "skill.use",
    bindingId: "binding_001",
    generation: 1,
    grantedAt: "2026-03-18T00:00:00.000Z",
    priority: "normal" as const,
  };
  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);

  assert.equal(envelope.status, "success");
  const output = envelope.output as {
    action: string;
    activation: {
      officialCarrier: string;
      composeStrategy: string;
      composeNotes?: string;
    };
    preparedInvocation: { adapterId?: string; key: string };
  };
  assert.equal(output.action, "skill.use");
  assert.equal(output.activation.officialCarrier, "openai-shell-environment");
  assert.equal(output.activation.composeStrategy, "payload-merge");
  assert.match(output.activation.composeNotes ?? "", /Responses generation requests/u);
  assert.equal(output.preparedInvocation.key, "skill.use");
  assert.equal("adapterId" in output.preparedInvocation, false);
});

test("rax skill adapter execute accepts reference-first skill.use input", async () => {
  const container = createContainer();
  const facade = {
    skill: {
      async use(): Promise<SkillUseResult> {
        return {
          container: {
            ...container,
            source: {
              kind: "virtual",
              rootDir: "virtual://skill/pptx",
              entryPath: "virtual://skill/pptx/SKILL.md",
            },
            descriptor: {
              ...container.descriptor,
              id: "pptx",
              name: "PowerPoint Skill",
            },
          },
          activation: createActivation("anthropic"),
          invocation: createInvocation("anthropic"),
        };
      },
      mount(): SkillMountResult {
        throw new Error("mount should not be called in this test");
      },
      prepare(): PreparedInvocation<Record<string, unknown>> {
        throw new Error("prepare should not be called in this test");
      },
    },
  };

  const adapter = createRaxSkillCapabilityAdapter(facade);
  const plan = {
    planId: "plan_ref_001",
    intentId: "intent_ref_001",
    sessionId: "session_ref_001",
    runId: "run_ref_001",
    capabilityKey: "skill.use",
    operation: "skill.use",
    input: {
      provider: "anthropic",
      model: "claude-opus-4-6-thinking",
      layer: "api",
      reference: {
        id: "pptx",
        version: "latest",
      },
      mode: "anthropic-api-managed",
      details: {
        type: "anthropic",
      },
    },
    priority: "normal" as const,
  };
  const lease = {
    leaseId: "lease_ref_001",
    capabilityId: "skill.use",
    bindingId: "binding_ref_001",
    generation: 1,
    grantedAt: "2026-03-18T00:00:00.000Z",
    priority: "normal" as const,
  };

  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  const output = envelope.output as {
    activation: {
      composeStrategy: string;
      composeNotes?: string;
    };
    container: {
      source: {
        kind: string;
      };
    };
  };
  assert.equal(output.container.source.kind, "virtual");
  assert.equal(output.activation.composeStrategy, "runtime-only");
  assert.match(output.activation.composeNotes ?? "", /SDK runtime path/u);
});

test("rax skill activation factory materializes a package-backed skill adapter", async () => {
  const container = createContainer();
  const facade = {
    skill: {
      async use(): Promise<SkillUseResult> {
        return {
          container,
          activation: createActivation("openai"),
          invocation: createInvocation("openai"),
        };
      },
      mount(): SkillMountResult {
        throw new Error("mount should not be called in this test");
      },
      prepare(): PreparedInvocation<Record<string, unknown>> {
        throw new Error("prepare should not be called in this test");
      },
    },
  };
  const capabilityPackage = createSkillCapabilityPackage("skill.use");
  const resolver = createActivationFactoryResolver();
  resolver.register(
    RAX_SKILL_ACTIVATION_FACTORY_REFS["skill.use"],
    createRaxSkillActivationFactory({ facade }),
  );

  const materialized = await materializeActivationRegistration({
    capabilityPackage,
    factoryResolver: resolver,
    capabilityIdPrefix: "capability",
  });
  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent_skill_pkg_001",
      sessionId: "session_skill_pkg_001",
      runId: "run_skill_pkg_001",
      capabilityKey: "skill.use",
      input: {
        provider: "openai",
        model: "gpt-5.4",
        source: "/skills/browser",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan_skill_pkg_001",
    },
  );
  const lease = createCapabilityLease(
    {
      capabilityId: materialized.manifest.capabilityId,
      bindingId: "binding_skill_pkg_001",
      generation: materialized.manifest.generation,
      plan,
    },
    {
      idFactory: () => "lease_skill_pkg_001",
      clock: {
        now: () => new Date("2026-03-25T00:00:00.000Z"),
      },
    },
  );

  const prepared = await materialized.adapter.prepare(plan, lease);
  const envelope = await materialized.adapter.execute(prepared);

  assert.equal(materialized.manifest.capabilityKey, "skill.use");
  assert.equal(materialized.targetPool, "ta-capability-pool");
  assert.equal(materialized.adapter.id, "rax.skill.adapter");
  assert.equal(envelope.status, "success");
  assert.equal((envelope.output as { action: string }).action, "skill.use");
});

test("register rax skill capability family wires requested manifests and activation factories", () => {
  const registeredManifests: string[] = [];
  const registeredFactories = new Map<string, ReturnType<typeof createRaxSkillActivationFactory>>();
  const registration = registerRaxSkillCapabilityFamily({
    runtime: {
      registerCapabilityAdapter(manifest, adapter) {
        registeredManifests.push(manifest.capabilityKey);
        return adapter.id;
      },
      registerTaActivationFactory(ref, factory) {
        registeredFactories.set(ref, factory);
      },
    },
    capabilityKeys: ["skill.use", "skill.prepare"],
  });

  assert.deepEqual(registration.capabilityKeys, ["skill.use", "skill.prepare"]);
  assert.deepEqual(
    registration.activationFactoryRefs,
    [
      RAX_SKILL_ACTIVATION_FACTORY_REFS["skill.use"],
      RAX_SKILL_ACTIVATION_FACTORY_REFS["skill.prepare"],
    ],
  );
  assert.deepEqual(
    registration.manifests.map((manifest) => manifest.capabilityKey),
    ["skill.use", "skill.prepare"],
  );
  assert.deepEqual(registeredManifests, ["skill.use", "skill.prepare"]);
  assert.equal(registeredFactories.size, 2);
  assert.deepEqual(registration.bindings, ["rax.skill.adapter", "rax.skill.adapter"]);
});
