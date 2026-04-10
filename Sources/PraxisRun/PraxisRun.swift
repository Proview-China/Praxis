import PraxisCoreTypes
import PraxisState
import PraxisTransition

// TODO(reboot-plan):
// - Implement core runtime models such as RunAggregate, RunPhase, RunTick, and RunFailure.
// - Implement pure rules for run lifecycle, tick coordination, and resume/fail/complete transitions.
// - Keep run focused on describing a single execution without direct knowledge of persistence, providers, or UI.
// - This file can later be split into RunModels.swift, RunLifecycle.swift, RunCoordinator.swift, and RunRecovery.swift.

/// Stable blueprint describing the `PraxisRun` target responsibilities.
public struct PraxisRunBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  /// Creates the run blueprint.
  ///
  /// - Parameter responsibilities: Stable responsibility labels owned by the target.
  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

/// Module-level boundary metadata for `PraxisRun`.
public enum PraxisRunModule {
  /// Architecture boundary descriptor for the run target.
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisRun",
    responsibility: "run 生命周期、tick 协调、恢复接续。",
    tsModules: [
      "src/agent_core/run",
    ],
  )

  /// Stable responsibility blueprint for the run target.
  public static let blueprint = PraxisRunBlueprint(
    responsibilities: [
      "create",
      "tick",
      "pause",
      "resume",
      "complete",
      "fail",
    ],
  )
}
