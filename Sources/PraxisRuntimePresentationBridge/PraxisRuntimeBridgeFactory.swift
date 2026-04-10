import PraxisRuntimeComposition
import PraxisRuntimeFacades
import PraxisRuntimeInterface

public enum PraxisRuntimeBridgeFactory {
  private static let sharedScaffoldHostAdapters = PraxisHostAdapterRegistry.scaffoldDefaults()

  static func makeCompositionRoot() -> PraxisRuntimeCompositionRoot {
    makeCompositionRoot(hostAdapters: sharedScaffoldHostAdapters, blueprint: PraxisRuntimePresentationBridgeModule.bootstrap)
  }

  static func makeCompositionRoot(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap
  ) -> PraxisRuntimeCompositionRoot {
    PraxisRuntimeCompositionRoot(
      boundaries: blueprint.foundationModules
        + blueprint.functionalDomainModules
        + blueprint.hostContractModules
        + blueprint.runtimeModules,
      hostAdapters: hostAdapters
    )
  }

  static func makeRuntimeFacade() throws -> PraxisRuntimeFacade {
    try makeRuntimeFacade(hostAdapters: sharedScaffoldHostAdapters, blueprint: PraxisRuntimePresentationBridgeModule.bootstrap)
  }

  static func makeRuntimeFacade(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap
  ) throws -> PraxisRuntimeFacade {
    let dependencies = try makeCompositionRoot(hostAdapters: hostAdapters, blueprint: blueprint).makeDependencyGraph()
    return PraxisRuntimeFacade(dependencies: dependencies)
  }

  public static func makeCLICommandBridge() throws -> PraxisCLICommandBridge {
    try makeCLICommandBridge(
      hostAdapters: sharedScaffoldHostAdapters,
      blueprint: PraxisRuntimePresentationBridgeModule.bootstrap,
      stateMapper: .init()
    )
  }

  static func makeCLICommandBridge(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap,
    stateMapper: PraxisPresentationStateMapper = .init()
  ) throws -> PraxisCLICommandBridge {
    PraxisCLICommandBridge(
      runtimeFacade: try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: blueprint),
      stateMapper: stateMapper
    )
  }

  @MainActor
  public static func makeApplePresentationBridge() throws -> PraxisApplePresentationBridge {
    try makeApplePresentationBridge(
      hostAdapters: sharedScaffoldHostAdapters,
      blueprint: PraxisRuntimePresentationBridgeModule.bootstrap,
      stateMapper: .init()
    )
  }

  @MainActor
  static func makeApplePresentationBridge(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap,
    stateMapper: PraxisPresentationStateMapper = .init()
  ) throws -> PraxisApplePresentationBridge {
    PraxisApplePresentationBridge(
      runtimeFacade: try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: blueprint),
      stateMapper: stateMapper
    )
  }

  public static func makeFFIBridge() throws -> PraxisFFIBridge {
    try makeFFIBridge(hostAdapters: sharedScaffoldHostAdapters, blueprint: PraxisRuntimePresentationBridgeModule.bootstrap)
  }

  public static func makeRuntimeInterface() throws -> PraxisRuntimeInterfaceSession {
    try makeRuntimeInterface(hostAdapters: sharedScaffoldHostAdapters, blueprint: PraxisRuntimePresentationBridgeModule.bootstrap)
  }

  static func makeRuntimeInterface(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap
  ) throws -> PraxisRuntimeInterfaceSession {
    PraxisRuntimeInterfaceSession(
      runtimeFacade: try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: blueprint),
      blueprint: blueprint
    )
  }

  static func makeFFIBridge(
    hostAdapters: PraxisHostAdapterRegistry = sharedScaffoldHostAdapters,
    blueprint: PraxisRuntimeBlueprint = PraxisRuntimePresentationBridgeModule.bootstrap
  ) throws -> PraxisFFIBridge {
    PraxisFFIBridge(runtimeFacade: try makeRuntimeFacade(hostAdapters: hostAdapters, blueprint: blueprint))
  }
}
