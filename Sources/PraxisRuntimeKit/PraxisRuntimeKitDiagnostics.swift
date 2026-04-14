import PraxisCoreTypes

/// Stable RuntimeKit error categories for caller-facing diagnostics.
public enum PraxisRuntimeErrorCategory: String, Sendable, Equatable, Codable {
  case invalidInput
  case dependencyMissing
  case unsupportedOperation
  case invariantViolation
  case unknown
}

/// Caller-facing diagnostic summary for one thrown runtime error.
///
/// This type keeps RuntimeKit error reporting lightweight while attaching one high-signal
/// remediation hint that examples, smoke harnesses, and embedding apps can print directly.
public struct PraxisRuntimeErrorDiagnostic: Sendable, Equatable, Codable {
  public let category: PraxisRuntimeErrorCategory
  public let summary: String
  public let remediation: String
  public let isRetryable: Bool

  public init(
    category: PraxisRuntimeErrorCategory,
    summary: String,
    remediation: String,
    isRetryable: Bool
  ) {
    self.category = category
    self.summary = summary
    self.remediation = remediation
    self.isRetryable = isRetryable
  }
}

/// Maps thrown runtime errors into stable RuntimeKit diagnostics.
///
/// This helper deliberately stays small: it does not hide the original error, but it gives
/// caller-facing code one consistent place to ask for category and remediation text.
public enum PraxisRuntimeErrorDiagnostics {
  /// Builds a stable diagnostic for one thrown error.
  ///
  /// - Parameter error: Any error raised by RuntimeKit or lower runtime layers.
  /// - Returns: One caller-facing diagnostic with category and remediation text.
  public static func diagnose(_ error: Error) -> PraxisRuntimeErrorDiagnostic {
    switch error {
    case let PraxisError.invalidInput(message):
      return PraxisRuntimeErrorDiagnostic(
        category: .invalidInput,
        summary: message,
        remediation: "Check required fields, typed refs, and enum values before retrying the request.",
        isRetryable: false
      )
    case let PraxisError.dependencyMissing(message):
      return PraxisRuntimeErrorDiagnostic(
        category: .dependencyMissing,
        summary: message,
        remediation: "Wire the required host adapter or runtime facade surface before calling this RuntimeKit path again.",
        isRetryable: false
      )
    case let PraxisError.unsupportedOperation(message):
      return PraxisRuntimeErrorDiagnostic(
        category: .unsupportedOperation,
        summary: message,
        remediation: "Use a supported runtime profile or platform baseline for this capability, or guard the call before invoking it.",
        isRetryable: false
      )
    case let PraxisError.invariantViolation(message):
      return PraxisRuntimeErrorDiagnostic(
        category: .invariantViolation,
        summary: message,
        remediation: "Treat this as a runtime bug or corrupted local state; inspect the runtime root and local SQLite baseline before retrying.",
        isRetryable: false
      )
    default:
      return PraxisRuntimeErrorDiagnostic(
        category: .unknown,
        summary: String(describing: error),
        remediation: "Inspect the original error and surrounding host logs before retrying.",
        isRetryable: false
      )
    }
  }
}
