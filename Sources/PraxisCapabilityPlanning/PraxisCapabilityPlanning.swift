import PraxisCapabilityContracts
import PraxisCoreTypes
import PraxisGoal
import PraxisRun

// TODO(reboot-plan):
// - Implement the capability selector, routing policy, invocation plan, and lowering rules.
// - Implement planner-only semantics for lease, queue, dispatch, and retry without calling executors directly.
// - Complete the mappings and constraints from goal/run to capability plans.
// - This file can later be split into CapabilityPlanner.swift, CapabilityRouting.swift, CapabilityLease.swift, and CapabilityDispatchLowering.swift.

public enum PraxisCapabilityPlanningModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityPlanning",
    responsibility: "capability invocation plan、lease、queue、dispatch 与 execution lowering。",
    tsModules: [
      "src/agent_core/capability-invocation",
      "src/agent_core/capability-gateway",
      "src/agent_core/capability-pool",
      "src/agent_core/port",
    ],
  )
}
