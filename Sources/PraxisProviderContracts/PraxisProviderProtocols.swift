public protocol PraxisCapabilityExecutor: Sendable {
  func execute(_ request: PraxisHostCapabilityRequest) async throws -> PraxisHostCapabilityReceipt
}

public protocol PraxisProviderInferenceExecutor: Sendable {
  func infer(_ request: PraxisProviderInferenceRequest) async throws -> PraxisProviderInferenceResponse
}

public protocol PraxisProviderEmbeddingExecutor: Sendable {
  func embed(_ request: PraxisProviderEmbeddingRequest) async throws -> PraxisProviderEmbeddingResponse
}

public protocol PraxisProviderFileStore: Sendable {
  func upload(summary: String) async throws -> String
}

public protocol PraxisProviderBatchExecutor: Sendable {
  func enqueue(summary: String) async throws -> String
}

public protocol PraxisProviderSkillRegistry: Sendable {
  func listSkillKeys() async throws -> [String]
}

public protocol PraxisProviderSkillActivator: Sendable {
  func activate(skillKey: String) async throws
}

public protocol PraxisProviderMCPExecutor: Sendable {
  func callTool(summary: String) async throws -> String
}
