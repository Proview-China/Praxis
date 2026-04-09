import PraxisCapabilityContracts
import PraxisCoreTypes
import PraxisGoal
import PraxisRun

// TODO(reboot-plan):
// - 实现 capability selector、routing policy、invocation plan 和 lowering 规则。
// - 实现 lease、queue、dispatch、retry 等纯 planner 语义，不直接调用 executor。
// - 补足从 goal/run 到 capability plan 的映射与约束。
// - 文件可继续拆分：CapabilityPlanner.swift、CapabilityRouting.swift、CapabilityLease.swift、CapabilityDispatchLowering.swift。

public enum PraxisCapabilityPlanningModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityPlanning",
    responsibility: "capability invocation plan、lease、queue、dispatch 与 execution lowering。",
    tsModules: [
      "src/agent_core/capability-invocation",
      "src/agent_core/capability-gateway",
      "src/agent_core/capability-pool",
      "src/agent_core/port",
    ],
  )
}
