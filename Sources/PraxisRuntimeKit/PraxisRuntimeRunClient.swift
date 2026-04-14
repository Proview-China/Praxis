import Foundation
import PraxisGoal
import PraxisRuntimeFacades
import PraxisSession

/// Caller-friendly runtime execution entrypoint.
///
/// This surface keeps goal preparation details internal while exposing a minimal run/resume API to
/// Swift framework callers.
public struct PraxisRuntimeRunClient: Sendable {
  private let runFacade: PraxisRunFacade

  init(runFacade: PraxisRunFacade) {
    self.runFacade = runFacade
  }

  /// Normalizes, compiles, and runs one goal from a caller-friendly request model.
  ///
  /// - Parameter request: Structured execution request for one runtime goal.
  /// - Returns: A runtime run summary produced by the host-neutral runtime facade.
  /// - Throws: Any goal preparation or runtime execution error raised by the underlying services.
  public func run(_ request: PraxisRuntimeRunRequest) async throws -> PraxisRunSummary {
    let goalNormalizer = PraxisDefaultGoalNormalizer()
    let goalCompiler = PraxisDefaultGoalCompiler()
    let source = PraxisGoalSource(
      id: Self.makeGeneratedGoalID(),
      kind: .user,
      sessionID: request.sessionID?.rawValue,
      userInput: request.task
    )
    let normalizedGoal = try goalNormalizer.normalize(source, options: .init())
    let compiledGoal = try goalCompiler.compile(normalizedGoal, context: .init())

    return try await runFacade.runGoal(
      .init(
        goal: compiledGoal,
        sessionID: request.sessionID.map { PraxisSessionID(rawValue: $0.rawValue) }
      )
    )
  }

  /// Normalizes, compiles, and runs one goal from lightweight call-site parameters.
  ///
  /// - Parameters:
  ///   - task: Plain-text task description for one runtime goal.
  ///   - sessionID: Optional stable session identifier.
  /// - Returns: A runtime run summary produced by the host-neutral runtime facade.
  /// - Throws: Any goal preparation or runtime execution error raised by the underlying services.
  public func run(
    task: String,
    sessionID: PraxisRuntimeSessionRef? = nil
  ) async throws -> PraxisRunSummary {
    try await run(.init(task: task, sessionID: sessionID))
  }

  /// Resumes one existing run by identifier.
  ///
  /// - Parameter run: Stable run identifier to resume.
  /// - Returns: A runtime run summary produced by the host-neutral runtime facade.
  /// - Throws: Any runtime execution error raised by the underlying services.
  public func resumeRun(_ run: PraxisRuntimeRunRef) async throws -> PraxisRunSummary {
    try await runFacade.resumeRun(.init(runID: .init(rawValue: run.rawValue)))
  }

  /// Resumes one existing run through the shorter RuntimeKit convenience name.
  ///
  /// - Parameter run: Stable run identifier to resume.
  /// - Returns: A runtime run summary produced by the host-neutral runtime facade.
  /// - Throws: Any runtime execution error raised by the underlying services.
  public func resume(_ run: PraxisRuntimeRunRef) async throws -> PraxisRunSummary {
    try await resumeRun(run)
  }

  private static func makeGeneratedGoalID() -> PraxisGoalID {
    PraxisGoalID(rawValue: "goal.\(UUID().uuidString.lowercased())")
  }
}
