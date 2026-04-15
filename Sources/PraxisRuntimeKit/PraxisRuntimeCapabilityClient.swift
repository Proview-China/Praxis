import PraxisCapabilityCatalog
import PraxisCapabilityContracts
import PraxisCoreTypes
import PraxisProviderContracts
import PraxisRuntimeFacades
import PraxisSession
import PraxisTapTypes
import PraxisToolingContracts

/// Caller-friendly thin capability entrypoint for Phase 3 baseline operations.
///
/// This surface keeps provider, session, and catalog calls behind one narrow Swift API without
/// leaking composition, transport, or raw adapter protocols to embedding callers.
public struct PraxisRuntimeCapabilityClient: Sendable {
  private let capabilityFacade: PraxisCapabilityFacade

  init(capabilityFacade: PraxisCapabilityFacade) {
    self.capabilityFacade = capabilityFacade
  }

  /// Reads the currently available thin capability catalog.
  ///
  /// - Returns: A caller-friendly capability catalog grouped into families.
  public func catalog() -> PraxisRuntimeCapabilityCatalog {
    PraxisRuntimeCapabilityCatalog(snapshot: capabilityFacade.catalog())
  }

  /// Executes one bounded generation request.
  ///
  /// - Parameter request: Caller-friendly generation request.
  /// - Returns: A normalized generation result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func generate(_ request: PraxisRuntimeGenerateRequest) async throws -> PraxisRuntimeGenerateResult {
    let snapshot = try await capabilityFacade.generate(
      .init(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
        contextSummary: request.contextSummary,
        preferredModel: request.preferredModel,
        temperature: request.temperature,
        requiredCapabilityIDs: request.requiredCapabilities.map { .init(rawValue: $0.rawValue) }
      )
    )
    return PraxisRuntimeGenerateResult(snapshot: snapshot)
  }

  /// Executes one bounded streaming-style generation request.
  ///
  /// - Parameters:
  ///   - request: Caller-friendly generation request.
  ///   - chunkCharacterCount: Maximum number of characters projected into each chunk.
  /// - Returns: A normalized streaming generation result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func stream(
    _ request: PraxisRuntimeGenerateRequest,
    chunkCharacterCount: Int = 80
  ) async throws -> PraxisRuntimeGenerateStreamResult {
    let snapshot = try await capabilityFacade.stream(
      .init(
        prompt: request.prompt,
        systemPrompt: request.systemPrompt,
        contextSummary: request.contextSummary,
        preferredModel: request.preferredModel,
        temperature: request.temperature,
        requiredCapabilityIDs: request.requiredCapabilities.map { .init(rawValue: $0.rawValue) }
      ),
      chunkCharacterCount: chunkCharacterCount
    )
    return PraxisRuntimeGenerateStreamResult(snapshot: snapshot)
  }

  /// Executes one embedding request.
  ///
  /// - Parameter request: Caller-friendly embedding request.
  /// - Returns: A normalized embedding result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func embed(_ request: PraxisRuntimeEmbeddingRequest) async throws -> PraxisRuntimeEmbeddingResult {
    let snapshot = try await capabilityFacade.embed(
      .init(
        content: request.content,
        preferredModel: request.preferredModel
      )
    )
    return PraxisRuntimeEmbeddingResult(snapshot: snapshot)
  }

  /// Requests one bounded shell approval through the CMP/TAP review path.
  ///
  /// - Parameter request: Caller-friendly shell approval request.
  /// - Returns: A normalized shell approval result.
  /// - Throws: Any validation or approval failure raised by the underlying capability facade.
  public func requestShellApproval(
    _ request: PraxisRuntimeShellApprovalRequest
  ) async throws -> PraxisRuntimeShellApprovalResult {
    let snapshot = try await capabilityFacade.requestShellApproval(
      .init(
        projectID: request.projectID.rawValue,
        agentID: request.agentID.rawValue,
        targetAgentID: request.targetAgentID.rawValue,
        requestedTier: request.requestedTier,
        summary: request.summary
      )
    )
    return PraxisRuntimeShellApprovalResult(snapshot: snapshot)
  }

  /// Reads the latest bounded shell approval state through the CMP/TAP recovery path.
  ///
  /// - Parameter query: Caller-friendly shell approval readback query.
  /// - Returns: A normalized shell approval readback result.
  /// - Throws: Any validation or readback failure raised by the underlying capability facade.
  public func readbackShellApproval(
    _ query: PraxisRuntimeShellApprovalQuery
  ) async throws -> PraxisRuntimeShellApprovalReadback {
    let snapshot = try await capabilityFacade.readbackShellApproval(
      .init(
        projectID: query.projectID.rawValue,
        agentID: query.agentID?.rawValue,
        targetAgentID: query.targetAgentID?.rawValue
      )
    )
    return PraxisRuntimeShellApprovalReadback(snapshot: snapshot)
  }

  /// Executes one bounded shell command.
  ///
  /// - Parameter request: Caller-friendly bounded shell execution request.
  /// - Returns: A normalized shell execution result.
  /// - Throws: Any validation or shell adapter failure raised by the underlying capability facade.
  public func runShell(_ request: PraxisRuntimeShellRunRequest) async throws -> PraxisRuntimeShellRunResult {
    let snapshot = try await capabilityFacade.runShell(
      .init(
        summary: request.summary,
        command: request.command,
        workingDirectory: request.workingDirectory,
        environment: request.environment,
        timeoutSeconds: request.timeoutSeconds,
        outputMode: request.outputMode,
        requiresPTY: request.requiresPTY
      )
    )
    return PraxisRuntimeShellRunResult(snapshot: snapshot)
  }

  /// Calls one provider-backed tool lane.
  ///
  /// - Parameter request: Caller-friendly tool-call request.
  /// - Returns: A normalized tool-call result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func callTool(_ request: PraxisRuntimeToolCallRequest) async throws -> PraxisRuntimeToolCallResult {
    let snapshot = try await capabilityFacade.callTool(
      .init(
        toolName: request.toolName,
        summary: request.summary,
        serverName: request.serverName
      )
    )
    return PraxisRuntimeToolCallResult(snapshot: snapshot)
  }

  /// Uploads one provider file payload.
  ///
  /// - Parameter request: Caller-friendly file-upload request.
  /// - Returns: A normalized file-upload result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func uploadFile(_ request: PraxisRuntimeFileUploadRequest) async throws -> PraxisRuntimeFileUploadResult {
    let snapshot = try await capabilityFacade.uploadFile(
      .init(
        summary: request.summary,
        purpose: request.purpose
      )
    )
    return PraxisRuntimeFileUploadResult(snapshot: snapshot)
  }

  /// Submits one batch workload.
  ///
  /// - Parameter request: Caller-friendly batch-submit request.
  /// - Returns: A normalized batch-submit result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func submitBatch(_ request: PraxisRuntimeBatchSubmitRequest) async throws -> PraxisRuntimeBatchSubmitResult {
    let snapshot = try await capabilityFacade.submitBatch(
      .init(
        summary: request.summary,
        itemCount: request.itemCount
      )
    )
    return PraxisRuntimeBatchSubmitResult(snapshot: snapshot)
  }

  /// Opens one caller-scoped runtime session header.
  ///
  /// - Parameter request: Caller-friendly runtime-session open request.
  /// - Returns: A normalized runtime-session result.
  /// - Throws: Any validation failure raised by the underlying capability facade.
  public func openSession(
    _ request: PraxisRuntimeSessionOpenRequest = .init()
  ) async throws -> PraxisRuntimeOpenedSession {
    let snapshot = try await capabilityFacade.openSession(
      .init(
        sessionID: request.sessionID?.rawValue,
        title: request.title
      )
    )
    return PraxisRuntimeOpenedSession(snapshot: snapshot)
  }

  /// Executes one web search request.
  ///
  /// - Parameter request: Caller-friendly web-search request.
  /// - Returns: A normalized web-search result.
  /// - Throws: Any validation or provider failure raised by the underlying capability facade.
  public func searchWeb(_ request: PraxisRuntimeWebSearchRequest) async throws -> PraxisRuntimeWebSearchResult {
    let snapshot = try await capabilityFacade.searchWeb(
      .init(
        query: request.query,
        locale: request.locale,
        preferredDomains: request.preferredDomains,
        limit: request.limit
      )
    )
    return PraxisRuntimeWebSearchResult(snapshot: snapshot)
  }

  /// Fetches one candidate URL from the search chain.
  ///
  /// - Parameter request: Caller-friendly fetch request.
  /// - Returns: A normalized fetch result.
  /// - Throws: Any validation or browser failure raised by the underlying capability facade.
  public func fetchSearchResult(_ request: PraxisRuntimeSearchFetchRequest) async throws -> PraxisRuntimeSearchFetchResult {
    let snapshot = try await capabilityFacade.fetchSearchResult(
      .init(
        url: request.url,
        preferredTitle: request.preferredTitle,
        captureSnapshot: request.captureSnapshot,
        waitPolicy: request.waitPolicy,
        timeoutSeconds: request.timeoutSeconds
      )
    )
    return PraxisRuntimeSearchFetchResult(snapshot: snapshot)
  }

  /// Grounds one candidate URL into evidence records.
  ///
  /// - Parameter request: Caller-friendly grounding request.
  /// - Returns: A normalized grounded evidence result.
  /// - Throws: Any validation or grounding failure raised by the underlying capability facade.
  public func groundSearchResult(_ request: PraxisRuntimeSearchGroundRequest) async throws -> PraxisRuntimeSearchGroundResult {
    let snapshot = try await capabilityFacade.groundSearchResult(
      .init(
        taskSummary: request.taskSummary,
        exampleURL: request.exampleURL,
        requestedFacts: request.requestedFacts,
        locale: request.locale,
        maxPages: request.maxPages
      )
    )
    return PraxisRuntimeSearchGroundResult(snapshot: snapshot)
  }
}

/// Caller-friendly capability catalog entry.
public struct PraxisRuntimeCapabilityCatalogEntry: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let name: String
  public let summary: String
  public let kind: PraxisCapabilityKind
  public let supportsStreaming: Bool
  public let tags: [String]

  init(entry: PraxisCapabilityCatalogEntry) {
    capabilityID = .init(entry.manifest.id.rawValue)
    name = entry.manifest.name
    summary = entry.manifest.summary
    kind = entry.manifest.kind
    supportsStreaming = entry.manifest.supportsStreaming
    tags = entry.manifest.tags
  }
}

/// Caller-friendly capability catalog family grouping.
public struct PraxisRuntimeCapabilityCatalogFamily: Sendable, Equatable {
  public let name: String
  public let capabilityIDs: [PraxisRuntimeCapabilityRef]
  public let summary: String?

  init(family: PraxisCapabilityFamily) {
    name = family.name
    capabilityIDs = family.capabilityIDs.map { .init($0.rawValue) }
    summary = family.summary
  }
}

/// Caller-friendly thin capability catalog.
public struct PraxisRuntimeCapabilityCatalog: Sendable, Equatable {
  public let entries: [PraxisRuntimeCapabilityCatalogEntry]
  public let families: [PraxisRuntimeCapabilityCatalogFamily]

  init(snapshot: PraxisCapabilityCatalogSnapshot) {
    entries = snapshot.entries.map(PraxisRuntimeCapabilityCatalogEntry.init(entry:))
    families = snapshot.families.map(PraxisRuntimeCapabilityCatalogFamily.init(family:))
  }

  /// Stable capability identifiers in catalog order.
  public var capabilityIDs: [PraxisRuntimeCapabilityRef] {
    entries.map(\.capabilityID)
  }
}

/// Caller-friendly generation result.
public struct PraxisRuntimeGenerateResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let outputText: String
  public let structuredFields: [String: PraxisValue]
  public let backend: String
  public let providerOperationID: String?
  public let completedAt: String?
  public let preferredModel: String?

  init(snapshot: PraxisCapabilityGenerationSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    outputText = snapshot.outputText
    structuredFields = snapshot.structuredFields
    backend = snapshot.backend
    providerOperationID = snapshot.providerOperationID
    completedAt = snapshot.completedAt
    preferredModel = snapshot.preferredModel
  }
}

/// Caller-friendly projected generation stream chunk.
public struct PraxisRuntimeGenerateStreamChunk: Sendable, Equatable {
  public let index: Int
  public let text: String
  public let isFinal: Bool

  init(chunk: PraxisCapabilityGenerationChunkSnapshot) {
    index = chunk.index
    text = chunk.text
    isFinal = chunk.isFinal
  }
}

/// Caller-friendly streaming generation result.
public struct PraxisRuntimeGenerateStreamResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let outputText: String
  public let chunks: [PraxisRuntimeGenerateStreamChunk]
  public let backend: String
  public let providerOperationID: String?
  public let completedAt: String?
  public let preferredModel: String?

  init(snapshot: PraxisCapabilityGenerationStreamSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    outputText = snapshot.outputText
    chunks = snapshot.chunks.map(PraxisRuntimeGenerateStreamChunk.init(chunk:))
    backend = snapshot.backend
    providerOperationID = snapshot.providerOperationID
    completedAt = snapshot.completedAt
    preferredModel = snapshot.preferredModel
  }
}

/// Caller-friendly embedding result.
public struct PraxisRuntimeEmbeddingResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let vectorLength: Int
  public let preferredModel: String?

  init(snapshot: PraxisCapabilityEmbeddingSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    vectorLength = snapshot.vectorLength
    preferredModel = snapshot.preferredModel
  }
}

/// Caller-friendly bounded shell execution result.
public struct PraxisRuntimeShellRunResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let command: String
  public let workingDirectory: String?
  public let environmentKeys: [String]
  public let outputMode: PraxisToolingOutputMode
  public let requiresPTY: Bool
  public let riskLabel: String
  public let stdout: String
  public let stderr: String
  public let exitCode: Int32
  public let durationMilliseconds: Int?
  public let terminationReason: PraxisShellTerminationReason
  public let outputWasTruncated: Bool

  init(snapshot: PraxisCapabilityShellRunSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    command = snapshot.command
    workingDirectory = snapshot.workingDirectory
    environmentKeys = snapshot.environmentKeys
    outputMode = snapshot.outputMode
    requiresPTY = snapshot.requiresPTY
    riskLabel = snapshot.riskLabel
    stdout = snapshot.stdout
    stderr = snapshot.stderr
    exitCode = snapshot.exitCode
    durationMilliseconds = snapshot.durationMilliseconds
    terminationReason = snapshot.terminationReason
    outputWasTruncated = snapshot.outputWasTruncated
  }

  /// Whether the bounded shell execution exited successfully.
  public var succeeded: Bool {
    exitCode == 0 && terminationReason == .exited
  }
}

/// Caller-friendly bounded shell approval result.
public struct PraxisRuntimeShellApprovalResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let approvedCapabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let projectID: PraxisRuntimeProjectRef
  public let agentID: PraxisRuntimeAgentRef
  public let targetAgentID: PraxisRuntimeAgentRef
  public let requestedTier: PraxisTapCapabilityTier
  public let route: String
  public let outcome: String
  public let tapMode: String
  public let riskLevel: String
  public let humanGateState: String
  public let requestedAt: String
  public let decisionSummary: String

  init(snapshot: PraxisCapabilityShellApprovalSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    approvedCapabilityID = .init(snapshot.approvedCapabilityID.rawValue)
    summary = snapshot.summary
    projectID = .init(snapshot.projectID)
    agentID = .init(snapshot.agentID)
    targetAgentID = .init(snapshot.targetAgentID)
    requestedTier = snapshot.requestedTier
    route = snapshot.route
    outcome = snapshot.outcome
    tapMode = snapshot.tapMode
    riskLevel = snapshot.riskLevel
    humanGateState = snapshot.humanGateState
    requestedAt = snapshot.requestedAt
    decisionSummary = snapshot.decisionSummary
  }

  /// Whether the shell approval request was redirected into provisioning instead of immediate execution.
  public var isProvisioningRedirect: Bool {
    outcome == "redirected_to_provisioning"
  }
}

/// Caller-friendly bounded shell approval readback result.
public struct PraxisRuntimeShellApprovalReadback: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let approvedCapabilityID: PraxisRuntimeCapabilityRef?
  public let summary: String
  public let projectID: PraxisRuntimeProjectRef
  public let agentID: PraxisRuntimeAgentRef?
  public let targetAgentID: PraxisRuntimeAgentRef?
  public let requestedTier: PraxisTapCapabilityTier?
  public let route: String?
  public let outcome: String?
  public let tapMode: String?
  public let riskLevel: String?
  public let humanGateState: String?
  public let requestedAt: String?
  public let decisionSummary: String?
  public let found: Bool

  init(snapshot: PraxisCapabilityShellApprovalReadbackSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    approvedCapabilityID = snapshot.approvedCapabilityID.map { .init($0.rawValue) }
    summary = snapshot.summary
    projectID = .init(snapshot.projectID)
    agentID = snapshot.agentID.map { PraxisRuntimeAgentRef($0) }
    targetAgentID = snapshot.targetAgentID.map { PraxisRuntimeAgentRef($0) }
    requestedTier = snapshot.requestedTier
    route = snapshot.route
    outcome = snapshot.outcome
    tapMode = snapshot.tapMode
    riskLevel = snapshot.riskLevel
    humanGateState = snapshot.humanGateState
    requestedAt = snapshot.requestedAt
    decisionSummary = snapshot.decisionSummary
    found = snapshot.found
  }

  /// Whether the recovered shell approval is currently waiting on a human gate.
  public var isWaitingApproval: Bool {
    humanGateState == "waitingApproval"
  }
}

/// Caller-friendly tool-call result.
public struct PraxisRuntimeToolCallResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let toolName: String
  public let status: PraxisHostCapabilityExecutionStatus
  public let summary: String

  init(snapshot: PraxisCapabilityToolCallSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    toolName = snapshot.toolName
    status = snapshot.status
    summary = snapshot.summary
  }
}

/// Caller-friendly file-upload result.
public struct PraxisRuntimeFileUploadResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let fileID: String
  public let backend: String

  init(snapshot: PraxisCapabilityFileUploadSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    fileID = snapshot.fileID
    backend = snapshot.backend
  }
}

/// Caller-friendly batch-submit result.
public struct PraxisRuntimeBatchSubmitResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let batchID: String
  public let backend: String

  init(snapshot: PraxisCapabilityBatchSubmitSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    batchID = snapshot.batchID
    backend = snapshot.backend
  }
}

/// Caller-friendly runtime-session open result.
public struct PraxisRuntimeOpenedSession: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let sessionID: PraxisRuntimeSessionRef
  public let title: String
  public let temperature: PraxisSessionTemperature
  public let summary: String

  init(snapshot: PraxisRuntimeSessionSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    sessionID = .init(snapshot.sessionID.rawValue)
    title = snapshot.title
    temperature = snapshot.temperature
    summary = snapshot.summary
  }
}

/// Caller-friendly web-search result item.
public struct PraxisRuntimeWebSearchResultItem: Sendable, Equatable {
  public let title: String
  public let snippet: String
  public let url: String
  public let source: String?

  init(snapshot: PraxisCapabilitySearchWebResultSnapshot) {
    title = snapshot.title
    snippet = snapshot.snippet
    url = snapshot.url
    source = snapshot.source
  }
}

/// Caller-friendly web-search result.
public struct PraxisRuntimeWebSearchResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let query: String
  public let summary: String
  public let provider: String?
  public let results: [PraxisRuntimeWebSearchResultItem]

  init(snapshot: PraxisCapabilitySearchWebSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    query = snapshot.query
    summary = snapshot.summary
    provider = snapshot.provider
    results = snapshot.results.map(PraxisRuntimeWebSearchResultItem.init(snapshot:))
  }
}

/// Caller-friendly fetched search candidate result.
public struct PraxisRuntimeSearchFetchResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let requestedURL: String
  public let finalURL: String
  public let title: String?
  public let snapshotPath: String?
  public let summary: String

  init(snapshot: PraxisCapabilitySearchFetchSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    requestedURL = snapshot.requestedURL
    finalURL = snapshot.finalURL
    title = snapshot.title
    snapshotPath = snapshot.snapshotPath
    summary = snapshot.summary
  }
}

/// Caller-friendly grounded page record.
public struct PraxisRuntimeGroundedPage: Sendable, Equatable {
  public let role: String
  public let url: String
  public let title: String?
  public let snapshotPath: String?
  public let screenshotPath: String?
  public let capturedAt: String?

  init(snapshot: PraxisCapabilityGroundedPageSnapshot) {
    role = snapshot.role.rawValue
    url = snapshot.url
    title = snapshot.title
    snapshotPath = snapshot.snapshotPath
    screenshotPath = snapshot.screenshotPath
    capturedAt = snapshot.capturedAt
  }
}

/// Caller-friendly grounded fact record.
public struct PraxisRuntimeGroundedFact: Sendable, Equatable {
  public let name: String
  public let status: String
  public let value: String?
  public let unit: String?
  public let detail: String?
  public let sourceRole: String?
  public let sourceURL: String?
  public let sourceTitle: String?
  public let citationSnippet: String?
  public let observedAt: String?

  init(snapshot: PraxisCapabilityGroundedFactSnapshot) {
    name = snapshot.name
    status = snapshot.status.rawValue
    value = snapshot.value
    unit = snapshot.unit
    detail = snapshot.detail
    sourceRole = snapshot.sourceRole?.rawValue
    sourceURL = snapshot.sourceURL
    sourceTitle = snapshot.sourceTitle
    citationSnippet = snapshot.citationSnippet
    observedAt = snapshot.observedAt
  }
}

/// Caller-friendly grounded search result.
public struct PraxisRuntimeSearchGroundResult: Sendable, Equatable {
  public let capabilityID: PraxisRuntimeCapabilityRef
  public let summary: String
  public let pages: [PraxisRuntimeGroundedPage]
  public let facts: [PraxisRuntimeGroundedFact]
  public let generatedAt: String?
  public let blockedReason: String?

  init(snapshot: PraxisCapabilitySearchGroundSnapshot) {
    capabilityID = .init(snapshot.capabilityID.rawValue)
    summary = snapshot.summary
    pages = snapshot.pages.map(PraxisRuntimeGroundedPage.init(snapshot:))
    facts = snapshot.facts.map(PraxisRuntimeGroundedFact.init(snapshot:))
    generatedAt = snapshot.generatedAt
    blockedReason = snapshot.blockedReason
  }
}
