import PraxisCapabilityContracts
import PraxisContextAssembly
import PraxisCoreTypes
import PraxisInfraContracts
import PraxisMpTypes
import PraxisProviderContracts
import PraxisRuntimeFacades
import Foundation

public typealias PraxisRuntimePreparedContext = PraxisPreparedModelContext

/// RuntimeKit entrypoint for IDE-facing model context preparation and context-backed generation.
public struct PraxisRuntimeContextClient: Sendable {
  private let mpFacade: PraxisMpFacade
  private let cmpFacade: PraxisCmpFacade
  private let capabilityFacade: PraxisCapabilityFacade
  private let conversationStateStore: (any PraxisConversationStateStoreContract)?
  private let compactionDriver: (any PraxisContextCompactionDriver)?

  init(
    mpFacade: PraxisMpFacade,
    cmpFacade: PraxisCmpFacade,
    capabilityFacade: PraxisCapabilityFacade,
    conversationStateStore: (any PraxisConversationStateStoreContract)?,
    compactionDriver: (any PraxisContextCompactionDriver)?
  ) {
    self.mpFacade = mpFacade
    self.cmpFacade = cmpFacade
    self.capabilityFacade = capabilityFacade
    self.conversationStateStore = conversationStateStore
    self.compactionDriver = compactionDriver
  }

  /// Creates a project-scoped context client.
  public func project(_ project: PraxisRuntimeProjectRef) -> PraxisRuntimeContextProjectClient {
    PraxisRuntimeContextProjectClient(
      project: project,
      mpFacade: mpFacade,
      cmpFacade: cmpFacade,
      capabilityFacade: capabilityFacade,
      conversationStateStore: conversationStateStore,
      compactionDriver: compactionDriver
    )
  }
}

/// Project-scoped model context operations for host IDEs.
public struct PraxisRuntimeContextProjectClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let mpFacade: PraxisMpFacade
  private let cmpFacade: PraxisCmpFacade
  private let capabilityFacade: PraxisCapabilityFacade
  private let conversationStateStore: (any PraxisConversationStateStoreContract)?
  private let compactionDriver: (any PraxisContextCompactionDriver)?

  init(
    project: PraxisRuntimeProjectRef,
    mpFacade: PraxisMpFacade,
    cmpFacade: PraxisCmpFacade,
    capabilityFacade: PraxisCapabilityFacade,
    conversationStateStore: (any PraxisConversationStateStoreContract)?,
    compactionDriver: (any PraxisContextCompactionDriver)?
  ) {
    self.project = project
    self.mpFacade = mpFacade
    self.cmpFacade = cmpFacade
    self.capabilityFacade = capabilityFacade
    self.conversationStateStore = conversationStateStore
    self.compactionDriver = compactionDriver
  }

  public func conversation(_ session: PraxisRuntimeSessionRef) -> PraxisRuntimeContextConversationClient {
    PraxisRuntimeContextConversationClient(projectClient: self, session: session)
  }

  /// Prepares one explainable provider context package without invoking the model.
  public func prepare(_ request: PraxisRuntimeContextPrepareRequest) async throws -> PraxisRuntimePreparedContext {
    var issues: [String] = []
    let memoryCandidates = await loadMemoryCandidates(request, issues: &issues)
    let reviewEvidence = await loadReviewEvidence(agent: request.agentID, issues: &issues)
    let capabilitySummaries = loadCapabilitySummaries(issues: &issues)

    let assemblyRequest = PraxisContextAssemblyRequest(
      projectID: project.rawValue,
      task: request.task,
      systemPrompt: request.systemPrompt,
      developerInstructions: request.developerInstructions,
      memoryCandidates: memoryCandidates,
      reviewEvidence: reviewEvidence,
      capabilitySummaries: capabilitySummaries,
      policy: .init(
        maxCharacterBudget: request.maxCharacterBudget,
        includeSupersededMemory: request.includeSupersededMemory,
        compactionMode: request.compactionMode
      )
    )

    var prepared = try await PraxisContextAssemblyService(compactionDriver: compactionDriver).prepare(assemblyRequest)
    if !issues.isEmpty {
      prepared = prepared.appendingIssues(issues)
    }
    return prepared
  }

  /// Prepares context and then runs one generation call using the prepared provider messages.
  public func generate(_ request: PraxisRuntimeContextGenerateRequest) async throws -> PraxisRuntimeContextGenerationResult {
    var prepared = try await prepare(request.prepareRequest)
    let sessionID = request.prepareRequest.sessionID?.rawValue
    let history = try await loadConversationHistory(sessionID: sessionID, limit: 20)
    var continuation = history.turns.last?.providerContinuation ?? [:]
    continuation["contextManifest"] = prepared.manifestSummary
    var conversationIssues: [String] = []
    let providerMessages = try await makeConversationWindowMessages(
      prepared: prepared,
      history: history,
      request: request,
      issues: &conversationIssues
    )
    if !conversationIssues.isEmpty {
      prepared = prepared.appendingIssues(conversationIssues)
    }
    let generationSnapshot = try await capabilityFacade.generate(
      .init(
        messages: providerMessages,
        preferredModel: request.preferredModel,
        temperature: request.temperature,
        requiredCapabilityIDs: request.requiredCapabilities.map { .init(rawValue: $0.rawValue) },
        continuation: continuation,
        toolDefinitions: request.toolDefinitions,
        providerProfile: request.providerProfile,
        stream: request.stream
      )
    )
    let generation = PraxisRuntimeGenerateResult(snapshot: generationSnapshot)
    let conversationState = try await persistConversationTurnIfNeeded(
      sessionID: sessionID,
      request: request,
      prepared: prepared,
      providerMessages: providerMessages,
      generation: generation,
      existingHistory: history
    )
    return PraxisRuntimeContextGenerationResult(
      preparedContext: prepared,
      generation: generation,
      providerContinuation: generation.continuation,
      conversationState: conversationState
    )
  }

  fileprivate func history(session: PraxisRuntimeSessionRef, limit: Int = 20) async throws -> PraxisRuntimeContextConversationHistory {
    let history = try await loadConversationHistory(sessionID: session.rawValue, limit: limit)
    return PraxisRuntimeContextConversationHistory(
      projectID: project.rawValue,
      sessionID: session.rawValue,
      turns: history.turns.map(PraxisRuntimeContextConversationTurn.init(record:))
    )
  }

  fileprivate func replay(session: PraxisRuntimeSessionRef, limit: Int = 20) async throws -> PraxisRuntimeContextConversationReplay {
    let history = try await loadConversationHistory(sessionID: session.rawValue, limit: limit)
    return PraxisRuntimeContextConversationReplay(
      projectID: project.rawValue,
      sessionID: session.rawValue,
      messages: makeReplayMessages(history: history)
    )
  }

  private func loadConversationHistory(
    sessionID: String?,
    limit: Int
  ) async throws -> PraxisConversationHistoryRecord {
    guard let sessionID, let conversationStateStore else {
      return .init(projectID: project.rawValue, sessionID: sessionID ?? "", turns: [])
    }
    return try await conversationStateStore.history(
      .init(projectID: project.rawValue, sessionID: sessionID, limit: limit)
    )
  }

  private func makeConversationWindowMessages(
    prepared: PraxisRuntimePreparedContext,
    history: PraxisConversationHistoryRecord,
    request: PraxisRuntimeContextGenerateRequest,
    issues: inout [String]
  ) async throws -> [PraxisProviderMessage] {
    guard let latest = history.turns.last else {
      return prepared.providerMessages
    }
    let priorWindow = latest.providerInputMessages + latest.assistantMessages
    var providerMessages = priorWindow + prepared.providerMessages
    guard estimateProviderCharacterCount(providerMessages) > request.prepareRequest.maxCharacterBudget else {
      return providerMessages
    }

    guard request.prepareRequest.compactionMode == .providerCompactionPreferred else {
      issues.append("Conversation window exceeds the character budget; deterministic conversation continuation was used.")
      return providerMessages
    }
    guard let compactionDriver else {
      issues.append("Conversation window exceeds the character budget and no context compaction driver is wired.")
      return providerMessages
    }

    do {
      let result = try await compactionDriver.compact(
        .init(
          projectID: project.rawValue,
          messages: priorWindow,
          maxCharacterBudget: request.prepareRequest.maxCharacterBudget
        )
      )
      providerMessages = result.messages + prepared.providerMessages
      if estimateProviderCharacterCount(providerMessages) > request.prepareRequest.maxCharacterBudget {
        issues.append("Conversation window remains over budget after provider compaction.")
      }
      return providerMessages
    } catch {
      issues.append("Conversation window compaction failed: \(error.localizedDescription)")
      return providerMessages
    }
  }

  private func makeReplayMessages(history: PraxisConversationHistoryRecord) -> [PraxisProviderMessage] {
    guard let latest = history.turns.last else {
      return []
    }
    return latest.providerInputMessages + latest.assistantMessages
  }

  private func estimateProviderCharacterCount(_ messages: [PraxisProviderMessage]) -> Int {
    messages
      .flatMap(\.textParts)
      .reduce(0) { $0 + $1.count }
  }

  private func persistConversationTurnIfNeeded(
    sessionID: String?,
    request: PraxisRuntimeContextGenerateRequest,
    prepared: PraxisRuntimePreparedContext,
    providerMessages: [PraxisProviderMessage],
    generation: PraxisRuntimeGenerateResult,
    existingHistory: PraxisConversationHistoryRecord
  ) async throws -> PraxisRuntimeContextConversationState? {
    guard let sessionID else {
      return nil
    }
    guard let conversationStateStore else {
      return .init(
        projectID: project.rawValue,
        sessionID: sessionID,
        turnCount: existingHistory.turns.count,
        latestProviderContinuation: generation.continuation,
        issues: ["Conversation state store is unavailable; generation was not persisted."]
      )
    }

    let turnIndex = (existingHistory.turns.map(\.turnIndex).max() ?? 0) + 1
    let createdAt = runtimeContextNow()
    let record = PraxisConversationTurnRecord(
      projectID: project.rawValue,
      sessionID: sessionID,
      turnID: "turn.\(turnIndex).\(UUID().uuidString)",
      turnIndex: turnIndex,
      agentID: request.prepareRequest.agentID?.rawValue,
      preparedManifestSummary: prepared.manifestSummary,
      includedSectionIDs: prepared.includedSections.map(\.id),
      omittedSectionIDs: prepared.omittedSections.map(\.id),
      providerInputMessages: providerMessages,
      assistantMessages: generation.outputText.isEmpty ? [] : [.assistantText(generation.outputText)],
      providerContinuation: generation.continuation,
      generationSummary: generation.summary,
      outputText: generation.outputText,
      backend: generation.backend,
      providerOperationID: generation.providerOperationID,
      completedAt: generation.completedAt,
      preferredModel: generation.preferredModel,
      createdAt: createdAt
    )
    _ = try await conversationStateStore.save(record)
    return .init(
      projectID: project.rawValue,
      sessionID: sessionID,
      turnCount: turnIndex,
      latestProviderContinuation: generation.continuation,
      issues: []
    )
  }

  private func loadMemoryCandidates(
    _ request: PraxisRuntimeContextPrepareRequest,
    issues: inout [String]
  ) async -> [PraxisContextMemoryCandidate] {
    do {
      let search = try await mpFacade.search(
        .init(
          projectID: project.rawValue,
          query: request.memoryQuery,
          scopeLevels: request.scopeLevels,
          limit: request.memoryLimit,
          agentID: request.agentID?.rawValue,
          sessionID: request.sessionID?.rawValue,
          includeSuperseded: request.includeSupersededMemory
        )
      )
      issues.append(contentsOf: search.issues)
      return search.hits.map {
        PraxisContextMemoryCandidate(
          memoryID: $0.memoryID,
          summary: $0.summary,
          storageKey: $0.storageKey,
          memoryKind: $0.memoryKind,
          freshnessStatus: $0.freshnessStatus,
          alignmentStatus: $0.alignmentStatus,
          scopeLevel: $0.scopeLevel,
          semanticScore: $0.semanticScore,
          finalScore: $0.finalScore,
          rankExplanation: $0.rankExplanation,
          sourceRefs: [$0.storageKey]
        )
      }
    } catch {
      issues.append("MP memory search unavailable for context assembly: \(error.localizedDescription)")
      return []
    }
  }

  private func loadReviewEvidence(
    agent: PraxisRuntimeAgentRef?,
    issues: inout [String]
  ) async -> [String] {
    do {
      async let readback = cmpFacade.readbackProject(.init(projectID: project.rawValue))
      async let smoke = cmpFacade.smokeProject(.init(projectID: project.rawValue))
      async let status = cmpFacade.readbackStatus(
        .init(projectID: project.rawValue, agentID: agent?.rawValue)
      )
      let resolved = try await (readback, smoke, status)
      return [
        "source=cmp.readback; reason=project review state; sourceRef=cmp://\(project.rawValue)/readback; summary=\(resolved.0.summary)",
        "source=cmp.smoke; reason=runtime smoke evidence; sourceRef=cmp://\(project.rawValue)/smoke; summary=\(resolved.1.smokeResult.summary)",
        "source=cmp.status; reason=agent governance status; sourceRef=cmp://\(project.rawValue)/status; summary=\(resolved.2.summary)",
      ].filter { !$0.isEmpty }
    } catch {
      issues.append("CMP review evidence unavailable for context assembly: \(error.localizedDescription)")
      return []
    }
  }

  private func loadCapabilitySummaries(issues: inout [String]) -> [String] {
    let catalog = capabilityFacade.catalog()
    let capabilityIDs = catalog.entries.map(\.manifest.id.rawValue).prefix(12).joined(separator: ", ")
    if catalog.entries.isEmpty {
      issues.append("Capability catalog returned no entries for context assembly.")
      return []
    }
    return [
      "Capability catalog exposes \(catalog.entries.count) entries. Visible sample: \(capabilityIDs)."
    ]
  }
}

public struct PraxisRuntimeContextConversationClient: Sendable {
  private let projectClient: PraxisRuntimeContextProjectClient
  private let session: PraxisRuntimeSessionRef

  fileprivate init(projectClient: PraxisRuntimeContextProjectClient, session: PraxisRuntimeSessionRef) {
    self.projectClient = projectClient
    self.session = session
  }

  public func prepare(_ request: PraxisRuntimeContextPrepareRequest) async throws -> PraxisRuntimePreparedContext {
    try await projectClient.prepare(request.withSession(session))
  }

  public func generate(_ request: PraxisRuntimeContextGenerateRequest) async throws -> PraxisRuntimeContextGenerationResult {
    try await projectClient.generate(request.withSession(session))
  }

  public func history(limit: Int = 20) async throws -> PraxisRuntimeContextConversationHistory {
    try await projectClient.history(session: session, limit: limit)
  }

  public func replay(limit: Int = 20) async throws -> PraxisRuntimeContextConversationReplay {
    try await projectClient.replay(session: session, limit: limit)
  }
}

public struct PraxisRuntimeContextPrepareRequest: Sendable, Equatable {
  public let task: String
  public let agentID: PraxisRuntimeAgentRef?
  public let sessionID: PraxisRuntimeSessionRef?
  public let systemPrompt: String?
  public let developerInstructions: String?
  public let memoryQuery: String
  public let scopeLevels: [PraxisMpScopeLevel]
  public let memoryLimit: Int
  public let includeSupersededMemory: Bool
  public let maxCharacterBudget: Int
  public let compactionMode: PraxisContextCompactionMode

  public init(
    task: String,
    agentID: PraxisRuntimeAgentRef? = nil,
    sessionID: PraxisRuntimeSessionRef? = nil,
    systemPrompt: String? = nil,
    developerInstructions: String? = nil,
    memoryQuery: String? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    memoryLimit: Int = 8,
    includeSupersededMemory: Bool = false,
    maxCharacterBudget: Int = 6_000,
    compactionMode: PraxisContextCompactionMode = .disabled
  ) {
    self.task = task
    self.agentID = agentID
    self.sessionID = sessionID
    self.systemPrompt = systemPrompt
    self.developerInstructions = developerInstructions
    self.memoryQuery = memoryQuery ?? task
    self.scopeLevels = scopeLevels
    self.memoryLimit = memoryLimit
    self.includeSupersededMemory = includeSupersededMemory
    self.maxCharacterBudget = maxCharacterBudget
    self.compactionMode = compactionMode
  }
}

public struct PraxisRuntimeContextGenerateRequest: Sendable, Equatable {
  public let prepareRequest: PraxisRuntimeContextPrepareRequest
  public let preferredModel: String?
  public let temperature: Double?
  public let requiredCapabilities: [PraxisRuntimeCapabilityRef]
  public let toolDefinitions: [PraxisProviderToolDefinition]
  public let providerProfile: PraxisProviderConversationProfile?
  public let stream: Bool

  public init(
    task: String,
    agentID: PraxisRuntimeAgentRef? = nil,
    sessionID: PraxisRuntimeSessionRef? = nil,
    systemPrompt: String? = nil,
    developerInstructions: String? = nil,
    memoryQuery: String? = nil,
    scopeLevels: [PraxisMpScopeLevel] = PraxisMpScopeLevel.allCases,
    memoryLimit: Int = 8,
    includeSupersededMemory: Bool = false,
    maxCharacterBudget: Int = 6_000,
    compactionMode: PraxisContextCompactionMode = .disabled,
    preferredModel: String? = nil,
    temperature: Double? = nil,
    requiredCapabilities: [PraxisRuntimeCapabilityRef] = [],
    toolDefinitions: [PraxisProviderToolDefinition] = [],
    providerProfile: PraxisProviderConversationProfile? = nil,
    stream: Bool = false
  ) {
    self.prepareRequest = .init(
      task: task,
      agentID: agentID,
      sessionID: sessionID,
      systemPrompt: systemPrompt,
      developerInstructions: developerInstructions,
      memoryQuery: memoryQuery,
      scopeLevels: scopeLevels,
      memoryLimit: memoryLimit,
      includeSupersededMemory: includeSupersededMemory,
      maxCharacterBudget: maxCharacterBudget,
      compactionMode: compactionMode
    )
    self.preferredModel = preferredModel
    self.temperature = temperature
    self.requiredCapabilities = requiredCapabilities
    self.toolDefinitions = toolDefinitions
    self.providerProfile = providerProfile
    self.stream = stream
  }
}

public struct PraxisRuntimeContextGenerationResult: Sendable, Equatable {
  public let preparedContext: PraxisRuntimePreparedContext
  public let generation: PraxisRuntimeGenerateResult
  public let providerContinuation: [String: String]
  public let conversationState: PraxisRuntimeContextConversationState?

  public init(
    preparedContext: PraxisRuntimePreparedContext,
    generation: PraxisRuntimeGenerateResult,
    providerContinuation: [String: String] = [:],
    conversationState: PraxisRuntimeContextConversationState? = nil
  ) {
    self.preparedContext = preparedContext
    self.generation = generation
    self.providerContinuation = providerContinuation
    self.conversationState = conversationState
  }
}

public struct PraxisRuntimeContextConversationState: Sendable, Equatable {
  public let projectID: String
  public let sessionID: String
  public let turnCount: Int
  public let latestProviderContinuation: [String: String]
  public let issues: [String]
}

public struct PraxisRuntimeContextConversationTurn: Sendable, Equatable, Identifiable {
  public let id: String
  public let turnID: String
  public let turnIndex: Int
  public let preparedManifestSummary: String
  public let includedSectionIDs: [String]
  public let omittedSectionIDs: [String]
  public let providerContinuation: [String: String]
  public let outputText: String
  public let createdAt: String

  init(record: PraxisConversationTurnRecord) {
    id = record.turnID
    turnID = record.turnID
    turnIndex = record.turnIndex
    preparedManifestSummary = record.preparedManifestSummary
    includedSectionIDs = record.includedSectionIDs
    omittedSectionIDs = record.omittedSectionIDs
    providerContinuation = record.providerContinuation
    outputText = record.outputText
    createdAt = record.createdAt
  }
}

public struct PraxisRuntimeContextConversationHistory: Sendable, Equatable {
  public let projectID: String
  public let sessionID: String
  public let turns: [PraxisRuntimeContextConversationTurn]
}

public struct PraxisRuntimeContextConversationReplay: Sendable, Equatable {
  public let projectID: String
  public let sessionID: String
  public let messages: [PraxisProviderMessage]
}

private extension PraxisRuntimeContextPrepareRequest {
  func withSession(_ session: PraxisRuntimeSessionRef) -> PraxisRuntimeContextPrepareRequest {
    .init(
      task: task,
      agentID: agentID,
      sessionID: session,
      systemPrompt: systemPrompt,
      developerInstructions: developerInstructions,
      memoryQuery: memoryQuery,
      scopeLevels: scopeLevels,
      memoryLimit: memoryLimit,
      includeSupersededMemory: includeSupersededMemory,
      maxCharacterBudget: maxCharacterBudget,
      compactionMode: compactionMode
    )
  }
}

private extension PraxisRuntimeContextGenerateRequest {
  func withSession(_ session: PraxisRuntimeSessionRef) -> PraxisRuntimeContextGenerateRequest {
    .init(
      task: prepareRequest.task,
      agentID: prepareRequest.agentID,
      sessionID: session,
      systemPrompt: prepareRequest.systemPrompt,
      developerInstructions: prepareRequest.developerInstructions,
      memoryQuery: prepareRequest.memoryQuery,
      scopeLevels: prepareRequest.scopeLevels,
      memoryLimit: prepareRequest.memoryLimit,
      includeSupersededMemory: prepareRequest.includeSupersededMemory,
      maxCharacterBudget: prepareRequest.maxCharacterBudget,
      compactionMode: prepareRequest.compactionMode,
      preferredModel: preferredModel,
      temperature: temperature,
      requiredCapabilities: requiredCapabilities,
      toolDefinitions: toolDefinitions,
      providerProfile: providerProfile,
      stream: stream
    )
  }
}

private func runtimeContextNow() -> String {
  ISO8601DateFormatter().string(from: Date())
}

private extension PraxisPreparedModelContext {
  func appendingIssues(_ additionalIssues: [String]) -> PraxisPreparedModelContext {
    PraxisPreparedModelContext(
      projectID: projectID,
      includedSections: includedSections,
      omittedSections: omittedSections,
      budget: budget,
      manifestSummary: manifestSummary,
      providerMessages: providerMessages,
      compaction: compaction,
      issues: issues + additionalIssues
    )
  }
}
