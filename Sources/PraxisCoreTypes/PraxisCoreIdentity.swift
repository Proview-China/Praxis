public protocol PraxisIdentifier: RawRepresentable, Hashable, Codable, Sendable where RawValue == String {}

public struct PraxisVersion: Sendable, Equatable, Codable {
  public let major: Int
  public let minor: Int
  public let patch: Int

  public init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }
}

public struct PraxisTraceTag: Sendable, Equatable, Hashable, Codable {
  public let name: String
  public let value: String

  public init(name: String, value: String) {
    self.name = name
    self.value = value
  }
}
