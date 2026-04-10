import PraxisCapabilityPlanning
import PraxisCmpDelivery
import PraxisCmpProjection
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisTapReview
import PraxisTapRuntime

// TODO(reboot-plan):
// - Implement the role models and interaction contracts for ICMA, iterator, checker, dbagent, and dispatcher.
// - Implement multi-agent handoff, responsibility boundaries, window constraints, and context allocation rules.
// - Keep this target focused on describing the five-agent protocol rather than runtime composition.
// - This file can later be split into FiveAgentRoles.swift, FiveAgentProtocol.swift, FiveAgentHandOff.swift, and FiveAgentPolicies.swift.

public enum PraxisCmpFiveAgentModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpFiveAgent",
    responsibility: "CMP five-agent role protocol 与 ICMA/iterator/checker/dbagent/dispatcher 纯职责模型。",
    tsModules: [
      "src/agent_core/cmp-five-agent",
    ],
  )
}
