import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 ProjectionPersistencePlan、PackagePersistencePlan、StorageTopology 等模型。
// - 实现 DB 写入/读取需要的纯 planner 与 schema 语义。
// - 保持这里是 DB model，不直接绑定 PostgreSQL/SQLite 客户端。
// - 文件可继续拆分：StorageTopology.swift、ProjectionPersistencePlan.swift、PackagePersistencePlan.swift、DeliveryPersistencePlan.swift。

public enum PraxisCmpDbModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpDbModel",
    responsibility: "CMP DB topology、projection/package/delivery persistence model 与 write plans。",
    tsModules: [
      "src/agent_core/cmp-db",
    ],
  )
}
