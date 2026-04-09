import PraxisCapabilityContracts
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 TAP 共用对象模型，包括 governance/review/provision/human-gate 的基础值类型。
// - 冻结 TAP 子域共享枚举、状态标签、审查级别和 availability 关联类型。
// - 保持这里只放共用语义，不塞 runtime 规则或宿主执行细节。
// - 文件可继续拆分：TapGovernanceTypes.swift、TapReviewTypes.swift、TapProvisionTypes.swift、TapAvailabilityTypes.swift。

public enum PraxisTapTypesModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapTypes",
    responsibility: "TAP review/provision/TMA/human-gate 共享类型。",
    tsModules: [
      "src/agent_core/ta-pool-types",
    ],
  )
}
