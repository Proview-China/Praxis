public struct PraxisStateKey: Sendable, Equatable, Hashable, Codable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisStateSnapshot: Sendable, Equatable, Codable {
  public let values: [PraxisStateKey: String]

  public init(values: [PraxisStateKey: String]) {
    self.values = values
  }
}

public struct PraxisStateDelta: Sendable, Equatable, Codable {
  public let changedKeys: [PraxisStateKey]

  public init(changedKeys: [PraxisStateKey]) {
    self.changedKeys = changedKeys
  }
}

public enum PraxisStateInvariantViolation: Sendable, Equatable, Codable {
  case missingValue(String)
  case invalidValue(String)
}
