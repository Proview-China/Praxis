import assert from "node:assert/strict";
import test from "node:test";

import {
  RAX_WEBSEARCH_ACTIVATION_FACTORY_REF,
  createRaxWebsearchCapabilityPackage,
} from "../capability-package/index.js";
import { createCapabilityLease } from "../capability-invocation/capability-lease.js";
import { createCapabilityInvocationPlan } from "../capability-invocation/capability-plan.js";
import {
  createRaxWebsearchActivationFactory,
  createRaxWebsearchAdapter,
  registerRaxWebsearchActivationFactory,
  registerRaxWebsearchCapability,
  type RaxWebsearchAdapterOptions,
} from "./rax-websearch-adapter.js";
import {
  createActivationFactoryResolver,
  materializeActivationRegistration,
} from "../ta-pool-runtime/index.js";

test("rax websearch adapter supports search.ground and prepares direct calls", async () => {
  const facade = {
    websearch: {
      async create() {
        return {
          status: "success",
          provider: "openai",
          model: "gpt-5.4",
          layer: "api",
          capability: "search",
          action: "ground",
          output: {
            answer: "Praxis is a rebooted runtime.",
            citations: [],
            sources: [],
          },
          evidence: [{ source: "test" }],
        };
      },
    },
  } as RaxWebsearchAdapterOptions["facade"];

  const adapter = createRaxWebsearchAdapter({
    facade,
  });

  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent_001",
      sessionId: "session_001",
      runId: "run_001",
      capabilityKey: "search.ground",
      input: {
        provider: "openai",
        model: "gpt-5.4",
        query: "What is Praxis?",
      },
      priority: "high",
    },
    {
      idFactory: () => "plan_001",
    },
  );

  const lease = createCapabilityLease(
    {
      capabilityId: "cap_search_ground",
      bindingId: "binding_001",
      generation: 1,
      plan,
    },
    {
      idFactory: () => "lease_001",
      clock: {
        now: () => new Date("2026-03-18T00:00:00.000Z"),
      },
    },
  );

  assert.equal(adapter.supports(plan), true);

  const prepared = await adapter.prepare(plan, lease);
  assert.equal(prepared.bindingId, "binding_001");
  assert.equal(prepared.executionMode, "direct");
  assert.ok(prepared.preparedPayloadRef?.startsWith("rax-websearch:"));

  const envelope = await adapter.execute(prepared);
  assert.equal(envelope.status, "success");
  assert.equal(
    (envelope.output as { answer: string }).answer,
    "Praxis is a rebooted runtime.",
  );
  assert.equal(envelope.metadata?.provider, "openai");
});

test("rax websearch adapter returns failed envelope when prepared input is missing", async () => {
  const adapter = createRaxWebsearchAdapter();
  const envelope = await adapter.execute({
    preparedId: "prepared_missing",
    leaseId: "lease_001",
    capabilityKey: "search.ground",
    bindingId: "binding_001",
    generation: 1,
    executionMode: "direct",
  });

  assert.equal(envelope.status, "failed");
  assert.equal(envelope.error?.code, "rax_websearch_prepared_input_missing");
});

test("rax websearch adapter maps blocked status into unified envelope", async () => {
  const facade = {
    websearch: {
      async create() {
        return {
          status: "blocked",
          provider: "anthropic",
          model: "claude-opus-4-6-thinking",
          layer: "agent",
          capability: "search",
          action: "ground",
          error: {
            reason: "profile-blocked",
          },
        };
      },
    },
  } as RaxWebsearchAdapterOptions["facade"];

  const adapter = createRaxWebsearchAdapter({
    facade,
  });

  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent_002",
      sessionId: "session_002",
      runId: "run_002",
      capabilityKey: "search.ground",
      input: {
        provider: "anthropic",
        model: "claude-opus-4-6-thinking",
        query: "blocked test",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan_002",
    },
  );
  const lease = createCapabilityLease(
    {
      capabilityId: "cap_search_ground",
      bindingId: "binding_002",
      generation: 2,
      plan,
    },
    {
      idFactory: () => "lease_002",
      clock: {
        now: () => new Date("2026-03-18T00:00:00.000Z"),
      },
    },
  );

  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);

  assert.equal(envelope.status, "blocked");
  assert.equal(envelope.error?.code, "rax_search_ground_failed");
  assert.equal(envelope.metadata?.provider, "anthropic");
});

test("rax websearch activation factory materializes a package-backed adapter", async () => {
  const facade = {
    websearch: {
      async create() {
        return {
          status: "success",
          provider: "openai",
          model: "gpt-5.4",
          layer: "api",
          capability: "search",
          action: "ground",
          output: {
            answer: "package-backed-search-ok",
            citations: [],
            sources: [],
          },
        };
      },
    },
  } as RaxWebsearchAdapterOptions["facade"];

  const capabilityPackage = createRaxWebsearchCapabilityPackage();
  const resolver = createActivationFactoryResolver();
  resolver.register(
    RAX_WEBSEARCH_ACTIVATION_FACTORY_REF,
    createRaxWebsearchActivationFactory({ facade }),
  );

  const materialized = await materializeActivationRegistration({
    capabilityPackage,
    factoryResolver: resolver,
    capabilityIdPrefix: "capability",
  });

  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent_pkg_001",
      sessionId: "session_pkg_001",
      runId: "run_pkg_001",
      capabilityKey: "search.ground",
      input: {
        provider: "openai",
        model: "gpt-5.4",
        query: "package-backed grounded search",
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan_pkg_001",
    },
  );

  const lease = createCapabilityLease(
    {
      capabilityId: materialized.manifest.capabilityId,
      bindingId: "binding_pkg_001",
      generation: materialized.manifest.generation,
      plan,
    },
    {
      idFactory: () => "lease_pkg_001",
      clock: {
        now: () => new Date("2026-03-25T00:00:00.000Z"),
      },
    },
  );

  const prepared = await materialized.adapter.prepare(plan, lease);
  const envelope = await materialized.adapter.execute(prepared);

  assert.equal(materialized.manifest.capabilityKey, "search.ground");
  assert.equal(materialized.targetPool, "ta-capability-pool");
  assert.equal(materialized.adapter.id, "adapter:search.ground");
  assert.equal(envelope.status, "success");
  assert.equal(
    (envelope.output as { answer: string }).answer,
    "package-backed-search-ok",
  );
});

test("registerRaxWebsearchActivationFactory wires the search.ground factory ref onto a target", () => {
  const registrations = new Map<string, ReturnType<typeof createRaxWebsearchActivationFactory>>();

  const registration = registerRaxWebsearchActivationFactory({
    target: {
      registerTaActivationFactory(ref, factory) {
        registrations.set(ref, factory);
      },
    },
  });

  assert.equal(registration.activationFactoryRef, RAX_WEBSEARCH_ACTIVATION_FACTORY_REF);
  assert.equal(registration.capabilityPackage.manifest.capabilityKey, "search.ground");
  assert.equal(registrations.has(RAX_WEBSEARCH_ACTIVATION_FACTORY_REF), true);

  const adapter = registration.factory({
    manifest: {
      capabilityId: "capability:search.ground:1",
      capabilityKey: "search.ground",
      kind: "tool",
      version: "1.0.0",
      generation: 1,
      description: "Grounded web search",
      supportsPrepare: true,
    },
  });

  assert.equal(adapter.id, "adapter:search.ground");
});

test("registerRaxWebsearchCapability registers the package-backed adapter and activation entry together", () => {
  const registrations = new Map<string, ReturnType<typeof createRaxWebsearchActivationFactory>>();
  const manifestBindings: Array<{
    manifest: {
      capabilityId: string;
      capabilityKey: string;
      generation: number;
      version: string;
    };
    adapterId: string;
  }> = [];
  const facade = {
    websearch: {
      async create() {
        return {
          status: "success",
          provider: "openai",
          model: "gpt-5.4",
          layer: "api",
        };
      },
    },
  } as RaxWebsearchAdapterOptions["facade"];

  const registration = registerRaxWebsearchCapability({
    runtime: {
      registerCapabilityAdapter(manifest, adapter) {
        manifestBindings.push({
          manifest: {
            capabilityId: manifest.capabilityId,
            capabilityKey: manifest.capabilityKey,
            generation: manifest.generation,
            version: manifest.version,
          },
          adapterId: adapter.id,
        });

        return {
          bindingId: "binding:search.ground",
          capabilityId: manifest.capabilityId,
          state: "active",
        };
      },
      registerTaActivationFactory(ref, factory) {
        registrations.set(ref, factory);
      },
    },
    facade,
    capabilityPackage: createRaxWebsearchCapabilityPackage({
      generation: 3,
      version: "1.3.0",
    }),
  });

  assert.equal(registration.activationFactoryRef, RAX_WEBSEARCH_ACTIVATION_FACTORY_REF);
  assert.equal(registration.manifest.capabilityId, "capability:search.ground:3");
  assert.equal(registration.manifest.version, "1.3.0");
  assert.equal(registration.adapter.id, "adapter:search.ground");
  assert.deepEqual(manifestBindings, [
    {
      manifest: {
        capabilityId: "capability:search.ground:3",
        capabilityKey: "search.ground",
        generation: 3,
        version: "1.3.0",
      },
      adapterId: "adapter:search.ground",
    },
  ]);
  assert.deepEqual(registration.binding, {
    bindingId: "binding:search.ground",
    capabilityId: "capability:search.ground:3",
    state: "active",
  });
  assert.equal(registrations.has(RAX_WEBSEARCH_ACTIVATION_FACTORY_REF), true);
});
