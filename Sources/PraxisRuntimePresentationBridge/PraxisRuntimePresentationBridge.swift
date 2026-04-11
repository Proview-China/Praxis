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
import PraxisMpFiveAgent
import PraxisMpMemory
import PraxisMpSearch
import PraxisMpTypes
import PraxisProviderContracts
import PraxisRun
import PraxisRuntimeComposition
import PraxisRuntimeFacades
import PraxisRuntimeGateway
import PraxisRuntimeInterface
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

// Boundary note:
// - This target maps host-neutral runtime outputs into presentation state and compatibility wrappers.
// - It must not redefine runtime contract truth or bypass RuntimeGateway / RuntimeInterface rules.
// - Native hosts should depend on the bridge surface instead of composition, use cases, or facades.

public enum PraxisRuntimePresentationBridgeModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimePresentationBridge",
    responsibility: "把 runtime facade/use case 映射为原生展示态与兼容包装，不承担 portal-agnostic runtime contract。",
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
      PraxisMpTypesModule.boundary,
      PraxisMpSearchModule.boundary,
      PraxisMpMemoryModule.boundary,
      PraxisMpFiveAgentModule.boundary,
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
      PraxisRuntimeInterfaceModule.boundary,
      PraxisRuntimeGatewayModule.boundary,
      boundary,
    ],
    entrypoints: PraxisHostNeutralRuntimeBoundary.presentationBridgeEntrypoints,
    rules: PraxisHostNeutralRuntimeBoundary.presentationBridgeBlueprintRules,
  )
}
