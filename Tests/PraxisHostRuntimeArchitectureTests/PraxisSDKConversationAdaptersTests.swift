import AnthropicMessagesAPI
import AnthropicAgentRuntime
import Foundation
import OpenAIAuthentication
import OpenAIResponsesAPI
import OpenAIAgentRuntime
import Testing
@testable import PraxisRuntimeComposition
import PraxisCoreTypes
import PraxisProviderContracts

struct PraxisSDKConversationAdaptersTests {
  @Test
  func openAIRequestMappingProjectsMessagesToolsAndContinuation() throws {
    let request = PraxisProviderConversationRequest(
      messages: [
        .systemText("Be concise"),
        .userText("Summarize the migration plan")
      ],
      preferredModel: "gpt-5.4",
      temperature: 0.2,
      continuation: ["responseID": "resp-123"],
      toolDefinitions: [
        .remote(
          name: "workspace.search",
          transportID: "provider-mcp",
          inputSchema: .object(
            properties: ["query": .string],
            required: ["query"]
          ),
          description: "Search the workspace."
        )
      ],
      providerProfile: .init(backend: .openAI, openAIProfile: .sub2api),
      stream: true
    )

    let mapped = try PraxisSDKConversationAdapters.makeOpenAIRequest(from: request)
    let compatibility = PraxisSDKConversationAdapters.makeOpenAICompatibilityProfile(
      from: request.providerProfile
    )

    #expect(mapped.model == "gpt-5.4")
    #expect(mapped.previousResponseID == "resp-123")
    #expect(mapped.stream == true)
    #expect(mapped.input.count == 2)
    #expect(mapped.tools?.count == 1)
    #expect(compatibility == .sub2api)
  }

  @Test
  func anthropicRequestMappingSeparatesSystemMessagesAndBuildsTools() throws {
    let request = PraxisProviderConversationRequest(
      messages: [
        .systemText("You are precise."),
        .developerText("Focus on implementation details."),
        .userText("Summarize the migration plan"),
        .assistantText("Prior summary")
      ],
      preferredModel: "claude-sonnet-test",
      toolDefinitions: [
        .local(
          name: "lookup_docs",
          inputSchema: .object(properties: ["topic": .string], required: ["topic"]),
          description: "Lookup docs."
        )
      ],
      stream: true
    )

    let mapped = try PraxisSDKConversationAdapters.makeAnthropicRequest(from: request, defaultMaxTokens: 512)

    #expect(mapped.model == "claude-sonnet-test")
    #expect(mapped.maxTokens == 512)
    #expect(mapped.system == "You are precise.\n\nFocus on implementation details.")
    #expect(mapped.messages.count == 2)
    #expect(mapped.tools?.count == 1)
    #expect(mapped.stream == true)
  }

  @Test
  func openAIConversationExecutorProjectsSdkResponseIntoPraxisConversation() async throws {
    let executor = PraxisOpenAIConversationExecutor(
      transport: StubOpenAIResponsesTransport(
        response: OpenAIResponse(
          id: "resp-openai-1",
          status: .completed,
          output: [
            .message(
              .init(
                id: "msg-1",
                role: .assistant,
                content: [.outputText("Mapped from OpenAI")]
              )
            ),
            .functionCall(
              .init(
                callID: "call-1",
                name: "workspace.search",
                arguments: #"{"query":"migration"}"#
              )
            ),
          ]
        )
      )
    )

    let response = try await executor.converse(
      .init(messages: [.userText("Summarize the migration")], preferredModel: "gpt-5.4")
    )

    #expect(response.receipt.backend == "openai")
    #expect(response.messages == [.assistantText("Mapped from OpenAI")])
    #expect(response.toolCalls.first?.toolName == "workspace.search")
    #expect(response.continuation["responseID"] == "resp-openai-1")
  }

  @Test
  func anthropicConversationExecutorProjectsSdkResponseIntoPraxisConversation() async throws {
    let executor = PraxisAnthropicConversationExecutor(
      transport: StubAnthropicMessagesTransport(
        response: AnthropicMessageResponse(
          id: "resp-anthropic-1",
          model: "claude-sonnet-test",
          role: .assistant,
          content: [.text("Mapped from Anthropic")],
          stopReason: .endTurn,
          stopSequence: nil,
          usage: .init(inputTokens: 8, outputTokens: 16)
        )
      )
    )

    let response = try await executor.converse(
      .init(messages: [.userText("Summarize the migration")], preferredModel: "claude-sonnet-test")
    )

    #expect(response.receipt.backend == "anthropic")
    #expect(response.messages == [.assistantText("Mapped from Anthropic")])
    #expect(response.toolCalls.isEmpty)
  }

  @Test
  func openAIConversationExecutorResolvesToolCallsThroughPraxisMCPExecutor() async throws {
    let transport = SequencedOpenAIResponsesTransport(
      responses: [
        OpenAIResponse(
          id: "resp-openai-tool-1",
          status: .completed,
          output: [
            .functionCall(
              .init(
                callID: "call-weather-1",
                name: "lookup_weather",
                arguments: #"{"city":"Paris"}"#,
                status: .completed
              )
            ),
          ]
        ),
        OpenAIResponse(
          id: "resp-openai-tool-2",
          status: .completed,
          output: [
            .message(
              .init(
                id: "msg-openai-tool-2",
                role: .assistant,
                content: [.outputText("Paris is sunny.")]
              )
            ),
          ]
        ),
      ]
    )
    let mcpExecutor = RecordingPraxisProviderMCPExecutor(
      toolName: "lookup_weather",
      payload: [
        "forecast": .string("sunny"),
      ]
    )
    let executor = PraxisOpenAIConversationExecutor(
      transport: transport,
      providerMCPExecutor: mcpExecutor
    )

    let response = try await executor.converse(
      PraxisProviderConversationRequest(
        messages: [PraxisProviderMessage.userText("What is the weather in Paris?")],
        preferredModel: "gpt-5.4",
        toolDefinitions: [
          PraxisProviderToolDefinition.remote(
            name: "lookup_weather",
            transportID: "weather-mcp",
            inputSchema: PraxisProviderToolSchema.object(
              properties: ["city": PraxisProviderToolSchema.string],
              required: ["city"]
            )
          ),
        ]
      )
    )

    #expect(response.receipt.backend == "openai")
    #expect(response.messages == [PraxisProviderMessage.assistantText("Paris is sunny.")])
    #expect(response.toolCalls.isEmpty)

    let mcpRequests = await mcpExecutor.recordedRequests
    #expect(mcpRequests.count == 1)
    #expect(mcpRequests[0].serverName == "weather-mcp")
    #expect(mcpRequests[0].input["city"] == PraxisValue.string("Paris"))

    let requests = await transport.recordedRequests
    #expect(requests.count == 2)
    #expect(requests[1].previousResponseID == "resp-openai-tool-1")
    let followUpPayload = try jsonObject(for: requests[1])
    let followUpInput = try #require(followUpPayload["input"] as? [[String: Any]])
    #expect(followUpInput.count == 1)
    #expect(followUpInput[0]["type"] as? String == "function_call_output")
    #expect(followUpInput[0]["call_id"] as? String == "call-weather-1")
    #expect(followUpInput[0]["output"] as? String == #"{"forecast":"sunny"}"#)
  }

  @Test
  func anthropicConversationExecutorResolvesToolCallsThroughPraxisMCPExecutor() async throws {
    let transport = SequencedAnthropicMessagesTransport(
      responses: [
        AnthropicMessageResponse(
          id: "resp-anthropic-tool-1",
          model: "claude-sonnet-test",
          role: .assistant,
          content: [
            .toolUse(
              .init(
                id: "toolu-weather-1",
                name: "lookup_weather",
                input: ["city": .string("Paris")]
              )
            ),
          ],
          stopReason: .toolUse,
          stopSequence: nil,
          usage: .init(inputTokens: 12, outputTokens: 8)
        ),
        AnthropicMessageResponse(
          id: "resp-anthropic-tool-2",
          model: "claude-sonnet-test",
          role: .assistant,
          content: [.text("Paris is sunny.")],
          stopReason: .endTurn,
          stopSequence: nil,
          usage: .init(inputTokens: 18, outputTokens: 7)
        ),
      ]
    )
    let mcpExecutor = RecordingPraxisProviderMCPExecutor(
      toolName: "lookup_weather",
      payload: [
        "forecast": .string("sunny"),
      ]
    )
    let executor = PraxisAnthropicConversationExecutor(
      transport: transport,
      providerMCPExecutor: mcpExecutor
    )

    let response = try await executor.converse(
      PraxisProviderConversationRequest(
        messages: [PraxisProviderMessage.userText("What is the weather in Paris?")],
        preferredModel: "claude-sonnet-test",
        toolDefinitions: [
          PraxisProviderToolDefinition.remote(
            name: "lookup_weather",
            transportID: "weather-mcp",
            inputSchema: PraxisProviderToolSchema.object(
              properties: ["city": PraxisProviderToolSchema.string],
              required: ["city"]
            )
          ),
        ]
      )
    )

    #expect(response.receipt.backend == "anthropic")
    #expect(response.messages == [PraxisProviderMessage.assistantText("Paris is sunny.")])
    #expect(response.toolCalls.isEmpty)

    let mcpRequests = await mcpExecutor.recordedRequests
    #expect(mcpRequests.count == 1)
    #expect(mcpRequests[0].serverName == "weather-mcp")
    #expect(mcpRequests[0].input["city"] == PraxisValue.string("Paris"))

    let requests = await transport.recordedRequests
    #expect(requests.count == 2)
    #expect(requests[1].messages.count == 3)
    #expect(requests[1].messages[1].content == [
      .toolUse(
        .init(
          id: "toolu-weather-1",
          name: "lookup_weather",
          input: ["city": .string("Paris")]
        )
      ),
    ])
    #expect(requests[1].messages[2].content == [
      .toolResult(
        .init(
          toolUseID: "toolu-weather-1",
          content: #"{"forecast":"sunny"}"#,
          isError: false
        )
      ),
    ])
  }

  @Test
  func conversationRouterPrefersExplicitBackendThenModelHintThenFallback() async throws {
    let openAI = StubConversationExecutor(backend: "openai-sdk")
    let anthropic = StubConversationExecutor(backend: "anthropic-sdk")
    let fallback = StubConversationExecutor(backend: "local-fallback")
    let router = PraxisSDKConversationRouter(
      openAIExecutor: openAI,
      anthropicExecutor: anthropic,
      fallbackExecutor: fallback
    )

    let anthropicResponse = try await router.converse(
      .init(
        messages: [.userText("Summarize the migration")],
        preferredModel: "gpt-5.4",
        providerProfile: .init(backend: .anthropic)
      )
    )
    #expect(anthropicResponse.receipt.backend == "anthropic-sdk")

    let modelHintResponse = try await router.converse(
      .init(
        messages: [.userText("Summarize the migration")],
        preferredModel: "claude-sonnet-4-20250514"
      )
    )
    #expect(modelHintResponse.receipt.backend == "anthropic-sdk")

    let defaultResponse = try await router.converse(
      .init(messages: [.userText("Summarize the migration")])
    )
    #expect(defaultResponse.receipt.backend == "openai-sdk")

    let fallbackRouter = PraxisSDKConversationRouter(fallbackExecutor: fallback)
    let fallbackResponse = try await fallbackRouter.converse(
      .init(messages: [.userText("Summarize the migration")])
    )
    #expect(fallbackResponse.receipt.backend == "local-fallback")
  }
}

private struct StubOpenAIResponsesTransport: OpenAIResponsesTransport, Sendable {
  let response: OpenAIResponse

  func createResponse(_ request: OpenAIResponseRequest) async throws -> OpenAIResponse {
    response
  }
}

private struct StubAnthropicMessagesTransport: AnthropicMessagesTransport, Sendable {
  let response: AnthropicMessageResponse

  func createMessage(_ request: AnthropicMessagesRequest) async throws -> AnthropicMessageResponse {
    response
  }
}

private actor SequencedOpenAIResponsesTransport: OpenAIResponsesTransport {
  private var remainingResponses: [OpenAIResponse]
  private(set) var recordedRequests: [OpenAIResponseRequest] = []

  init(responses: [OpenAIResponse]) {
    self.remainingResponses = responses
  }

  func createResponse(_ request: OpenAIResponseRequest) async throws -> OpenAIResponse {
    recordedRequests.append(request)
    return remainingResponses.removeFirst()
  }
}

private actor SequencedAnthropicMessagesTransport: AnthropicMessagesTransport {
  private var remainingResponses: [AnthropicMessageResponse]
  private(set) var recordedRequests: [AnthropicMessagesRequest] = []

  init(responses: [AnthropicMessageResponse]) {
    self.remainingResponses = responses
  }

  func createMessage(_ request: AnthropicMessagesRequest) async throws -> AnthropicMessageResponse {
    recordedRequests.append(request)
    return remainingResponses.removeFirst()
  }
}

private actor RecordingPraxisProviderMCPExecutor: PraxisProviderMCPExecutor {
  private let toolName: String
  private let payload: [String: PraxisValue]
  private(set) var recordedRequests: [PraxisProviderMCPToolCallRequest] = []

  init(toolName: String, payload: [String: PraxisValue]) {
    self.toolName = toolName
    self.payload = payload
  }

  func callTool(_ request: PraxisProviderMCPToolCallRequest) async throws -> PraxisProviderMCPToolCallReceipt {
    recordedRequests.append(request)
    return PraxisProviderMCPToolCallReceipt(
      toolName: toolName,
      status: .succeeded,
      payload: payload,
      summary: "Tool executed."
    )
  }
}

private struct StubConversationExecutor: PraxisProviderConversationExecutor, Sendable {
  let backend: String

  func converse(_ request: PraxisProviderConversationRequest) async throws -> PraxisProviderConversationResponse {
    PraxisProviderConversationResponse(
      messages: [.assistantText("handled by \(backend)")],
      receipt: .init(
        capabilityKey: "provider.converse",
        backend: backend,
        status: .succeeded,
        summary: "Stub executor handled the conversation."
      )
    )
  }
}

private func jsonObject<T: Encodable>(for value: T) throws -> [String: Any] {
  let data = try JSONEncoder().encode(value)
  let object = try JSONSerialization.jsonObject(with: data)
  guard let dictionary = object as? [String: Any] else {
    throw DecodingError.typeMismatch(
      [String: Any].self,
      .init(codingPath: [], debugDescription: "Encoded payload is not a JSON object.")
    )
  }
  return dictionary
}
