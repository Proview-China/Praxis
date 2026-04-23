import AnthropicMessagesAPI
import AnthropicAgentRuntime
import Foundation
import OpenAIAgentRuntime
import OpenAIAuthentication
import OpenAIResponsesAPI
import PraxisCoreTypes
import PraxisProviderContracts

enum PraxisSDKConversationAdapters {
  static func makeOpenAIRequest(
    from request: PraxisProviderConversationRequest,
    defaultModel: String = "gpt-5.4"
  ) throws -> OpenAIResponseRequest {
    OpenAIResponseRequest(
      model: request.preferredModel ?? defaultModel,
      input: try request.messages.map(makeOpenAIInputItem),
      instructions: nil,
      previousResponseID: request.continuation["responseID"],
      store: nil,
      promptCacheKey: nil,
      stream: request.stream,
      tools: request.toolDefinitions.map(makeOpenAITool),
      toolChoice: request.toolDefinitions.isEmpty ? nil : .auto
    )
  }

  static func makeAnthropicRequest(
    from request: PraxisProviderConversationRequest,
    defaultModel: String = "claude-sonnet-4-20250514",
    defaultMaxTokens: Int = 1024
  ) throws -> AnthropicMessagesRequest {
    let systemSegments = request.messages
      .filter { $0.role == .system || $0.role == .developer }
      .flatMap(\.textParts)
    let system = systemSegments.isEmpty ? nil : systemSegments.joined(separator: "\n\n")

    let messages = try request.messages.compactMap { message -> AnthropicMessage? in
      switch message.role {
      case .system, .developer:
        return nil
      case .user:
        return AnthropicMessage(role: .user, content: try message.parts.map(makeAnthropicContentBlock))
      case .assistant:
        return AnthropicMessage(role: .assistant, content: try message.parts.map(makeAnthropicContentBlock))
      case .tool:
        return nil
      }
    }

    return AnthropicMessagesRequest(
      model: request.preferredModel ?? defaultModel,
      maxTokens: defaultMaxTokens,
      system: system,
      messages: messages,
      tools: request.toolDefinitions.map(makeAnthropicTool),
      stream: request.stream
    )
  }

  static func makeOpenAICompatibilityProfile(
    from profile: PraxisProviderConversationProfile?
  ) -> OpenAICompatibilityProfile {
    guard let profile else {
      return .openAI
    }

    switch profile.openAIProfile ?? .openAI {
    case .openAI:
      return .openAI
    case .newAPI:
      return .newAPI
    case .sub2api:
      return .sub2api
    case .chatGPTCodexOAuth:
      return .chatGPTCodexOAuth
    }
  }

  static func projectOpenAIResponse(
    _ response: OpenAIResponse,
    receipt: PraxisHostCapabilityReceipt
  ) throws -> PraxisProviderConversationResponse {
    var messages: [PraxisProviderMessage] = []
    var toolCalls: [PraxisProviderConversationToolCall] = []

    for item in response.output {
      switch item {
      case .message(let message):
        let parts = message.content.map { content -> PraxisProviderMessagePart in
          switch content {
          case .outputText(let text):
            return .text(text)
          case .refusal(let text):
            return .text(text)
          }
        }
        messages.append(.init(role: .assistant, parts: parts))

      case .functionCall(let functionCall):
        toolCalls.append(
          .init(
            callID: functionCall.callID,
            toolName: functionCall.name,
            input: try parseOpenAIArguments(functionCall.arguments)
          )
        )

      case .webSearchCall:
        continue
      }
    }

    return PraxisProviderConversationResponse(
      messages: messages,
      toolCalls: toolCalls,
      structuredFields: [:],
      receipt: receipt,
      continuation: ["responseID": response.id]
    )
  }

  static func projectAnthropicResponse(
    _ response: AnthropicMessageResponse,
    receipt: PraxisHostCapabilityReceipt
  ) -> PraxisProviderConversationResponse {
    let parts = response.content.compactMap { block -> PraxisProviderMessagePart? in
      switch block {
      case .text(let text):
        return .text(text)
      case .textWithCitations(let textBlock):
        return .text(textBlock.text)
      default:
        return nil
      }
    }

    let messages = parts.isEmpty ? [] : [PraxisProviderMessage(role: .assistant, parts: parts)]
    return PraxisProviderConversationResponse(
      messages: messages,
      structuredFields: [:],
      receipt: receipt,
      continuation: [:]
    )
  }

  static func projectOpenAIProjection(
    _ projection: OpenAIResponseProjection,
    receipt: PraxisHostCapabilityReceipt,
    continuation: [String: String] = [:]
  ) -> PraxisProviderConversationResponse {
    PraxisProviderConversationResponse(
      messages: projection.messages.map(makePraxisMessage),
      toolCalls: projection.toolCalls.map {
        PraxisProviderConversationToolCall(
          callID: $0.callID,
          toolName: $0.invocation.toolName,
          input: makePraxisValue(from: $0.invocation.input)
        )
      },
      structuredFields: [:],
      receipt: receipt,
      continuation: continuation
    )
  }

  static func projectAnthropicProjection(
    _ projection: AnthropicResponseProjection,
    receipt: PraxisHostCapabilityReceipt,
    continuation: [String: String] = [:]
  ) -> PraxisProviderConversationResponse {
    PraxisProviderConversationResponse(
      messages: projection.messages.map(makePraxisMessage),
      toolCalls: projection.toolCalls.map {
        PraxisProviderConversationToolCall(
          callID: $0.callID,
          toolName: $0.invocation.toolName,
          input: makePraxisValue(from: $0.invocation.input)
        )
      },
      structuredFields: [:],
      receipt: receipt,
      continuation: continuation
    )
  }
}

private extension PraxisSDKConversationAdapters {
  static func makePraxisMessage(
    from message: AgentMessage
  ) -> PraxisProviderMessage {
    PraxisProviderMessage(
      role: makePraxisRole(from: message.role),
      parts: message.parts.map(makePraxisMessagePart)
    )
  }

  static func makePraxisRole(
    from role: AgentMessageRole
  ) -> PraxisProviderMessageRole {
    switch role {
    case .system:
      return .system
    case .developer:
      return .developer
    case .user:
      return .user
    case .assistant:
      return .assistant
    case .tool:
      return .tool
    }
  }

  static func makePraxisMessagePart(
    from part: MessagePart
  ) -> PraxisProviderMessagePart {
    switch part {
    case .text(let text):
      return .text(text)
    case .image(let url):
      return .image(url: url.absoluteString)
    }
  }

  static func makePraxisValue(
    from value: ToolValue
  ) -> PraxisValue {
    switch value {
    case .string(let string):
      return .string(string)
    case .integer(let integer):
      return .number(Double(integer))
    case .number(let number):
      return .number(number)
    case .boolean(let boolean):
      return .bool(boolean)
    case .array(let array):
      return .array(array.map(makePraxisValue))
    case .object(let object):
      return .object(object.mapValues(makePraxisValue))
    case .null:
      return .null
    }
  }

  static func makeOpenAIInputItem(
    from message: PraxisProviderMessage
  ) throws -> OpenAIResponseInputItem {
    .message(
      OpenAIInputMessage(
        role: try makeOpenAIInputRole(from: message.role),
        content: try message.parts.map(makeOpenAIInputContent)
      )
    )
  }

  static func makeOpenAIInputRole(
    from role: PraxisProviderMessageRole
  ) throws -> OpenAIInputMessageRole {
    switch role {
    case .system:
      return .system
    case .developer:
      return .developer
    case .user:
      return .user
    case .assistant:
      return .assistant
    case .tool:
      throw PraxisError.unsupportedOperation("OpenAI request mapping does not project tool-role messages directly.")
    }
  }

  static func makeOpenAIInputContent(
    from part: PraxisProviderMessagePart
  ) throws -> OpenAIInputMessageContent {
    switch part {
    case .text(let text):
      return .inputText(text)
    case .image(let url):
      guard let resolvedURL = URL(string: url) else {
        throw PraxisError.invalidInput("OpenAI request mapping requires image URLs to be absolute.")
      }
      return .inputImage(resolvedURL)
    }
  }

  static func makeOpenAITool(
    from definition: PraxisProviderToolDefinition
  ) -> OpenAIResponseTool {
    OpenAIResponseTool(
      name: definition.name,
      description: definition.description,
      parameters: makeOpenAIToolSchema(from: definition.inputSchema)
    )
  }

  static func makeOpenAIToolSchema(
    from schema: PraxisProviderToolSchema
  ) -> OpenAIResponseToolSchema {
    switch schema {
    case .string:
      return .string
    case .integer:
      return .integer
    case .number:
      return .number
    case .boolean:
      return .boolean
    case .array(let items):
      return .array(items: makeOpenAIToolSchema(from: items))
    case .object(let properties, let required):
      return .object(
        properties: properties.mapValues(makeOpenAIToolSchema),
        required: required,
        additionalProperties: false
      )
    }
  }

  static func makeAnthropicContentBlock(
    from part: PraxisProviderMessagePart
  ) throws -> AnthropicContentBlock {
    switch part {
    case .text(let text):
      return .text(text)
    case .image:
      throw PraxisError.unsupportedOperation("Anthropic request mapping does not currently project image message parts.")
    }
  }

  static func makeAnthropicTool(
    from definition: PraxisProviderToolDefinition
  ) -> AnthropicTool {
    AnthropicTool(
      name: definition.name,
      description: definition.description,
      inputSchema: makeAnthropicToolSchema(from: definition.inputSchema)
    )
  }

  static func makeAnthropicToolSchema(
    from schema: PraxisProviderToolSchema
  ) -> AnthropicToolSchema {
    switch schema {
    case .string:
      return .string
    case .integer:
      return .integer
    case .number:
      return .number
    case .boolean:
      return .boolean
    case .array(let items):
      return .array(items: makeAnthropicToolSchema(from: items))
    case .object(let properties, let required):
      return .object(
        properties: properties.mapValues(makeAnthropicToolSchema),
        required: required
      )
    }
  }

  static func parseOpenAIArguments(
    _ arguments: String
  ) throws -> PraxisValue {
    guard let data = arguments.data(using: .utf8) else {
      throw PraxisError.invalidInput("OpenAI function-call arguments must be UTF-8 JSON.")
    }
    return try JSONDecoder().decode(PraxisValue.self, from: data)
  }
}
