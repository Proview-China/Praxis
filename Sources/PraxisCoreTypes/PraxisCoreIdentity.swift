/// Common protocol for string-backed identifiers shared across Praxis domains.
public protocol PraxisIdentifier: RawRepresentable, Hashable, Codable, Sendable where RawValue == String {}

/// Semantic version used for stable surface or artifact versioning.
public struct PraxisVersion: Sendable, Equatable, Codable {
  public let major: Int
  public let minor: Int
  public let patch: Int

  /// Creates a semantic version value.
  ///
  /// - Parameters:
  ///   - major: The breaking-change component.
  ///   - minor: The backward-compatible feature component.
  ///   - patch: The backward-compatible fix component.
  public init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }
}

/// Structured trace metadata attached to requests, goals, or runtime events.
public struct PraxisTraceTag: Sendable, Equatable, Hashable, Codable {
  public let name: String
  public let value: String

  /// Creates a trace tag.
  ///
  /// - Parameters:
  ///   - name: The tag key.
  ///   - value: The tag value.
  public init(name: String, value: String) {
    self.name = name
    self.value = value
  }
}
