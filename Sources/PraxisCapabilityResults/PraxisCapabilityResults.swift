import PraxisCapabilityContracts
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 CapabilityResultEnvelope、NormalizedOutput、CapabilityFailure 等结果模型。
// - 实现 provider 原始回包到核心统一结果的映射规则。
// - 定义结果事件桥和错误分类，保证上层只看到归一化语义。
// - 文件可继续拆分：ResultEnvelope.swift、ResultNormalization.swift、ResultEvents.swift、ResultFailures.swift。

public enum PraxisCapabilityResultsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityResults",
    responsibility: "capability result envelope、normalized output 与 result-event bridge。",
    tsModules: [
      "src/agent_core/capability-result",
    ],
  )
}
