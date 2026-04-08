import assert from "node:assert/strict";
import test from "node:test";

import { createCapabilityLease } from "../capability-invocation/capability-lease.js";
import { createCapabilityInvocationPlan } from "../capability-invocation/capability-plan.js";
import {
  createTapVendorUserIoAdapter,
  registerTapVendorUserIoFamily,
} from "./tap-vendor-user-io-adapter.js";

test("tap vendor user-io adapter blocks with structured questions for request_user_input", async () => {
  const adapter = createTapVendorUserIoAdapter({
    capabilityKey: "request_user_input",
  });

  const plan = createCapabilityInvocationPlan(
    {
      intentId: "intent_user_input_001",
      sessionId: "session_user_input_001",
      runId: "run_user_input_001",
      capabilityKey: "request_user_input",
      input: {
        questions: [
          {
            id: "scope",
            header: "范围",
            question: "这次是只改后端还是前后端一起改？",
            options: [],
          },
        ],
      },
      priority: "normal",
    },
    {
      idFactory: () => "plan_user_input_001",
    },
  );

  const lease = createCapabilityLease(
    {
      capabilityId: "capability_user_input_001",
      bindingId: "binding_user_input_001",
      generation: 1,
      plan,
    },
    {
      idFactory: () => "lease_user_input_001",
      clock: {
        now: () => new Date("2026-04-08T00:00:00.000Z"),
      },
    },
  );

  const prepared = await adapter.prepare(plan, lease);
  const envelope = await adapter.execute(prepared);

  assert.equal(envelope.status, "blocked");
  assert.equal(envelope.metadata?.waitingHuman, true);
  assert.equal(envelope.error?.code, "tap_vendor_user_input_required");
});

test("registerTapVendorUserIoFamily registers the two user-io baseline capabilities", () => {
  const capabilityKeys: string[] = [];
  const activationFactoryRefs = new Set<string>();

  const registration = registerTapVendorUserIoFamily({
    runtime: {
      registerCapabilityAdapter(manifest, adapter) {
        capabilityKeys.push(manifest.capabilityKey);
        return {
          bindingId: `binding:${manifest.capabilityKey}`,
          adapterId: adapter.id,
        };
      },
      registerTaActivationFactory(ref) {
        activationFactoryRefs.add(ref);
      },
    },
  });

  assert.deepEqual(registration.capabilityKeys, [
    "request_user_input",
    "request_permissions",
  ]);
  assert.equal(registration.packages.length, 2);
  assert.equal(registration.bindings.length, 2);
  assert.equal(registration.activationFactoryRefs.length, activationFactoryRefs.size);
  assert.deepEqual(capabilityKeys, [
    "request_user_input",
    "request_permissions",
  ]);
});
