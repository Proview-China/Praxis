import PraxisCoreTypes
import PraxisSession

// TODO(reboot-plan):
// - Implement core models such as JournalEvent, JournalCursor, and AppendOnlyStream.
// - Implement event append, read windows, cursor advancement, and read-model input boundaries.
// - Keep journal focused on event-stream truth instead of session or run business decisions.
// - This file can later be split into JournalEvent.swift, JournalCursor.swift, JournalStream.swift, and JournalReadModelInput.swift.

/// Stable blueprint describing the `PraxisJournal` target responsibilities.
public struct PraxisJournalBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  /// Creates the journal blueprint.
  ///
  /// - Parameter responsibilities: Stable responsibility labels owned by the target.
  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

/// Module-level boundary metadata for `PraxisJournal`.
public enum PraxisJournalModule {
  /// Architecture boundary descriptor for the journal target.
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisJournal",
    responsibility: "append-only journal、cursor 与 flush 触发。",
    tsModules: [
      "src/agent_core/journal",
    ],
  )

  /// Stable responsibility blueprint for the journal target.
  public static let blueprint = PraxisJournalBlueprint(
    responsibilities: [
      "append",
      "read",
      "cursor",
      "flush",
    ],
  )
}
