import AnthropicMessagesAPI
import Foundation
import OpenAIAuthentication
import OpenAIResponsesAPI
import PraxisCoreTypes
import PraxisProviderContracts

enum PraxisSDKConversationToolBridge {
  static let providerMCPTransportID = "praxis-provider-mcp"

  static func makeToolExecutor(
    toolDefinitions: [PraxisProviderToolDefinition],
    providerMCPExecutor: (any PraxisProviderMCPExecutor)?
  ) async throws -> ToolExecutor? {
    guard !toolDefinitions.isEmpty, let providerMCPExecutor else {
      return nil
    }

    let registry = ToolRegistry()
    for definition in toolDefinitions {
      try await registry.register(makeToolDescriptor(from: definition))
    }

    let executor = ToolExecutor(registry: registry)
    await executor.register(
      PraxisSDKProviderMCPRemoteToolTransport(
        providerMCPExecutor: providerMCPExecutor,
        serverNameByToolName: toolDefinitions.reduce(into: [:]) { partialResult, definition in
          guard let transportID = definition.transportID, !transportID.isEmpty else {
            return
          }
          partialResult[definition.name] = transportID
        }
      )
    )
    return executor
  }

  static func makeToolDescriptor(
    from definition: PraxisProviderToolDefinition
  ) -> ToolDescriptor {
    ToolDescriptor.remote(
      name: definition.name,
      transport: providerMCPTransportID,
      inputSchema: makeToolInputSchema(from: definition.inputSchema),
      description: definition.description,
      outputSchema: definition.outputSchema.map(makeToolInputSchema)
    )
  }

  static func makeToolInputSchema(
    from schema: PraxisProviderToolSchema
  ) -> ToolInputSchema {
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
      return .array(items: makeToolInputSchema(from: items))
    case .object(let properties, let required):
      return .object(
        properties: properties.mapValues(makeToolInputSchema),
        required: required
      )
    }
  }

  static func makeToolValue(
    from value: PraxisValue
  ) -> ToolValue {
    switch value {
    case .string(let string):
      return .string(string)
    case .number(let number):
      if
        number.rounded(.towardZero) == number,
        number >= Double(Int.min),
        number <= Double(Int.max)
      {
        return .integer(Int(number))
      }
      return .number(number)
    case .bool(let bool):
      return .boolean(bool)
    case .object(let object):
      return .object(object.mapValues(makeToolValue))
    case .array(let array):
      return .array(array.map(makeToolValue))
    case .null:
      return .null
    }
  }

  static func makePraxisObject(
    from value: ToolValue
  ) -> [String: PraxisValue] {
    switch value {
    case .object(let object):
      return object.mapValues(makePraxisValue)
    case .null:
      return [:]
    default:
      return ["value": makePraxisValue(from: value)]
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
    case .object(let object):
      return .object(object.mapValues(makePraxisValue))
    case .array(let array):
      return .array(array.map(makePraxisValue))
    case .null:
      return .null
    }
  }
}

actor PraxisSDKProviderMCPRemoteToolTransport: RemoteToolTransport {
  let transportID = PraxisSDKConversationToolBridge.providerMCPTransportID

  private let providerMCPExecutor: any PraxisProviderMCPExecutor
  private let serverNameByToolName: [String: String]

  init(
    providerMCPExecutor: any PraxisProviderMCPExecutor,
    serverNameByToolName: [String: String] = [:]
  ) {
    self.providerMCPExecutor = providerMCPExecutor
    self.serverNameByToolName = serverNameByToolName
  }

  func invoke(_ invocation: ToolInvocation) async throws -> ToolResult {
    let receipt = try await providerMCPExecutor.callTool(
      PraxisProviderMCPToolCallRequest(
        toolName: invocation.toolName,
        input: PraxisSDKConversationToolBridge.makePraxisObject(from: invocation.input),
        serverName: serverNameByToolName[invocation.toolName]
      )
    )

    guard receipt.status == .succeeded else {
      throw PraxisError.unsupportedOperation(
        "Provider MCP tool \(invocation.toolName) failed: \(receipt.summary)"
      )
    }

    if receipt.payload.isEmpty, !receipt.summary.isEmpty {
      return ToolResult(
        payload: .object([
          "summary": .string(receipt.summary),
        ])
      )
    }

    return ToolResult(
      payload: .object(receipt.payload.mapValues(PraxisSDKConversationToolBridge.makeToolValue))
    )
  }
}

public struct PraxisSDKConversationRouter: PraxisProviderConversationExecutor, Sendable {
  public let openAIExecutor: (any PraxisProviderConversationExecutor)?
  public let anthropicExecutor: (any PraxisProviderConversationExecutor)?
  public let fallbackExecutor: any PraxisProviderConversationExecutor

  public init(
    openAIExecutor: (any PraxisProviderConversationExecutor)? = nil,
    anthropicExecutor: (any PraxisProviderConversationExecutor)? = nil,
    fallbackExecutor: any PraxisProviderConversationExecutor
  ) {
    self.openAIExecutor = openAIExecutor
    self.anthropicExecutor = anthropicExecutor
    self.fallbackExecutor = fallbackExecutor
  }

  public func converse(_ request: PraxisProviderConversationRequest) async throws -> PraxisProviderConversationResponse {
    let executor = try resolvedExecutor(for: request)
    return try await executor.converse(request)
  }
}

extension PraxisSDKConversationRouter {
  func resolvedExecutor(
    for request: PraxisProviderConversationRequest
  ) throws -> any PraxisProviderConversationExecutor {
    if let backend = request.providerProfile?.backend {
      switch backend {
      case .openAI:
        guard let openAIExecutor else {
          throw PraxisError.unsupportedOperation(
            "OpenAI conversation executor is not configured for the current host environment."
          )
        }
        return openAIExecutor
      case .anthropic:
        guard let anthropicExecutor else {
          throw PraxisError.unsupportedOperation(
            "Anthropic conversation executor is not configured for the current host environment."
          )
        }
        return anthropicExecutor
      }
    }

    if let modelHint = request.preferredModel?.lowercased() {
      if modelHint.contains("claude"), let anthropicExecutor {
        return anthropicExecutor
      }
      if isLikelyOpenAIModel(modelHint), let openAIExecutor {
        return openAIExecutor
      }
    }

    switch (openAIExecutor, anthropicExecutor) {
    case let (.some(openAIExecutor), nil):
      return openAIExecutor
    case let (nil, .some(anthropicExecutor)):
      return anthropicExecutor
    case let (.some(openAIExecutor), .some):
      return openAIExecutor
    case (nil, nil):
      return fallbackExecutor
    }
  }

  func isLikelyOpenAIModel(_ model: String) -> Bool {
    model.hasPrefix("gpt") ||
    model.hasPrefix("o1") ||
    model.hasPrefix("o3") ||
    model.hasPrefix("o4") ||
    model.contains("codex")
  }
}

enum PraxisSDKConversationEnvironment {
  static func makeConversationExecutor(
    environment: [String: String],
    fallback: any PraxisProviderConversationExecutor,
    providerMCPExecutor: (any PraxisProviderMCPExecutor)?
  ) -> any PraxisProviderConversationExecutor {
    let openAIExecutor = makeOpenAIExecutor(
      environment: environment,
      providerMCPExecutor: providerMCPExecutor
    )
    let anthropicExecutor = makeAnthropicExecutor(
      environment: environment,
      providerMCPExecutor: providerMCPExecutor
    )

    guard openAIExecutor != nil || anthropicExecutor != nil else {
      return fallback
    }

    return PraxisSDKConversationRouter(
      openAIExecutor: openAIExecutor,
      anthropicExecutor: anthropicExecutor,
      fallbackExecutor: fallback
    )
  }
}

private extension PraxisSDKConversationEnvironment {
  static func makeOpenAIExecutor(
    environment: [String: String],
    providerMCPExecutor: (any PraxisProviderMCPExecutor)?
  ) -> PraxisOpenAIConversationExecutor? {
    let baseURL = url(
      environment["OPENAI_BASE_URL"],
      default: nonEmpty(environment["OPENAI_ACCESS_TOKEN"]) == nil
        ? "https://api.openai.com/v1"
        : "https://chatgpt.com/backend-api/codex"
    )
    let compatibilityProfile = openAICompatibilityProfile(
      rawValue: environment["OPENAI_COMPAT_PROFILE"],
      baseURL: baseURL
    )
    let model = nonEmpty(environment["OPENAI_MODEL"]) ?? "gpt-5.4"

    if let accessToken = nonEmpty(environment["OPENAI_ACCESS_TOKEN"]) {
      let tokenProvider = OpenAIExternalTokenProvider(
        tokens: OpenAIAuthTokens(
          accessToken: accessToken,
          chatGPTAccountID: nonEmpty(environment["OPENAI_CHATGPT_ACCOUNT_ID"]),
          chatGPTPlanType: nonEmpty(environment["OPENAI_CHATGPT_PLAN_TYPE"])
        )
      )
      let configuration = OpenAIAuthenticatedAPIConfiguration(
        baseURL: baseURL,
        compatibilityProfile: compatibilityProfile
      )
      return PraxisOpenAIConversationExecutor(
        transport: URLSessionOpenAIAuthenticatedResponsesTransport(
          configuration: configuration,
          tokenProvider: tokenProvider
        ),
        streamingTransport: URLSessionOpenAIAuthenticatedResponsesStreamingTransport(
          configuration: configuration,
          tokenProvider: tokenProvider
        ),
        defaultModel: model,
        compatibilityProfile: compatibilityProfile,
        providerMCPExecutor: providerMCPExecutor
      )
    }

    guard let apiKey = nonEmpty(environment["OPENAI_API_KEY"]) else {
      return nil
    }

    let configuration = OpenAIAPIConfiguration(apiKey: apiKey, baseURL: baseURL)
    return PraxisOpenAIConversationExecutor(
      transport: URLSessionOpenAIResponsesTransport(configuration: configuration),
      streamingTransport: URLSessionOpenAIResponsesStreamingTransport(configuration: configuration),
      defaultModel: model,
      compatibilityProfile: compatibilityProfile,
      providerMCPExecutor: providerMCPExecutor
    )
  }

  static func makeAnthropicExecutor(
    environment: [String: String],
    providerMCPExecutor: (any PraxisProviderMCPExecutor)?
  ) -> PraxisAnthropicConversationExecutor? {
    guard let apiKey = nonEmpty(environment["ANTHROPIC_API_KEY"]) else {
      return nil
    }

    let configuration = AnthropicAPIConfiguration(
      apiKey: apiKey,
      baseURL: url(environment["ANTHROPIC_BASE_URL"], default: "https://api.anthropic.com/v1"),
      version: nonEmpty(environment["ANTHROPIC_VERSION"]) ?? "2023-06-01"
    )

    return PraxisAnthropicConversationExecutor(
      transport: URLSessionAnthropicMessagesTransport(configuration: configuration),
      streamingTransport: URLSessionAnthropicMessagesStreamingTransport(configuration: configuration),
      defaultModel: nonEmpty(environment["ANTHROPIC_MODEL"]) ?? "claude-sonnet-4-20250514",
      defaultMaxTokens: int(environment["ANTHROPIC_MAX_TOKENS"]) ?? 1024,
      providerMCPExecutor: providerMCPExecutor
    )
  }

  static func openAICompatibilityProfile(
    rawValue: String?,
    baseURL: URL
  ) -> OpenAICompatibilityProfile {
    switch nonEmpty(rawValue)?.lowercased() {
    case nil, "auto":
      switch baseURL.host?.lowercased() {
      case "api.openai.com":
        return .openAI
      case "chatgpt.com":
        return .chatGPTCodexOAuth
      default:
        return .newAPI
      }
    case "openai":
      return .openAI
    case "newapi", "new-api":
      return .newAPI
    case "sub2api":
      return .sub2api
    case "chatgpt", "chatgpt-codex-oauth", "chatgpt_codex_oauth":
      return .chatGPTCodexOAuth
    default:
      return .newAPI
    }
  }

  static func url(_ candidate: String?, default fallback: String) -> URL {
    if let rawValue = nonEmpty(candidate), let resolved = URL(string: rawValue) {
      return resolved
    }
    guard let fallbackURL = URL(string: fallback) else {
      preconditionFailure("Invalid SDK environment fallback URL: \(fallback)")
    }
    return fallbackURL
  }

  static func int(_ candidate: String?) -> Int? {
    guard let candidate = nonEmpty(candidate) else {
      return nil
    }
    return Int(candidate)
  }

  static func nonEmpty(_ candidate: String?) -> String? {
    guard let candidate else {
      return nil
    }
    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
