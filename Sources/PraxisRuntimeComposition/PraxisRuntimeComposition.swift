import PraxisCapabilityCatalog
import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCapabilityResults
import PraxisCheckpoint
import PraxisCmpDbModel
import PraxisCmpDelivery
import PraxisCmpFiveAgent
import PraxisCmpGitModel
import PraxisCmpMqModel
import PraxisCmpProjection
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisGoal
import PraxisInfraContracts
import PraxisJournal
import PraxisProviderContracts
import PraxisRun
import PraxisSession
import PraxisState
import PraxisTapAvailability
import PraxisTapGovernance
import PraxisTapProvision
import PraxisTapReview
import PraxisTapRuntime
import PraxisTapTypes
import PraxisToolingContracts
import PraxisTransition
import PraxisUserIOContracts
import PraxisWorkspaceContracts

// TODO(reboot-plan):
// - Implement the composition root, dependency graph, adapter registry, and bootstrap validation.
// - Define how Core subdomains compose with the five HostContracts families without pulling business rules back in.
// - Clarify which runtime dependencies are required, replaceable, or test doubles.
// - This file can later be split into CompositionRoot.swift, DependencyGraph.swift, AdapterRegistry.swift, and BootstrapValidation.swift.

public enum PraxisRuntimeCompositionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeComposition",
    responsibility: "composition root 与跨域装配边界。",
    tsModules: [
      "src/agent_core/runtime.ts",
      "src/rax/runtime.ts",
    ],
  )
}
