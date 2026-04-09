import PraxisCheckpoint
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 ProjectionRecord、MaterializationPlan、VisibilityPolicy、ProjectionRecovery 等模型。
// - 实现 projection rebuild、runtime snapshot、visibility enforcement 和恢复规则。
// - 保持 projection 只表达“上下文怎样被投影”，不直接调用 store。
// - 文件可继续拆分：ProjectionRecord.swift、Materializer.swift、VisibilityPolicy.swift、ProjectionRecovery.swift。

public enum PraxisCmpProjectionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpProjection",
    responsibility: "CMP projection、materialization、visibility、runtime snapshot 与 recovery model。",
    tsModules: [
      "src/agent_core/cmp-runtime/materialization.ts",
      "src/agent_core/cmp-runtime/visibility-enforcement.ts",
      "src/agent_core/cmp-runtime/runtime-snapshot.ts",
      "src/agent_core/cmp-runtime/runtime-recovery.ts",
    ],
  )
}
