import PraxisCapabilityContracts
import PraxisCapabilityResults
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 provider request/receipt、inference、embedding、skill、MCP 相关协议模型。
// - 细化 capability executor 与 provider executor 的分层，避免语义混叠。
// - 统一 provider 原始能力到核心规范请求/结果的映射边界。
// - 文件可继续拆分：ProviderRequests.swift、ProviderReceipts.swift、InferenceProtocols.swift、SkillAndMCPProtocols.swift。

public struct PraxisHostCapabilityRequest: Sendable, Equatable {
  public let capabilityKey: String
  public let payloadSummary: String

  public init(
    capabilityKey: String,
    payloadSummary: String,
  ) {
    self.capabilityKey = capabilityKey
    self.payloadSummary = payloadSummary
  }
}

public struct PraxisHostCapabilityReceipt: Sendable, Equatable {
  public let capabilityKey: String
  public let backend: String
  public let status: String

  public init(
    capabilityKey: String,
    backend: String,
    status: String,
  ) {
    self.capabilityKey = capabilityKey
    self.backend = backend
    self.status = status
  }
}

public protocol PraxisCapabilityExecutor: Sendable {
  func execute(_ request: PraxisHostCapabilityRequest) async throws -> PraxisHostCapabilityReceipt
}

public protocol PraxisProviderInferenceExecutor: Sendable {
  func infer(summary: String) async throws -> PraxisHostCapabilityReceipt
}

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
