import PraxisGoal

public protocol PraxisCapabilitySelecting: Sendable {
  func select(for goal: PraxisCompiledGoal) -> PraxisCapabilitySelection?
}

public struct PraxisCapabilityPlanner: Sendable {
  public init() {}
}

public struct PraxisDefaultCapabilitySelector: Sendable {
  public init() {}
}
