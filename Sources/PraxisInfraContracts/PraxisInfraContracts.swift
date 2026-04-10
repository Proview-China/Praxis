import PraxisCheckpoint
import PraxisCmpDelivery
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisJournal

// TODO(reboot-plan):
// - 实现 checkpoint、journal、projection、message bus、lineage store 的协议边界。
// - 补充持久化键、版本、读写一致性和批处理语义。
// - 保证 infra 只描述基础设施能力，不承接 CMP/TAP 业务规则。
// - 文件可继续拆分：CheckpointStore.swift、JournalStore.swift、ProjectionStore.swift、MessageBus.swift、LineageStore.swift。

public enum PraxisInfraContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisInfraContracts",
    responsibility: "checkpoint / projection store / message bus / infra adapter 协议族。",
    tsModules: [
      "src/agent_core/checkpoint",
      "src/agent_core/cmp-db",
      "src/agent_core/cmp-mq",
    ],
  )
}
