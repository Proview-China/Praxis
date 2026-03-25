import assert from "node:assert/strict";
import test from "node:test";

import { registerTapCapabilityFamilyAssembly } from "./tap-capability-family-assembly.js";

test("registerTapCapabilityFamilyAssembly wires foundation, search, skill, and MCP families together", () => {
  const registeredCapabilityKeys: string[] = [];
  const activationFactories = new Set<string>();

  const result = registerTapCapabilityFamilyAssembly({
    runtime: {
      registerCapabilityAdapter(manifest, adapter) {
        registeredCapabilityKeys.push(manifest.capabilityKey);
        return {
          bindingId: `binding:${manifest.capabilityKey}`,
          adapterId: adapter.id,
        };
      },
      registerTaActivationFactory(ref) {
        activationFactories.add(ref);
      },
    },
    foundation: {
      workspaceRoot: "/tmp/praxis",
    },
  });

  assert.deepEqual(result.familyKeys.foundation, [
    "code.read",
    "docs.read",
    "repo.write",
    "shell.restricted",
    "test.run",
    "skill.doc.generate",
  ]);
  assert.deepEqual(result.familyKeys.websearch, ["search.ground"]);
  assert.deepEqual(result.familyKeys.skill, [
    "skill.use",
    "skill.mount",
    "skill.prepare",
  ]);
  assert.deepEqual(result.familyKeys.mcp, [
    "mcp.listTools",
    "mcp.readResource",
    "mcp.call",
    "mcp.native.execute",
  ]);
  assert.equal(result.packages.length, 14);
  assert.equal(result.bindings.length, 10);
  assert.equal(result.activationFactoryRefs.length, activationFactories.size);
  assert.equal(registeredCapabilityKeys.includes("search.ground"), true);
  assert.equal(registeredCapabilityKeys.includes("skill.use"), true);
  assert.equal(registeredCapabilityKeys.includes("mcp.native.execute"), true);
});
