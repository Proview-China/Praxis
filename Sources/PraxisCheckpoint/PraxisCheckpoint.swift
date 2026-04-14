import Foundation
import PraxisCoreTypes
import PraxisJournal
import PraxisSession

// TODO(reboot-plan):
// - Implement models such as CheckpointSnapshot, RecoveryEnvelope, and CheckpointPointer.
// - Implement snapshot packaging, recovery boundaries, serialization constraints, and version compatibility policies.
// - Keep checkpoint focused on recovery truth instead of business reasoning or governance decisions.
// - This file can later be split into CheckpointSnapshot.swift, RecoveryEnvelope.swift, CheckpointCodec.swift, and CheckpointVersioning.swift.

/// Stable blueprint describing the `PraxisCheckpoint` target responsibilities.
public struct PraxisCheckpointBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  /// Creates the checkpoint blueprint.
  ///
  /// - Parameter responsibilities: Stable responsibility labels owned by the target.
  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

/// Module-level boundary metadata for `PraxisCheckpoint`.
public enum PraxisCheckpointModule {
  /// Architecture boundary descriptor for the checkpoint target.
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCheckpoint",
    responsibility: "checkpoint snapshot、恢复入口与 runtime 快照封装。",
    legacyReferences: [
      "src/agent_core/checkpoint",
    ],
  )

  /// Stable responsibility blueprint for the checkpoint target.
  public static let blueprint = PraxisCheckpointBlueprint(
    responsibilities: [
      "snapshot",
      "store",
      "recover",
      "merge_runtime_state",
    ],
  )
}
