import PraxisCoreTypes
import PraxisJournal
import PraxisSession

// TODO(reboot-plan):
// - 实现 CheckpointSnapshot、RecoveryEnvelope、CheckpointPointer 等模型。
// - 实现快照封装、恢复边界、序列化约束和版本兼容策略。
// - 保证 checkpoint 只负责恢复真相，不承担业务推理或治理决策。
// - 文件可继续拆分：CheckpointSnapshot.swift、RecoveryEnvelope.swift、CheckpointCodec.swift、CheckpointVersioning.swift。

public struct PraxisCheckpointBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

public enum PraxisCheckpointModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCheckpoint",
    responsibility: "checkpoint snapshot、恢复入口与 runtime 快照封装。",
    tsModules: [
      "src/agent_core/checkpoint",
    ],
  )

  public static let blueprint = PraxisCheckpointBlueprint(
    responsibilities: [
      "snapshot",
      "store",
      "recover",
      "merge_runtime_state",
    ],
  )
}
