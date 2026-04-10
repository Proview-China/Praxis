import PraxisCapabilityResults

public struct PraxisHostCapabilityRequest: Sendable, Equatable, Codable {
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

public struct PraxisHostCapabilityReceipt: Sendable, Equatable, Codable {
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

public struct PraxisProviderInferenceRequest: Sendable, Equatable, Codable {
  public let prompt: String
  public let preferredModel: String?

  public init(prompt: String, preferredModel: String? = nil) {
    self.prompt = prompt
    self.preferredModel = preferredModel
  }
}

public struct PraxisProviderInferenceResponse: Sendable, Equatable, Codable {
  public let output: PraxisNormalizedCapabilityOutput
  public let receipt: PraxisHostCapabilityReceipt

  public init(output: PraxisNormalizedCapabilityOutput, receipt: PraxisHostCapabilityReceipt) {
    self.output = output
    self.receipt = receipt
  }
}

public struct PraxisProviderEmbeddingRequest: Sendable, Equatable, Codable {
  public let content: String

  public init(content: String) {
    self.content = content
  }
}

public struct PraxisProviderEmbeddingResponse: Sendable, Equatable, Codable {
  public let vectorLength: Int

  public init(vectorLength: Int) {
    self.vectorLength = vectorLength
  }
}
