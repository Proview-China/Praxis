import PraxisCapabilityContracts
import PraxisCapabilityResults
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 provider request/receipt、inference、embedding、skill、MCP 相关协议模型。
// - 细化 capability executor 与 provider executor 的分层，避免语义混叠。
// - 统一 provider 原始能力到核心规范请求/结果的映射边界。
// - 文件可继续拆分：ProviderRequests.swift、ProviderReceipts.swift、InferenceProtocols.swift、SkillAndMCPProtocols.swift。

public enum PraxisProviderContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisProviderContracts",
    responsibility: "provider 推理与 capability 执行协议族。",
    tsModules: [
      "src/agent_core/integrations/model-inference.ts",
      "src/integrations",
      "src/rax/facade.ts",
    ],
  )
}
