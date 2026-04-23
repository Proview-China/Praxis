import PraxisCapabilityContracts
import PraxisContextAssembly
import PraxisCoreTypes
import PraxisMpTypes
import PraxisProviderContracts
import PraxisRuntimeFacades

public typealias PraxisRuntimePreparedContext = PraxisPreparedModelContext

/// RuntimeKit entrypoint for IDE-facing model context preparation and context-backed generation.
public struct PraxisRuntimeContextClient: Sendable {
  private let mpFacade: PraxisMpFacade
  private let cmpFacade: PraxisCmpFacade
  private let capabilityFacade: PraxisCapabilityFacade

  init(
    mpFacade: PraxisMpFacade,
    cmpFacade: PraxisCmpFacade,
    capabilityFacade: PraxisCapabilityFacade
  ) {
    self.mpFacade = mpFacade
    self.cmpFacade = cmpFacade
    self.capabilityFacade = capabilityFacade
  }

  /// Creates a project-scoped context client.
  public func project(_ project: PraxisRuntimeProjectRef) -> PraxisRuntimeContextProjectClient {
    PraxisRuntimeContextProjectClient(
      project: project,
      mpFacade: mpFacade,
      cmpFacade: cmpFacade,
      capabilityFacade: capabilityFacade
    )
  }
}

/// Project-scoped model context operations for host IDEs.
public struct PraxisRuntimeContextProjectClient: Sendable {
  private let project: PraxisRuntimeProjectRef
  private let mpFacade: PraxisMpFacade
  private let cmpFacade: PraxisCmpFacade
  private let capabilityFacade: PraxisCapabilityFacade

  init(
    project: PraxisRuntimeProjectRef,
    mpFacade: PraxisMpFacade,
    cmpFacade: PraxisCmpFacade,
    capabilityFacade: PraxisCapabilityFacade
  ) {
    self.project = project
    self.mpFacade = mpFacade
    self.cmpFacade = cmpFacade
    self.capabilityFacade = capabilityFacade
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

    var prepared = try await PraxisContextAssemblyService().prepare(assemblyRequest)
    if !issues.isEmpty {
      prepared = prepared.appendingIssues(issues)
    }
    return prepared
  }

  /// Prepares context and then runs one generation call using the prepared provider messages.
  public func generate(_ request: PraxisRuntimeContextGenerateRequest) async throws -> PraxisRuntimeContextGenerationResult {
    let prepared = try await prepare(request.prepareRequest)
    let generationSnapshot = try await capabilityFacade.generate(
      .init(
        messages: prepared.providerMessages,
        preferredModel: request.preferredModel,
        temperature: request.temperature,
        requiredCapabilityIDs: request.requiredCapabilities.map { .init(rawValue: $0.rawValue) },
        continuation: ["contextManifest": prepared.manifestSummary],
        toolDefinitions: request.toolDefinitions,
        providerProfile: request.providerProfile,
        stream: request.stream
      )
    )
    return PraxisRuntimeContextGenerationResult(
      preparedContext: prepared,
      generation: PraxisRuntimeGenerateResult(snapshot: generationSnapshot)
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
        resolved.0.summary,
        resolved.1.smokeResult.summary,
        resolved.2.summary,
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

  public init(
    preparedContext: PraxisRuntimePreparedContext,
    generation: PraxisRuntimeGenerateResult
  ) {
    self.preparedContext = preparedContext
    self.generation = generation
  }
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
