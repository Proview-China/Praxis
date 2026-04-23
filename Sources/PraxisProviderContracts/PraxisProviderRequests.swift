import PraxisCapabilityResults
import PraxisCoreTypes

public enum PraxisHostCapabilityExecutionStatus: String, Sendable, Codable {
  case succeeded
  case failed
  case queued
}

public struct PraxisHostCapabilityRequest: Sendable, Equatable, Codable {
  public let capabilityKey: String
  public let payloadSummary: String
  public let traceID: String?
  public let metadata: [String: PraxisValue]

  public init(
    capabilityKey: String,
    payloadSummary: String,
    traceID: String? = nil,
    metadata: [String: PraxisValue] = [:]
  ) {
    self.capabilityKey = capabilityKey
    self.payloadSummary = payloadSummary
    self.traceID = traceID
    self.metadata = metadata
  }
}

public struct PraxisHostCapabilityReceipt: Sendable, Equatable, Codable {
  public let capabilityKey: String
  public let backend: String
  public let status: PraxisHostCapabilityExecutionStatus
  public let providerOperationID: String?
  public let completedAt: String?
  public let summary: String

  public init(
    capabilityKey: String,
    backend: String,
    status: PraxisHostCapabilityExecutionStatus,
    providerOperationID: String? = nil,
    completedAt: String? = nil,
    summary: String
  ) {
    self.capabilityKey = capabilityKey
    self.backend = backend
    self.status = status
    self.providerOperationID = providerOperationID
    self.completedAt = completedAt
    self.summary = summary
  }
}

public enum PraxisProviderConversationBackend: String, Sendable, Equatable, Codable {
  case openAI = "openai"
  case anthropic = "anthropic"
}

public enum PraxisProviderOpenAIProfile: String, Sendable, Equatable, Codable {
  case openAI = "openai"
  case newAPI = "new-api"
  case sub2api = "sub2api"
  case chatGPTCodexOAuth = "chatgpt-codex-oauth"
}

public struct PraxisProviderConversationProfile: Sendable, Equatable, Codable {
  public let backend: PraxisProviderConversationBackend
  public let openAIProfile: PraxisProviderOpenAIProfile?

  public init(
    backend: PraxisProviderConversationBackend,
    openAIProfile: PraxisProviderOpenAIProfile? = nil
  ) {
    self.backend = backend
    self.openAIProfile = openAIProfile
  }
}

public enum PraxisProviderMessageRole: String, Sendable, Equatable, Codable {
  case system
  case developer
  case user
  case assistant
  case tool
}

public enum PraxisProviderMessagePart: Sendable, Equatable, Codable {
  case text(String)
  case image(url: String)

  enum CodingKeys: String, CodingKey {
    case type
    case text
    case url
  }

  enum Kind: String, Codable {
    case text
    case image
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .type) {
    case .text:
      self = .text(try container.decode(String.self, forKey: .text))
    case .image:
      self = .image(url: try container.decode(String.self, forKey: .url))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .text(let text):
      try container.encode(Kind.text, forKey: .type)
      try container.encode(text, forKey: .text)
    case .image(let url):
      try container.encode(Kind.image, forKey: .type)
      try container.encode(url, forKey: .url)
    }
  }
}

public struct PraxisProviderMessage: Sendable, Equatable, Codable {
  public let role: PraxisProviderMessageRole
  public let parts: [PraxisProviderMessagePart]

  public init(
    role: PraxisProviderMessageRole,
    parts: [PraxisProviderMessagePart]
  ) {
    self.role = role
    self.parts = parts
  }
}

public extension PraxisProviderMessage {
  static func systemText(_ text: String) -> Self {
    Self(role: .system, parts: [.text(text)])
  }

  static func developerText(_ text: String) -> Self {
    Self(role: .developer, parts: [.text(text)])
  }

  static func userText(_ text: String) -> Self {
    Self(role: .user, parts: [.text(text)])
  }

  static func assistantText(_ text: String) -> Self {
    Self(role: .assistant, parts: [.text(text)])
  }

  var textParts: [String] {
    parts.compactMap { part in
      guard case .text(let text) = part else {
        return nil
      }
      return text
    }
  }
}

public indirect enum PraxisProviderToolSchema: Sendable, Equatable, Codable {
  case string
  case integer
  case number
  case boolean
  case array(items: PraxisProviderToolSchema)
  case object(
    properties: [String: PraxisProviderToolSchema] = [:],
    required: [String] = []
  )

  enum CodingKeys: String, CodingKey {
    case type
    case items
    case properties
    case required
  }

  enum Kind: String, Codable {
    case string
    case integer
    case number
    case boolean
    case array
    case object
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .type) {
    case .string:
      self = .string
    case .integer:
      self = .integer
    case .number:
      self = .number
    case .boolean:
      self = .boolean
    case .array:
      self = .array(items: try container.decode(PraxisProviderToolSchema.self, forKey: .items))
    case .object:
      self = .object(
        properties: try container.decodeIfPresent([String: PraxisProviderToolSchema].self, forKey: .properties) ?? [:],
        required: try container.decodeIfPresent([String].self, forKey: .required) ?? []
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .string:
      try container.encode(Kind.string, forKey: .type)
    case .integer:
      try container.encode(Kind.integer, forKey: .type)
    case .number:
      try container.encode(Kind.number, forKey: .type)
    case .boolean:
      try container.encode(Kind.boolean, forKey: .type)
    case .array(let items):
      try container.encode(Kind.array, forKey: .type)
      try container.encode(items, forKey: .items)
    case .object(let properties, let required):
      try container.encode(Kind.object, forKey: .type)
      try container.encode(properties, forKey: .properties)
      try container.encode(required, forKey: .required)
    }
  }
}

public enum PraxisProviderToolExecutionKind: String, Sendable, Equatable, Codable {
  case local
  case remote
}

public struct PraxisProviderToolDefinition: Sendable, Equatable, Codable {
  public let name: String
  public let description: String?
  public let executionKind: PraxisProviderToolExecutionKind
  public let transportID: String?
  public let inputSchema: PraxisProviderToolSchema
  public let outputSchema: PraxisProviderToolSchema?

  public init(
    name: String,
    description: String? = nil,
    executionKind: PraxisProviderToolExecutionKind,
    transportID: String? = nil,
    inputSchema: PraxisProviderToolSchema,
    outputSchema: PraxisProviderToolSchema? = nil
  ) {
    self.name = name
    self.description = description
    self.executionKind = executionKind
    self.transportID = transportID
    self.inputSchema = inputSchema
    self.outputSchema = outputSchema
  }

  public static func remote(
    name: String,
    transportID: String,
    inputSchema: PraxisProviderToolSchema,
    description: String? = nil,
    outputSchema: PraxisProviderToolSchema? = nil
  ) -> Self {
    Self(
      name: name,
      description: description,
      executionKind: .remote,
      transportID: transportID,
      inputSchema: inputSchema,
      outputSchema: outputSchema
    )
  }

  public static func local(
    name: String,
    inputSchema: PraxisProviderToolSchema,
    description: String? = nil,
    outputSchema: PraxisProviderToolSchema? = nil
  ) -> Self {
    Self(
      name: name,
      description: description,
      executionKind: .local,
      inputSchema: inputSchema,
      outputSchema: outputSchema
    )
  }
}

public struct PraxisProviderConversationToolCall: Sendable, Equatable, Codable {
  public let callID: String
  public let toolName: String
  public let input: PraxisValue

  public init(
    callID: String,
    toolName: String,
    input: PraxisValue
  ) {
    self.callID = callID
    self.toolName = toolName
    self.input = input
  }
}

public struct PraxisProviderConversationRequest: Sendable, Equatable, Codable {
  public let messages: [PraxisProviderMessage]
  public let preferredModel: String?
  public let temperature: Double?
  public let requiredCapabilities: [String]
  public let metadata: [String: PraxisValue]
  public let continuation: [String: String]
  public let toolDefinitions: [PraxisProviderToolDefinition]
  public let providerProfile: PraxisProviderConversationProfile?
  public let stream: Bool

  public init(
    messages: [PraxisProviderMessage],
    preferredModel: String? = nil,
    temperature: Double? = nil,
    requiredCapabilities: [String] = [],
    metadata: [String: PraxisValue] = [:],
    continuation: [String: String] = [:],
    toolDefinitions: [PraxisProviderToolDefinition] = [],
    providerProfile: PraxisProviderConversationProfile? = nil,
    stream: Bool = false
  ) {
    self.messages = messages
    self.preferredModel = preferredModel
    self.temperature = temperature
    self.requiredCapabilities = requiredCapabilities
    self.metadata = metadata
    self.continuation = continuation
    self.toolDefinitions = toolDefinitions
    self.providerProfile = providerProfile
    self.stream = stream
  }
}

public extension PraxisProviderConversationRequest {
  init(
    systemPrompt: String? = nil,
    prompt: String,
    contextSummary: String? = nil,
    preferredModel: String? = nil,
    temperature: Double? = nil,
    requiredCapabilities: [String] = [],
    metadata: [String: PraxisValue] = [:],
    toolDefinitions: [PraxisProviderToolDefinition] = [],
    providerProfile: PraxisProviderConversationProfile? = nil,
    stream: Bool = false
  ) {
    var messages: [PraxisProviderMessage] = []
    if let systemPrompt, !systemPrompt.isEmpty {
      messages.append(.systemText(systemPrompt))
    }
    if let contextSummary, !contextSummary.isEmpty {
      messages.append(.developerText(contextSummary))
    }
    messages.append(.userText(prompt))

    self.init(
      messages: messages,
      preferredModel: preferredModel,
      temperature: temperature,
      requiredCapabilities: requiredCapabilities,
      metadata: metadata,
      continuation: [:],
      toolDefinitions: toolDefinitions,
      providerProfile: providerProfile,
      stream: stream
    )
  }
}

public struct PraxisProviderConversationResponse: Sendable, Equatable, Codable {
  public let messages: [PraxisProviderMessage]
  public let toolCalls: [PraxisProviderConversationToolCall]
  public let structuredFields: [String: PraxisValue]
  public let receipt: PraxisHostCapabilityReceipt
  public let continuation: [String: String]

  public init(
    messages: [PraxisProviderMessage],
    toolCalls: [PraxisProviderConversationToolCall] = [],
    structuredFields: [String: PraxisValue] = [:],
    receipt: PraxisHostCapabilityReceipt,
    continuation: [String: String] = [:]
  ) {
    self.messages = messages
    self.toolCalls = toolCalls
    self.structuredFields = structuredFields
    self.receipt = receipt
    self.continuation = continuation
  }

  public init(
    output: PraxisNormalizedCapabilityOutput,
    receipt: PraxisHostCapabilityReceipt,
    continuation: [String: String] = [:]
  ) {
    self.init(
      messages: output.summary.isEmpty ? [] : [.assistantText(output.summary)],
      structuredFields: output.structuredFields,
      receipt: receipt,
      continuation: continuation
    )
  }

  public var outputText: String {
    messages
      .filter { $0.role == .assistant }
      .flatMap(\.textParts)
      .joined(separator: "\n")
  }

  public var output: PraxisNormalizedCapabilityOutput {
    PraxisNormalizedCapabilityOutput(
      summary: outputText,
      structuredFields: structuredFields
    )
  }
}

public struct PraxisProviderEmbeddingRequest: Sendable, Equatable, Codable {
  public let content: String
  public let preferredModel: String?
  public let metadata: [String: PraxisValue]

  public init(
    content: String,
    preferredModel: String? = nil,
    metadata: [String: PraxisValue] = [:]
  ) {
    self.content = content
    self.preferredModel = preferredModel
    self.metadata = metadata
  }
}

public struct PraxisProviderEmbeddingResponse: Sendable, Equatable, Codable {
  public let vectorLength: Int
  public let model: String?

  public init(vectorLength: Int, model: String? = nil) {
    self.vectorLength = vectorLength
    self.model = model
  }
}

public struct PraxisProviderFileUploadRequest: Sendable, Equatable, Codable {
  public let summary: String
  public let purpose: String?

  public init(summary: String, purpose: String? = nil) {
    self.summary = summary
    self.purpose = purpose
  }
}

public struct PraxisProviderFileUploadReceipt: Sendable, Equatable, Codable {
  public let fileID: String
  public let backend: String

  public init(fileID: String, backend: String) {
    self.fileID = fileID
    self.backend = backend
  }
}

public struct PraxisProviderBatchRequest: Sendable, Equatable, Codable {
  public let summary: String
  public let itemCount: Int

  public init(summary: String, itemCount: Int) {
    self.summary = summary
    self.itemCount = itemCount
  }
}

public struct PraxisProviderBatchReceipt: Sendable, Equatable, Codable {
  public let batchID: String
  public let backend: String

  public init(batchID: String, backend: String) {
    self.batchID = batchID
    self.backend = backend
  }
}

public struct PraxisProviderSkillActivationRequest: Sendable, Equatable, Codable {
  public let skillKey: String
  public let reason: String?

  public init(skillKey: String, reason: String? = nil) {
    self.skillKey = skillKey
    self.reason = reason
  }
}

public struct PraxisProviderSkillActivationReceipt: Sendable, Equatable, Codable {
  public let skillKey: String
  public let activated: Bool

  public init(skillKey: String, activated: Bool) {
    self.skillKey = skillKey
    self.activated = activated
  }
}

public struct PraxisProviderMCPToolCallRequest: Sendable, Equatable, Codable {
  public let toolName: String
  public let input: [String: PraxisValue]
  public let serverName: String?

  public init(
    toolName: String,
    input: [String: PraxisValue] = [:],
    serverName: String? = nil
  ) {
    self.toolName = toolName
    self.input = input
    self.serverName = serverName
  }

  public init(
    toolName: String,
    summary: String,
    serverName: String? = nil
  ) {
    self.init(
      toolName: toolName,
      input: ["summary": .string(summary)],
      serverName: serverName
    )
  }
}

public struct PraxisProviderMCPToolCallReceipt: Sendable, Equatable, Codable {
  public let toolName: String
  public let status: PraxisHostCapabilityExecutionStatus
  public let payload: [String: PraxisValue]
  public let summary: String

  public init(
    toolName: String,
    status: PraxisHostCapabilityExecutionStatus,
    payload: [String: PraxisValue] = [:],
    summary: String
  ) {
    self.toolName = toolName
    self.status = status
    self.payload = payload
    self.summary = summary
  }
}
