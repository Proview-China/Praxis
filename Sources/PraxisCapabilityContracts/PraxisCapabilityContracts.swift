import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 CapabilityManifest、InvocationContract、BindingSpec、CapabilityIdentity 等协议模型。
// - 定义 capability 请求、响应、生命周期状态与错误语义。
// - 冻结 Capability 子域最低层边界，避免 planning/results/catalog 反向污染 contracts。
// - 文件可继续拆分：CapabilityIdentity.swift、CapabilityManifest.swift、InvocationContract.swift、CapabilityErrors.swift。

public enum PraxisCapabilityContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityContracts",
    responsibility: "capability manifest、binding、invocation contract 与共享协议。",
    tsModules: [
      "src/agent_core/capability-types",
      "src/agent_core/capability-model",
    ],
  )
}
