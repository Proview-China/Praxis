/// Describes a module boundary and its mapped responsibilities.
public struct PraxisBoundaryDescriptor: Sendable, Equatable, Identifiable, Codable {
  public let name: String
  public let responsibility: String
  public let legacyReferences: [String]

  /// Stable identity derived from the boundary name.
  public var id: String {
    name
  }

  /// Creates a boundary descriptor for architecture maps and guard tests.
  ///
  /// - Parameters:
  ///   - name: The logical module or target name.
  ///   - responsibility: A concise statement of the boundary's job.
  ///   - legacyReferences: Historical implementation lineage references. These may point to
  ///     removed source trees kept only for architecture provenance.
  public init(
    name: String,
    responsibility: String,
    legacyReferences: [String] = [],
  ) {
    self.name = name
    self.responsibility = responsibility
    self.legacyReferences = legacyReferences
  }
}

public extension PraxisBoundaryDescriptor {
  /// Human-readable label used in snapshots and diagnostics.
  var displayLabel: String {
    "\(name): \(responsibility)"
  }
}
