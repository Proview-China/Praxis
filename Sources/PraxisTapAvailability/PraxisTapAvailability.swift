import PraxisCapabilityCatalog
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 AvailabilityState、GateRule、FailureTaxonomy、AvailabilityReport 等模型。
// - 实现 capability 暴露、gating、故障降级和 family audit 规则。
// - 让 availability 成为独立子域，而不是散落在 governance/runtime 里的附属判断。
// - 文件可继续拆分：AvailabilityState.swift、GateRules.swift、FailureTaxonomy.swift、AvailabilityReport.swift。

public enum PraxisTapAvailabilityModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapAvailability",
    responsibility: "TAP family audit、gating、failure taxonomy 与 availability report。",
    tsModules: [
      "src/agent_core/tap-availability",
    ],
  )
}
