public protocol PraxisGoalNormalizing: Sendable {
  func normalize(_ source: PraxisGoalSource) throws -> PraxisNormalizedGoal
}

public protocol PraxisGoalCompiling: Sendable {
  func compile(_ goal: PraxisNormalizedGoal) throws -> PraxisCompiledGoal
}

public struct PraxisDefaultGoalNormalizer: Sendable {
  public init() {}
}

public struct PraxisDefaultGoalCompiler: Sendable {
  public init() {}
}

public struct PraxisGoalValidationService: Sendable {
  public init() {}
}
