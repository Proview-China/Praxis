import PraxisCoreTypes

public struct PraxisCoreServiceFactory: Sendable {
  public init() {}
}

public final class PraxisHostAdapterFactory: Sendable {
  public init() {}

  public func makeScaffoldAdapters() -> PraxisHostAdapterRegistry {
    .scaffoldDefaults()
  }
}

public struct PraxisBootstrapValidator: Sendable {
  public init() {}

  public func validate(boundaries: [PraxisBoundaryDescriptor]) throws {
    guard !boundaries.isEmpty else {
      throw PraxisError.dependencyMissing("Runtime composition requires at least one boundary descriptor.")
    }

    var seen = Set<String>()
    for boundary in boundaries {
      guard seen.insert(boundary.name).inserted else {
        throw PraxisError.invariantViolation("Duplicate runtime boundary detected: \(boundary.name)")
      }
    }
  }
}
