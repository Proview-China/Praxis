import type {
  AgentObservedState,
  AgentState,
  AgentStateDelta,
  StateRecord,
  StateValue
} from "./state-types.js";
import { createInitialAgentState } from "./state-types.js";
import { assertValidAgentState, assertValidAgentStateDelta } from "./state-validator.js";

function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return false;
  }

  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function cloneStateValue(value: StateValue): StateValue {
  if (
    value === null ||
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  ) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((entry) => cloneStateValue(entry)) as StateValue;
  }

  const next: Record<string, StateValue> = {};
  for (const [key, nested] of Object.entries(value)) {
    next[key] = cloneStateValue(nested as StateValue);
  }
  return next;
}

function mergeStateRecord(
  base: StateRecord,
  patch?: StateRecord,
  clearKeys: readonly string[] = []
): StateRecord {
  const next: StateRecord = {};

  for (const [key, value] of Object.entries(base)) {
    if (!clearKeys.includes(key)) {
      next[key] = cloneStateValue(value);
    }
  }

  if (!patch) {
    return next;
  }

  for (const [key, value] of Object.entries(patch)) {
    const current = next[key];
    if (isPlainObject(current) && isPlainObject(value)) {
      next[key] = mergeStateRecord(
        current as StateRecord,
        value as StateRecord
      );
      continue;
    }

    next[key] = cloneStateValue(value as StateValue);
  }

  return next;
}

function mergeObservedState(
  base: AgentObservedState,
  patch?: Partial<AgentObservedState>
): AgentObservedState {
  if (!patch) {
    return {
      ...base,
      artifactRefs: [...base.artifactRefs]
    };
  }

  return {
    ...base,
    ...patch,
    artifactRefs: patch.artifactRefs
      ? [...patch.artifactRefs]
      : [...base.artifactRefs]
  };
}

export function applyStateDelta(
  base: AgentState,
  delta: AgentStateDelta
): AgentState {
  assertValidAgentState(base);
  assertValidAgentStateDelta(delta);

  const next: AgentState = {
    control: {
      ...base.control,
      ...(delta.control ?? {})
    },
    working: mergeStateRecord(
      base.working,
      delta.working,
      delta.clearWorkingKeys ?? []
    ),
    observed: mergeObservedState(base.observed, delta.observed),
    recovery: {
      ...base.recovery,
      ...(delta.recovery ?? {})
    }
  };

  const mergedDerived = mergeStateRecord(
    base.derived ?? {},
    delta.derived,
    delta.clearDerivedKeys ?? []
  );
  if (Object.keys(mergedDerived).length > 0) {
    next.derived = mergedDerived;
  }

  assertValidAgentState(next);
  return next;
}

export function applyStateDeltas(
  deltas: readonly AgentStateDelta[],
  initialState: AgentState = createInitialAgentState()
): AgentState {
  return deltas.reduce((state, delta) => applyStateDelta(state, delta), initialState);
}
