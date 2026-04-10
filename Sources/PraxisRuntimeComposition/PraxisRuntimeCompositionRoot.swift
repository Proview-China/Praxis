import PraxisCoreTypes

public struct PraxisRuntimeCompositionRoot: Sendable {
  public let boundaries: [PraxisBoundaryDescriptor]
  public let hostAdapters: PraxisHostAdapterRegistry
  public let bootstrapValidator: PraxisBootstrapValidator

  public init(
    boundaries: [PraxisBoundaryDescriptor],
    hostAdapters: PraxisHostAdapterRegistry = .scaffoldDefaults(),
    bootstrapValidator: PraxisBootstrapValidator = .init()
  ) {
    self.boundaries = boundaries
    self.hostAdapters = hostAdapters
    self.bootstrapValidator = bootstrapValidator
  }

  /// Validates the current composition input and materializes the dependency graph
  /// that HostRuntime use cases consume.
  ///
  /// - Returns: A dependency graph built from the current boundaries and host adapters.
  /// - Throws: `PraxisError` when boundary descriptors are missing or inconsistent.
  public func makeDependencyGraph() throws -> PraxisDependencyGraph {
    try bootstrapValidator.validate(boundaries: boundaries)
    return PraxisDependencyGraph(boundaries: boundaries, hostAdapters: hostAdapters)
  }
}
