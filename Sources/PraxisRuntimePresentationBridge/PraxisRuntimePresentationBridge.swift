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
import PraxisRuntimeComposition
import PraxisRuntimeFacades
import PraxisRuntimeUseCases
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
// - Implement presentation-facing DTOs, intents, and bridge mappers shared by CLI, SwiftUI, and FFI.
// - Ensure entry layers consume the runtime only through this target instead of touching composition, use case, or facade internals directly.
// - Provide stable bridge models for different hosts, such as command results, view state, and streaming events.
// - This file can later be split into PresentationModels.swift, CLICommandBridge.swift, ApplePresentationBridge.swift, and FFIBridge.swift.

public enum PraxisRuntimePresentationBridgeModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimePresentationBridge",
    responsibility: "把 runtime facade/use case 映射为 CLI / UI / FFI 可消费的展示桥。",
    tsModules: [
      "src/agent_core/live-agent-chat/shared.ts",
      "src/agent_core/live-agent-chat/ui.ts",
    ],
  )

  public static let bootstrap = PraxisRuntimeBlueprint(
    foundationModules: [
      PraxisCoreTypesModule.boundary,
      PraxisGoalModule.boundary,
      PraxisStateModule.boundary,
      PraxisTransitionModule.boundary,
      PraxisRunModule.boundary,
      PraxisSessionModule.boundary,
      PraxisJournalModule.boundary,
      PraxisCheckpointModule.boundary,
    ],
    functionalDomainModules: [
      PraxisCapabilityContractsModule.boundary,
      PraxisCapabilityPlanningModule.boundary,
      PraxisCapabilityResultsModule.boundary,
      PraxisCapabilityCatalogModule.boundary,
      PraxisTapTypesModule.boundary,
      PraxisTapGovernanceModule.boundary,
      PraxisTapReviewModule.boundary,
      PraxisTapProvisionModule.boundary,
      PraxisTapRuntimeModule.boundary,
      PraxisTapAvailabilityModule.boundary,
      PraxisCmpTypesModule.boundary,
      PraxisCmpSectionsModule.boundary,
      PraxisCmpProjectionModule.boundary,
      PraxisCmpDeliveryModule.boundary,
      PraxisCmpGitModelModule.boundary,
      PraxisCmpDbModelModule.boundary,
      PraxisCmpMqModelModule.boundary,
      PraxisCmpFiveAgentModule.boundary,
    ],
    hostContractModules: [
      PraxisProviderContractsModule.boundary,
      PraxisWorkspaceContractsModule.boundary,
      PraxisToolingContractsModule.boundary,
      PraxisInfraContractsModule.boundary,
      PraxisUserIOContractsModule.boundary,
    ],
    runtimeModules: [
      PraxisRuntimeCompositionModule.boundary,
      PraxisRuntimeUseCasesModule.boundary,
      PraxisRuntimeFacadesModule.boundary,
      boundary,
    ],
    entrypoints: [
      "PraxisCLI",
      "PraxisAppleUI",
      "PraxisFFI",
    ],
    rules: [
      "Core 是逻辑层，不是单一模块。",
      "HostContracts 必须按协议族继续拆分。",
      "HostRuntime 必须按 composition/use case/facade/presentation bridge 拆分。",
      "Entry 只能经由 RuntimePresentationBridge 进入系统。",
    ],
  )
}
