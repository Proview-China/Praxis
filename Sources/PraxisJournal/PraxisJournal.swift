import PraxisCoreTypes
import PraxisSession

// TODO(reboot-plan):
// - 实现 JournalEvent、JournalCursor、AppendOnlyStream 等核心模型。
// - 实现事件追加、读取窗口、cursor 前进和读模型输入边界。
// - 保证 journal 只表达事件流真相，不承担 session/run 业务判断。
// - 文件可继续拆分：JournalEvent.swift、JournalCursor.swift、JournalStream.swift、JournalReadModelInput.swift。

public struct PraxisJournalBlueprint: Sendable, Equatable {
  public let responsibilities: [String]

  public init(responsibilities: [String]) {
    self.responsibilities = responsibilities
  }
}

public enum PraxisJournalModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisJournal",
    responsibility: "append-only journal、cursor 与 flush 触发。",
    tsModules: [
      "src/agent_core/journal",
    ],
  )

  public static let blueprint = PraxisJournalBlueprint(
    responsibilities: [
      "append",
      "read",
      "cursor",
      "flush",
    ],
  )
}
