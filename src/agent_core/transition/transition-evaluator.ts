import type { KernelEvent } from "../types/kernel-events.js";
import type { GoalFrameCompiled } from "../types/kernel-goal.js";
import type { AgentState } from "../types/kernel-state.js";
import type { StepTransitionDecision } from "../types/kernel-transition.js";
import { matchTransitionRule } from "./transition-table.js";
import { InvalidTransitionError } from "./transition-types.js";

export function evaluateTransition(
  currentState: AgentState,
  incomingEvent: KernelEvent,
  goalFrame: GoalFrameCompiled
): StepTransitionDecision {
  const rule = matchTransitionRule({
    currentState,
    incomingEvent,
    goalFrame
  });

  if (!rule) {
    throw new InvalidTransitionError({
      fromStatus: currentState.control.status,
      eventType: incomingEvent.type,
      message: `No transition rule matched event ${incomingEvent.type} from status ${currentState.control.status}.`
    });
  }

  return rule.decide({
    currentState,
    incomingEvent,
    goalFrame
  });
}
