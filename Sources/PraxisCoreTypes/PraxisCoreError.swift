public enum PraxisError: Error, Sendable, Equatable {
  case invalidInput(String)
  case invariantViolation(String)
  case dependencyMissing(String)
  case unsupportedOperation(String)
}
