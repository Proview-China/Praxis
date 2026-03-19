import assert from "node:assert/strict";
import test from "node:test";

import type {
  CapabilityAdapter,
  CapabilityInvocationPlan,
  CapabilityLease,
  CapabilityResultEnvelope,
  PreparedCapabilityCall,
} from "../capability-types/index.js";
import { createDecisionToken } from "../ta-pool-types/index.js";
import { TA_ENFORCEMENT_METADATA_KEY } from "../ta-pool-runtime/enforcement-guard.js";
import { DefaultCapabilityPool } from "./pool-dispatch.js";

function createPlan(
  input: CapabilityInvocationPlan["priority"] | Partial<CapabilityInvocationPlan> = "normal",
): CapabilityInvocationPlan {
  const base: CapabilityInvocationPlan = {
    planId: "plan_001",
    intentId: "intent_001",
    sessionId: "session_001",
    runId: "run_001",
    capabilityKey: "search.ground",
    operation: "ground",
    input: {
      query: "life meaning",
    },
    priority: "normal",
  };

  if (typeof input === "string") {
    return {
      ...base,
      priority: input,
    };
  }

  return {
    ...base,
    ...input,
    input: {
      ...base.input,
      ...(input.input ?? {}),
    },
    metadata: {
      ...(base.metadata ?? {}),
      ...(input.metadata ?? {}),
    },
  };
}

function createAdapter(mode: PreparedCapabilityCall["executionMode"] = "direct"): CapabilityAdapter {
  return {
    id: `adapter.search.ground.${mode}`,
    runtimeKind: "tool",
    supports() {
      return true;
    },
    async prepare(plan: CapabilityInvocationPlan, lease: CapabilityLease): Promise<PreparedCapabilityCall> {
      return {
        preparedId: `${plan.planId}:prepared`,
        leaseId: lease.leaseId,
        capabilityKey: plan.capabilityKey,
        bindingId: lease.bindingId,
        generation: lease.generation,
        executionMode: mode,
        metadata: {
          idempotencyKey: plan.idempotencyKey,
          priority: plan.priority,
        },
      };
    },
    async execute(prepared: PreparedCapabilityCall): Promise<CapabilityResultEnvelope> {
      return {
        executionId: `${prepared.preparedId}:execution`,
        resultId: `${prepared.preparedId}:result`,
        status: "success",
        output: {
          text: "42",
        },
        completedAt: new Date().toISOString(),
      };
    },
  };
}

test("DefaultCapabilityPool acquire prepare and direct dispatch emits result", async () => {
  const pool = new DefaultCapabilityPool();
  pool.register({
    capabilityId: "cap_search_ground",
    capabilityKey: "search.ground",
    kind: "tool",
    version: "1.0.0",
    generation: 1,
    description: "Grounded search capability.",
  }, createAdapter());

  const resultPromise = new Promise<CapabilityResultEnvelope>((resolve) => {
    pool.onResult(resolve);
  });

  const plan = createPlan();
  const lease = await pool.acquire(plan);
  const prepared = await pool.prepare(lease, plan);
  const handle = await pool.dispatch(prepared);
  const result = await resultPromise;

  assert.equal(lease.capabilityId, "cap_search_ground");
  assert.equal(prepared.capabilityKey, "search.ground");
  assert.equal(handle.state, "running");
  assert.equal(result.status, "success");
});

test("DefaultCapabilityPool queued dispatch drains asynchronously", async () => {
  const pool = new DefaultCapabilityPool({
    maxInflight: 1,
  });
  pool.register({
    capabilityId: "cap_search_ground",
    capabilityKey: "search.ground",
    kind: "tool",
    version: "1.0.0",
    generation: 1,
    description: "Grounded search capability.",
  }, createAdapter("queued"));

  const resultPromise = new Promise<CapabilityResultEnvelope>((resolve) => {
    pool.onResult(resolve);
  });

  const plan = createPlan("high");
  const lease = await pool.acquire(plan);
  const prepared = await pool.prepare(lease, plan);
  const handle = await pool.dispatch(prepared);
  const result = await resultPromise;

  assert.equal(handle.state, "queued");
  assert.equal(result.status, "success");
});

test("DefaultCapabilityPool prepare rejects malformed T/A enforcement metadata", async () => {
  const pool = new DefaultCapabilityPool();
  pool.register({
    capabilityId: "cap_search_ground",
    capabilityKey: "search.ground",
    kind: "tool",
    version: "1.0.0",
    generation: 1,
    description: "Grounded search capability.",
  }, createAdapter());

  const plan = createPlan({
    metadata: {
      bridge: "ta-pool",
      [TA_ENFORCEMENT_METADATA_KEY]: {
        requestId: "different-request",
        executionRequestId: "another-exec-request",
        capabilityKey: "search.ground",
        grantId: "grant-1",
        grantTier: "B1",
        mode: "balanced",
        tokenRequired: false,
      },
    },
  });

  const lease = await pool.acquire(plan);
  await assert.rejects(() => pool.prepare(lease, plan), /does not match invocation plan/);
});

test("DefaultCapabilityPool dispatch rejects T/A prepared calls that lose the required DecisionToken", async () => {
  const pool = new DefaultCapabilityPool();
  pool.register({
    capabilityId: "cap_search_ground",
    capabilityKey: "search.ground",
    kind: "tool",
    version: "1.0.0",
    generation: 1,
    description: "Grounded search capability.",
  }, createAdapter());

  const decisionToken = createDecisionToken({
    requestId: "access-ta-1",
    decisionId: "decision-ta-1",
    compiledGrantId: "grant-ta-1",
    mode: "balanced",
    issuedAt: "2026-03-18T00:00:00.000Z",
    signatureOrIntegrityMarker: "tap-grant-compiler/v1:decision-ta-1:plan-ta-1",
  });
  const plan = createPlan({
    planId: "plan-ta-1",
    metadata: {
      bridge: "ta-pool",
      [TA_ENFORCEMENT_METADATA_KEY]: {
        requestId: "access-ta-1",
        executionRequestId: "plan-ta-1",
        capabilityKey: "search.ground",
        grantId: "grant-ta-1",
        grantTier: "B1",
        mode: "balanced",
        tokenRequired: true,
        decisionToken,
      },
    },
  });

  const lease = await pool.acquire(plan);
  const prepared = await pool.prepare(lease, plan);
  const tamperedPrepared: PreparedCapabilityCall = {
    ...prepared,
    metadata: {
      ...(prepared.metadata ?? {}),
      [TA_ENFORCEMENT_METADATA_KEY]: {
        ...((prepared.metadata?.[TA_ENFORCEMENT_METADATA_KEY] as Record<string, unknown>) ?? {}),
        decisionToken: undefined,
      },
    },
  };

  await assert.rejects(() => pool.dispatch(tamperedPrepared), /requires a compiled DecisionToken/);
});

test("DefaultCapabilityPool prepare rejects forged DecisionTokens that point at another compiled grant", async () => {
  const pool = new DefaultCapabilityPool();
  pool.register({
    capabilityId: "cap_search_ground",
    capabilityKey: "search.ground",
    kind: "tool",
    version: "1.0.0",
    generation: 1,
    description: "Grounded search capability.",
  }, createAdapter());

  const plan = createPlan({
    planId: "plan-ta-forged-1",
    metadata: {
      bridge: "ta-pool",
      [TA_ENFORCEMENT_METADATA_KEY]: {
        requestId: "access-ta-forged-1",
        executionRequestId: "plan-ta-forged-1",
        capabilityKey: "search.ground",
        grantId: "grant-ta-forged-expected",
        grantTier: "B1",
        mode: "balanced",
        tokenRequired: true,
        decisionToken: createDecisionToken({
          requestId: "access-ta-forged-1",
          decisionId: "decision-ta-forged-1",
          compiledGrantId: "grant-ta-forged-other",
          mode: "balanced",
          issuedAt: "2026-03-18T00:00:00.000Z",
          signatureOrIntegrityMarker: "tap-grant-compiler/v1:decision-ta-forged-1:plan-ta-forged-1",
        }),
      },
    },
  });

  const lease = await pool.acquire(plan);
  await assert.rejects(
    () => pool.prepare(lease, plan),
    /DecisionToken grant grant-ta-forged-other does not match enforcement grant grant-ta-forged-expected/i,
  );
});
