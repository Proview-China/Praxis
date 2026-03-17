import assert from "node:assert/strict";
import test from "node:test";

import { compileGoal } from "./goal-compiler.js";
import { buildGoalCompiledCacheKey } from "./goal-cache-key.js";
import { normalizeGoal } from "./goal-normalizer.js";
import { createGoalSource } from "./goal-source.js";

test("createGoalSource keeps the source layer small and normalized", () => {
  const source = createGoalSource({
    goalId: "goal-source-1",
    userInput: "  研究 agent runtime kernel  ",
    inputRefs: ["doc://outline"],
    constraints: [{ key: "mode", value: "design" }]
  });

  assert.equal(source.goalId, "goal-source-1");
  assert.equal(source.userInput, "研究 agent runtime kernel");
  assert.deepEqual(source.inputRefs, ["doc://outline"]);
  assert.deepEqual(source.constraints, [{ key: "mode", value: "design" }]);
});

test("normalizeGoal preserves success and failure criteria while merging constraints", () => {
  const source = createGoalSource({
    goalId: "goal-normalize-1",
    userInput: "Define the runtime kernel",
    constraints: [{ key: "scope", value: "raw-kernel" }],
    inputRefs: ["memory://current-context"]
  });

  const normalized = normalizeGoal(source, {
    successCriteria: [
      {
        id: "done",
        description: "Kernel outline is concrete",
        required: true
      }
    ],
    failureCriteria: [
      {
        id: "blocked",
        description: "Task is still vague",
        required: true
      }
    ],
    additionalConstraints: [{ key: "language", value: "typescript" }]
  });

  assert.equal(normalized.taskStatement, "Define the runtime kernel");
  assert.deepEqual(normalized.successCriteria, [
    {
      id: "done",
      description: "Kernel outline is concrete",
      required: true
    }
  ]);
  assert.deepEqual(normalized.failureCriteria, [
    {
      id: "blocked",
      description: "Task is still vague",
      required: true
    }
  ]);
  assert.deepEqual(normalized.constraints, [
    { key: "scope", value: "raw-kernel", description: undefined },
    { key: "language", value: "typescript", description: undefined }
  ]);
  assert.deepEqual(normalized.inputRefs, ["memory://current-context"]);
});

test("compileGoal injects constraints and context into the compiled instruction text", () => {
  const normalized = normalizeGoal(
    createGoalSource({
      goalId: "goal-compile-1",
      userInput: "Implement goal frame compiler",
      constraints: [{ key: "mode", value: "kernel-only" }]
    }),
    {
      successCriteria: [
        { id: "spec", description: "compiled frame is deterministic", required: true }
      ]
    }
  );

  const compiled = compileGoal(normalized, {
    staticInstructions: ["Stay within src/agent_core/goal/**"],
    capabilityHints: [{ key: "goal.compile", description: "compile source into instruction text" }],
    contextSummary: "Raw kernel only, no governance layer."
  });

  assert.match(compiled.instructionText, /Task/);
  assert.match(compiled.instructionText, /Implement goal frame compiler/);
  assert.match(compiled.instructionText, /mode=\"kernel-only\"/);
  assert.match(compiled.instructionText, /Stay within src\/agent_core\/goal\/\*\*/);
  assert.match(compiled.instructionText, /goal\.compile: compile source into instruction text/);
  assert.match(compiled.instructionText, /Raw kernel only, no governance layer\./);
});

test("buildGoalCompiledCacheKey is stable for semantically identical inputs", () => {
  const normalized = normalizeGoal(
    createGoalSource({
      goalId: "goal-cache-1",
      userInput: "Compile a goal",
      constraints: [{ key: "mode", value: "design" }]
    })
  );

  const keyA = buildGoalCompiledCacheKey(normalized, {
    staticInstructions: ["A", "B"],
    capabilityHints: [{ key: "goal.compile", description: "desc" }],
    metadata: { z: 2, a: 1 }
  });
  const keyB = buildGoalCompiledCacheKey(normalized, {
    staticInstructions: ["A", "B"],
    capabilityHints: [{ key: "goal.compile", description: "desc" }],
    metadata: { a: 1, z: 2 }
  });

  assert.equal(keyA, keyB);
});
