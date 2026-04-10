/// Describes a module boundary and its mapped responsibilities.
public struct PraxisBoundaryDescriptor: Sendable, Equatable, Identifiable, Codable {
  public let name: String
  public let responsibility: String
  public let tsModules: [String]

  /// Stable identity derived from the boundary name.
  public var id: String {
    name
  }

  /// Creates a boundary descriptor for architecture maps and guard tests.
  ///
  /// - Parameters:
  ///   - name: The logical module or target name.
  ///   - responsibility: A concise statement of the boundary's job.
  ///   - tsModules: Legacy or parallel TypeScript modules associated with this boundary.
  public init(
    name: String,
    responsibility: String,
    tsModules: [String] = [],
  ) {
    self.name = name
    self.responsibility = responsibility
    self.tsModules = tsModules
  }
}

public extension PraxisBoundaryDescriptor {
  /// Human-readable label used in snapshots and diagnostics.
  var displayLabel: String {
    "\(name): \(responsibility)"
  }
}
