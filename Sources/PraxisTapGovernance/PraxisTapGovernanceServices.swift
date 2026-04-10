import PraxisTapTypes

public protocol PraxisRiskClassifying: Sendable {
  func classify(summary: String) -> PraxisTapRiskLevel
}

public struct PraxisDefaultRiskClassifier: Sendable {
  public init() {}
}
