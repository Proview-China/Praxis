import PraxisState

public protocol PraxisTransitionGuard: Sendable {
  func canTransition(snapshot: PraxisStateSnapshot) -> Bool
}

public struct PraxisTransitionEvaluator: Sendable {
  public init() {}
}
