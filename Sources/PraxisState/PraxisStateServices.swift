public protocol PraxisStateProjecting: Sendable {
  func project(from events: [String]) -> PraxisStateSnapshot
}

public protocol PraxisStateValidating: Sendable {
  func validate(_ snapshot: PraxisStateSnapshot) -> [PraxisStateInvariantViolation]
}

public struct PraxisDefaultStateProjector: Sendable {
  public init() {}
}

public struct PraxisDefaultStateValidator: Sendable {
  public init() {}
}
