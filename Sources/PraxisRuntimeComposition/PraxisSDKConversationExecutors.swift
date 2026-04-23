import AnthropicAgentRuntime
import AnthropicMessagesAPI
import OpenAIAgentRuntime
import OpenAIAuthentication
import OpenAIResponsesAPI
import PraxisProviderContracts

public struct PraxisOpenAIConversationExecutor: PraxisProviderConversationExecutor, Sendable {
  public let transport: any OpenAIResponsesTransport
  public let streamingTransport: (any OpenAIResponsesStreamingTransport)?
  public let defaultModel: String
  public let compatibilityProfile: OpenAICompatibilityProfile
  public let providerMCPExecutor: (any PraxisProviderMCPExecutor)?

  public init(
    transport: any OpenAIResponsesTransport,
    streamingTransport: (any OpenAIResponsesStreamingTransport)? = nil,
    defaultModel: String = "gpt-5.4",
    compatibilityProfile: OpenAICompatibilityProfile = .openAI,
    providerMCPExecutor: (any PraxisProviderMCPExecutor)? = nil
  ) {
    self.transport = transport
    self.streamingTransport = streamingTransport
    self.defaultModel = defaultModel
    self.compatibilityProfile = compatibilityProfile
    self.providerMCPExecutor = providerMCPExecutor
  }

  public func converse(_ request: PraxisProviderConversationRequest) async throws -> PraxisProviderConversationResponse {
    let resolvedCompatibility = request.providerProfile.map {
      PraxisSDKConversationAdapters.makeOpenAICompatibilityProfile(from: $0)
    } ?? compatibilityProfile
    let client = OpenAIResponsesClient(
      transport: transport,
      streamingTransport: streamingTransport,
      followUpStrategy: resolvedCompatibility.responsesFollowUpStrategy
    )
    let sdkRequest = try PraxisSDKConversationAdapters.makeOpenAIRequest(
      from: request,
      defaultModel: defaultModel
    )
    let baseReceipt = PraxisHostCapabilityReceipt(
      capabilityKey: "provider.converse",
      backend: "openai",
      status: .succeeded,
      providerOperationID: nil,
      summary: request.toolDefinitions.isEmpty
        ? "OpenAI conversation executor completed one SDK-backed response."
        : "OpenAI conversation executor completed one SDK-backed conversation with tool resolution."
    )

    if let toolExecutor = try await PraxisSDKConversationToolBridge.makeToolExecutor(
      toolDefinitions: request.toolDefinitions,
      providerMCPExecutor: providerMCPExecutor
    ) {
      let projection = try await client.resolveToolCalls(
        sdkRequest,
        using: toolExecutor
      )
      return PraxisSDKConversationAdapters.projectOpenAIProjection(
        projection,
        receipt: baseReceipt
      )
    }

    let response = try await client.createResponse(sdkRequest)
    return try PraxisSDKConversationAdapters.projectOpenAIResponse(
      response,
      receipt: PraxisHostCapabilityReceipt(
        capabilityKey: baseReceipt.capabilityKey,
        backend: baseReceipt.backend,
        status: baseReceipt.status,
        providerOperationID: response.id,
        summary: baseReceipt.summary
      )
    )
  }
}

public struct PraxisAnthropicConversationExecutor: PraxisProviderConversationExecutor, Sendable {
  public let transport: any AnthropicMessagesTransport
  public let streamingTransport: (any AnthropicMessagesStreamingTransport)?
  public let defaultModel: String
  public let defaultMaxTokens: Int
  public let providerMCPExecutor: (any PraxisProviderMCPExecutor)?

  public init(
    transport: any AnthropicMessagesTransport,
    streamingTransport: (any AnthropicMessagesStreamingTransport)? = nil,
    defaultModel: String = "claude-sonnet-4-20250514",
    defaultMaxTokens: Int = 1024,
    providerMCPExecutor: (any PraxisProviderMCPExecutor)? = nil
  ) {
    self.transport = transport
    self.streamingTransport = streamingTransport
    self.defaultModel = defaultModel
    self.defaultMaxTokens = defaultMaxTokens
    self.providerMCPExecutor = providerMCPExecutor
  }

  public func converse(_ request: PraxisProviderConversationRequest) async throws -> PraxisProviderConversationResponse {
    let client = AnthropicMessagesClient(
      transport: transport,
      streamingTransport: streamingTransport
    )
    let sdkRequest = try PraxisSDKConversationAdapters.makeAnthropicRequest(
      from: request,
      defaultModel: defaultModel,
      defaultMaxTokens: defaultMaxTokens
    )
    let baseReceipt = PraxisHostCapabilityReceipt(
      capabilityKey: "provider.converse",
      backend: "anthropic",
      status: .succeeded,
      providerOperationID: nil,
      summary: request.toolDefinitions.isEmpty
        ? "Anthropic conversation executor completed one SDK-backed response."
        : "Anthropic conversation executor completed one SDK-backed conversation with tool resolution."
    )

    if let toolExecutor = try await PraxisSDKConversationToolBridge.makeToolExecutor(
      toolDefinitions: request.toolDefinitions,
      providerMCPExecutor: providerMCPExecutor
    ) {
      let projection = try await client.resolveToolCalls(
        sdkRequest,
        using: toolExecutor
      )
      return PraxisSDKConversationAdapters.projectAnthropicProjection(
        projection,
        receipt: baseReceipt
      )
    }

    let response = try await client.createMessage(sdkRequest)
    return PraxisSDKConversationAdapters.projectAnthropicResponse(
      response,
      receipt: PraxisHostCapabilityReceipt(
        capabilityKey: baseReceipt.capabilityKey,
        backend: baseReceipt.backend,
        status: baseReceipt.status,
        providerOperationID: response.id,
        summary: baseReceipt.summary
      )
    )
  }
}
