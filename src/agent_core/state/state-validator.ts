import assert from "node:assert/strict";

import {
  FORBIDDEN_STATE_TOP_LEVEL_KEYS,
  type ForbiddenStateTopLevelKey,
  type AgentState,
  type AgentStateDelta,
  type StateRecord,
  type StateValue
} from "./state-types.js";

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function assertSerializableStateValue(
  value: unknown,
  path: string
): asserts value is StateValue {
  if (
    value === null ||
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  ) {
    return;
  }

  if (Array.isArray(value)) {
    value.forEach((entry, index) => {
      assertSerializableStateValue(entry, `${path}[${index}]`);
    });
    return;
  }

  if (isPlainObject(value)) {
    for (const [key, nested] of Object.entries(value)) {
      assertSerializableStateValue(nested, `${path}.${key}`);
    }
    return;
  }

  throw new TypeError(
    `State value at ${path} must be JSON-serializable plain data.`
  );
}

function assertNoForbiddenTopLevelKeys(
  record: StateRecord | undefined,
  section: string
): void {
  if (!record) {
    return;
  }

  for (const key of Object.keys(record)) {
    if (
      (FORBIDDEN_STATE_TOP_LEVEL_KEYS as readonly string[]).includes(key)
    ) {
      throw new TypeError(
        `State section ${section} may not contain top-level key ${key}.`
      );
    }
  }
}

export function assertValidStateRecord(
  record: StateRecord,
  section: string
): void {
  assertNoForbiddenTopLevelKeys(record, section);
  assertSerializableStateValue(record, section);
}

export function assertValidAgentState(state: AgentState): void {
  assert.ok(state.control, "AgentState.control is required.");
  assert.ok(state.working, "AgentState.working is required.");
  assert.ok(state.observed, "AgentState.observed is required.");
  assert.ok(state.recovery, "AgentState.recovery is required.");

  assert.equal(
    Array.isArray(state.observed.artifactRefs),
    true,
    "AgentState.observed.artifactRefs must be an array."
  );

  assertValidStateRecord(state.working, "working");

  if (state.derived) {
    assertValidStateRecord(state.derived, "derived");
  }
}

export function assertValidAgentStateDelta(delta: AgentStateDelta): void {
  if (delta.working) {
    assertValidStateRecord(delta.working, "delta.working");
  }

  if (delta.derived) {
    assertValidStateRecord(delta.derived, "delta.derived");
  }

  if (delta.clearWorkingKeys) {
    assert.equal(
      Array.isArray(delta.clearWorkingKeys),
      true,
      "clearWorkingKeys must be an array when provided."
    );
  }

  if (delta.clearDerivedKeys) {
    assert.equal(
      Array.isArray(delta.clearDerivedKeys),
      true,
      "clearDerivedKeys must be an array when provided."
    );
  }

  if (delta.observed?.artifactRefs) {
    assert.equal(
      Array.isArray(delta.observed.artifactRefs),
      true,
      "observed.artifactRefs must be an array when provided."
    );
  }
}

export function isForbiddenStateTopLevelKey(
  key: string
): key is ForbiddenStateTopLevelKey {
  return (FORBIDDEN_STATE_TOP_LEVEL_KEYS as readonly string[]).includes(key);
}
