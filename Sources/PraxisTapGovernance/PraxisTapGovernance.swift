import PraxisCapabilityContracts
import PraxisCoreTypes
import PraxisTapTypes

// TODO(reboot-plan):
// - 实现 TapGovernanceObject、RiskClassifier、ModePolicy、GovernanceSnapshot 等模型。
// - 实现风险分级、模式切换、权限边界和审计快照规则。
// - 把治理判断固定为纯规则，不直接调用 user I/O 或 tooling。
// - 文件可继续拆分：GovernanceObject.swift、RiskClassifier.swift、ModePolicy.swift、GovernanceSnapshot.swift。

public enum PraxisTapGovernanceModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapGovernance",
    responsibility: "风险分类、mode policy、governance object 与 user surface snapshot。",
    tsModules: [
      "src/agent_core/ta-pool-model",
      "src/agent_core/ta-pool-context",
    ],
  )
}
