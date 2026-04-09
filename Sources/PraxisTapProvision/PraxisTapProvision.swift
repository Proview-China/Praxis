import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 ProvisionRequest、ProvisionRegistry、AssetIndex、ProvisionPlan 等模型。
// - 实现 capability/tool 供应、依赖满足、资源选择与 provisioning planner 规则。
// - 保证 provision 只负责“该供应什么”，不直接落执行器。
// - 文件可继续拆分：ProvisionRequest.swift、ProvisionRegistry.swift、AssetIndex.swift、ProvisionPlanner.swift。

public enum PraxisTapProvisionModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapProvision",
    responsibility: "provision registry、asset index、planner 与 provisioning 计划模型。",
    tsModules: [
      "src/agent_core/ta-pool-provision",
    ],
  )
}
