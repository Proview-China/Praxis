import Foundation
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

public enum PraxisRuntimeGatewayModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRuntimeGateway",
    responsibility: "为 framework-first 调用面与导出层提供宿主无关的 bootstrap 与 runtime access 装配面。",
    legacyReferences: [
      "src/rax/runtime.ts",
      "src/rax/facade.ts",
      "src/agent_core/runtime.ts",
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
      boundary,
    ],
    entrypoints: PraxisHostNeutralRuntimeBoundary.gatewayEntrypoints,
    rules: PraxisHostNeutralRuntimeBoundary.gatewayBlueprintRules,
  )
}

public typealias PraxisRuntimeGatewayBlueprint = PraxisRuntimeBlueprint

/// Builds host-neutral runtime access surfaces for framework callers and exported libraries.
///
/// This factory owns only the neutral bootstrap path so framework callers and cross-language hosts
/// can reuse the same runtime interface and registry wiring.
public enum PraxisRuntimeGatewayFactory {
  private static let sharedLocalHostAdapters = PraxisHostAdapterRegistry.localDefaults()

  /// Builds a composition root for the neutral runtime gateway bootstrap.
  ///
  /// - Parameters:
  ///   - hostAdapters: Host adapters used to materialize the runtime dependency graph.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A composition root ready to build a dependency graph.
  public static func makeCompositionRoot() -> PraxisRuntimeCompositionRoot {
    makeCompositionRoot(hostAdapters: sharedLocalHostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  /// Builds a composition root using explicit host adapters and the default gateway blueprint.
  ///
  /// - Parameter hostAdapters: Host adapters used to materialize the runtime dependency graph.
  /// - Returns: A composition root ready to build a dependency graph.
  public static func makeCompositionRoot(
    hostAdapters: PraxisHostAdapterRegistry
  ) -> PraxisRuntimeCompositionRoot {
    makeCompositionRoot(hostAdapters: hostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  public static func makeCompositionRoot(
    hostAdapters: PraxisHostAdapterRegistry,
    blueprint: PraxisRuntimeBlueprint
  ) -> PraxisRuntimeCompositionRoot {
    PraxisRuntimeCompositionRoot(
      boundaries: blueprint.foundationModules
        + blueprint.functionalDomainModules
        + blueprint.hostContractModules
        + blueprint.runtimeModules,
      hostAdapters: hostAdapters
    )
  }

  /// Builds a runtime facade from the neutral gateway bootstrap.
  ///
  /// - Parameters:
  ///   - hostAdapters: Host adapters used to assemble runtime dependencies.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A runtime facade backed by the requested host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeFacade() throws -> PraxisRuntimeFacade {
    try makeRuntimeFacade(hostAdapters: sharedLocalHostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  /// Builds a runtime facade using local default host adapters rooted at the supplied directory.
  ///
  /// - Parameters:
  ///   - rootDirectory: Optional runtime root directory used to construct local default adapters.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A runtime facade backed by local default host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeFacade(
    rootDirectory: URL?,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimeGatewayModule.bootstrap
  ) throws -> PraxisRuntimeFacade {
    try makeRuntimeFacade(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory),
      blueprint: blueprint
    )
  }

  /// Builds a runtime facade using explicit host adapters and the default gateway blueprint.
  ///
  /// - Parameter hostAdapters: Host adapters used to assemble runtime dependencies.
  /// - Returns: A runtime facade backed by the requested host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeFacade(
    hostAdapters: PraxisHostAdapterRegistry
  ) throws -> PraxisRuntimeFacade {
    try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  public static func makeRuntimeFacade(
    hostAdapters: PraxisHostAdapterRegistry,
    blueprint: PraxisRuntimeBlueprint
  ) throws -> PraxisRuntimeFacade {
    let dependencies = try makeCompositionRoot(hostAdapters: hostAdapters, blueprint: blueprint).makeDependencyGraph()
    return PraxisRuntimeFacade(dependencies: dependencies)
  }

  /// Builds one portal-agnostic runtime interface session.
  ///
  /// - Parameters:
  ///   - hostAdapters: Host adapters used to assemble runtime dependencies.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A runtime interface session backed by the requested host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeInterface() throws -> PraxisRuntimeInterfaceSession {
    try makeRuntimeInterface(hostAdapters: sharedLocalHostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  /// Builds one runtime interface session using local default host adapters rooted at the supplied directory.
  ///
  /// - Parameters:
  ///   - rootDirectory: Optional runtime root directory used to construct local default adapters.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A runtime interface session backed by local default host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeInterface(
    rootDirectory: URL?,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimeGatewayModule.bootstrap
  ) throws -> PraxisRuntimeInterfaceSession {
    try makeRuntimeInterface(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory),
      blueprint: blueprint
    )
  }

  /// Builds one runtime interface session using explicit host adapters and the default gateway blueprint.
  ///
  /// - Parameter hostAdapters: Host adapters used to assemble runtime dependencies.
  /// - Returns: A runtime interface session backed by the requested host adapters.
  /// - Throws: Any dependency graph validation error raised by composition.
  public static func makeRuntimeInterface(
    hostAdapters: PraxisHostAdapterRegistry
  ) throws -> PraxisRuntimeInterfaceSession {
    try makeRuntimeInterface(hostAdapters: hostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  public static func makeRuntimeInterface(
    hostAdapters: PraxisHostAdapterRegistry,
    blueprint: PraxisRuntimeBlueprint
  ) throws -> PraxisRuntimeInterfaceSession {
    PraxisRuntimeInterfaceSession(
      runtimeFacade: try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: blueprint),
      blueprint: blueprint
    )
  }

  /// Builds a registry that can open independent portal-agnostic runtime sessions by opaque handle.
  ///
  /// - Parameters:
  ///   - hostAdapters: Host adapters used to assemble each session.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A registry that lazily materializes runtime interface sessions.
  public static func makeRuntimeInterfaceRegistry() -> PraxisRuntimeInterfaceRegistry {
    makeRuntimeInterfaceRegistry(hostAdapters: sharedLocalHostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  /// Builds a registry using local default host adapters rooted at the supplied directory.
  ///
  /// - Parameters:
  ///   - rootDirectory: Optional runtime root directory used to construct local default adapters.
  ///   - blueprint: Runtime topology metadata used by neutral snapshots.
  /// - Returns: A registry that lazily materializes runtime interface sessions.
  public static func makeRuntimeInterfaceRegistry(
    rootDirectory: URL?,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimeGatewayModule.bootstrap
  ) -> PraxisRuntimeInterfaceRegistry {
    makeRuntimeInterfaceRegistry(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory),
      blueprint: blueprint
    )
  }

  /// Builds a registry that opens independent runtime sessions using explicit host adapters and the default blueprint.
  ///
  /// - Parameter hostAdapters: Host adapters used to assemble each session.
  /// - Returns: A registry that lazily materializes runtime interface sessions.
  public static func makeRuntimeInterfaceRegistry(
    hostAdapters: PraxisHostAdapterRegistry
  ) -> PraxisRuntimeInterfaceRegistry {
    makeRuntimeInterfaceRegistry(hostAdapters: hostAdapters, blueprint: PraxisRuntimeGatewayModule.bootstrap)
  }

  public static func makeRuntimeInterfaceRegistry(
    hostAdapters: PraxisHostAdapterRegistry,
    blueprint: PraxisRuntimeBlueprint
  ) -> PraxisRuntimeInterfaceRegistry {
    PraxisRuntimeInterfaceRegistry { _ in
      try makeRuntimeInterface(hostAdapters: hostAdapters, blueprint: blueprint)
    }
  }
}
