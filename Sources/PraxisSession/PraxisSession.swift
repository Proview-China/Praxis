import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement session models such as SessionHeader, SessionAttachment, and HotColdLifecycle.
// - Implement attachment relationships and lifecycle boundaries between session and run/checkpoint.
// - Keep session from sliding into journal or runtime-composition responsibilities.
// - This file can later be split into SessionModels.swift, SessionLifecycle.swift, SessionAttachment.swift, and SessionIndexes.swift.

/// Stable blueprint describing the `PraxisSession` target responsibilities.
public struct PraxisSessionBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  /// Creates the session blueprint.
  ///
  /// - Parameter responsibilities: Stable responsibility labels owned by the target.
  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

/// Module-level boundary metadata for `PraxisSession`.
public enum PraxisSessionModule {
  /// Architecture boundary descriptor for the session target.
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisSession",
    responsibility: "session header、冷热会话和 run 绑定。",
    tsModules: [
      "src/agent_core/session",
    ],
  )

  /// Stable responsibility blueprint for the session target.
  public static let blueprint = PraxisSessionBlueprint(
    responsibilities: [
      "header",
      "attach_run",
      "checkpoint_pointer",
      "hot_cold_storage",
    ],
  )
}
