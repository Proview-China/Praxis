import Foundation
import PraxisCapabilityCatalog
import PraxisCapabilityContracts
import PraxisCapabilityResults
import PraxisCoreTypes
import PraxisInfraContracts
import PraxisProviderContracts
import PraxisRuntimeComposition
import PraxisSession
import PraxisTapTypes
import PraxisToolingContracts
import PraxisWorkspaceContracts

/// Structured generation command for the thin capability surface.
public struct PraxisCapabilityGenerateCommand: Sendable, Equatable, Codable {
  public let prompt: String
  public let systemPrompt: String?
  public let contextSummary: String?
  public let preferredModel: String?
  public let temperature: Double?
  public let requiredCapabilityIDs: [PraxisCapabilityID]

  public init(
    prompt: String,
    systemPrompt: String? = nil,
    contextSummary: String? = nil,
    preferredModel: String? = nil,
    temperature: Double? = nil,
    requiredCapabilityIDs: [PraxisCapabilityID] = []
  ) {
    self.prompt = prompt
    self.systemPrompt = systemPrompt
    self.contextSummary = contextSummary
    self.preferredModel = preferredModel
    self.temperature = temperature
    self.requiredCapabilityIDs = requiredCapabilityIDs
  }
}

/// Structured embedding command for the thin capability surface.
public struct PraxisCapabilityEmbedCommand: Sendable, Equatable, Codable {
  public let content: String
  public let preferredModel: String?

  public init(
    content: String,
    preferredModel: String? = nil
  ) {
    self.content = content
    self.preferredModel = preferredModel
  }
}

/// Structured code-run command for the bounded execution surface.
public struct PraxisCapabilityCodeRunCommand: Sendable, Equatable, Codable {
  public let summary: String
  public let runtime: PraxisCodeRuntime
  public let source: String
  public let workingDirectory: String?
  public let environment: [String: String]
  public let timeoutSeconds: Double?
  public let outputMode: PraxisToolingOutputMode

  public init(
    summary: String,
    runtime: PraxisCodeRuntime = .swift,
    source: String,
    workingDirectory: String? = nil,
    environment: [String: String] = [:],
    timeoutSeconds: Double? = nil,
    outputMode: PraxisToolingOutputMode = .buffered
  ) {
    self.summary = summary
    self.runtime = runtime
    self.source = source
    self.workingDirectory = workingDirectory
    self.environment = environment
    self.timeoutSeconds = timeoutSeconds
    self.outputMode = outputMode
  }
}

/// One workspace patch change for the bounded code patch surface.
public struct PraxisCapabilityCodePatchChange: Sendable, Equatable, Codable {
  public let path: String
  public let patch: String
  public let expectedRevisionToken: String?

  public init(
    path: String,
    patch: String,
    expectedRevisionToken: String? = nil
  ) {
    self.path = path
    self.patch = patch
    self.expectedRevisionToken = expectedRevisionToken
  }
}

/// Structured code-patch command for the bounded execution surface.
public struct PraxisCapabilityCodePatchCommand: Sendable, Equatable, Codable {
  public let summary: String
  public let changes: [PraxisCapabilityCodePatchChange]

  public init(
    summary: String,
    changes: [PraxisCapabilityCodePatchChange]
  ) {
    self.summary = summary
    self.changes = changes
  }
}

/// Structured code-sandbox command for the bounded execution surface.
public struct PraxisCapabilityCodeSandboxCommand: Sendable, Equatable, Codable {
  public let profile: PraxisCodeSandboxProfile
  public let workingDirectory: String?
  public let requestedRuntime: PraxisCodeRuntime

  public init(
    profile: PraxisCodeSandboxProfile = .workspaceWriteLimited,
    workingDirectory: String? = nil,
    requestedRuntime: PraxisCodeRuntime = .swift
  ) {
    self.profile = profile
    self.workingDirectory = workingDirectory
    self.requestedRuntime = requestedRuntime
  }
}

/// Structured shell-run command for the bounded execution surface.
public struct PraxisCapabilityShellRunCommand: Sendable, Equatable, Codable {
  public let summary: String
  public let command: String
  public let workingDirectory: String?
  public let environment: [String: String]
  public let timeoutSeconds: Double?
  public let outputMode: PraxisToolingOutputMode
  public let requiresPTY: Bool

  public init(
    summary: String,
    command: String,
    workingDirectory: String? = nil,
    environment: [String: String] = [:],
    timeoutSeconds: Double? = nil,
    outputMode: PraxisToolingOutputMode = .buffered,
    requiresPTY: Bool = false
  ) {
    self.summary = summary
    self.command = command
    self.workingDirectory = workingDirectory
    self.environment = environment
    self.timeoutSeconds = timeoutSeconds
    self.outputMode = outputMode
    self.requiresPTY = requiresPTY
  }
}

/// Structured shell-approval command for the bounded execution surface.
public struct PraxisCapabilityShellApprovalCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let targetAgentID: String
  public let requestedTier: PraxisTapCapabilityTier
  public let summary: String

  public init(
    projectID: String,
    agentID: String,
    targetAgentID: String,
    requestedTier: PraxisTapCapabilityTier,
    summary: String
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.requestedTier = requestedTier
    self.summary = summary
  }
}

/// Structured shell-approval readback query for the bounded execution surface.
public struct PraxisCapabilityShellApprovalReadbackCommand: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String?
  public let targetAgentID: String?

  public init(
    projectID: String,
    agentID: String? = nil,
    targetAgentID: String? = nil
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
  }
}

/// Structured provider-skill list query for the thin capability surface.
public struct PraxisCapabilitySkillListCommand: Sendable, Equatable, Codable {
  public init() {}
}

/// Structured provider MCP-tool list query for the thin capability surface.
public struct PraxisCapabilityProviderMCPToolListCommand: Sendable, Equatable, Codable {
  public init() {}
}

/// Structured provider-skill activation command for the thin capability surface.
public struct PraxisCapabilitySkillActivateCommand: Sendable, Equatable, Codable {
  public let skillKey: String
  public let reason: String?

  public init(
    skillKey: String,
    reason: String? = nil
  ) {
    self.skillKey = skillKey
    self.reason = reason
  }
}

/// Structured tool-call command for the thin capability surface.
public struct PraxisCapabilityToolCallCommand: Sendable, Equatable, Codable {
  public let toolName: String
  public let summary: String
  public let serverName: String?

  public init(
    toolName: String,
    summary: String,
    serverName: String? = nil
  ) {
    self.toolName = toolName
    self.summary = summary
    self.serverName = serverName
  }
}

/// Structured file-upload command for the thin capability surface.
public struct PraxisCapabilityFileUploadCommand: Sendable, Equatable, Codable {
  public let summary: String
  public let purpose: String?

  public init(
    summary: String,
    purpose: String? = nil
  ) {
    self.summary = summary
    self.purpose = purpose
  }
}

/// Structured batch-submit command for the thin capability surface.
public struct PraxisCapabilityBatchSubmitCommand: Sendable, Equatable, Codable {
  public let summary: String
  public let itemCount: Int

  public init(
    summary: String,
    itemCount: Int
  ) {
    self.summary = summary
    self.itemCount = itemCount
  }
}

/// Structured runtime-session open command for the thin capability surface.
public struct PraxisOpenRuntimeSessionCommand: Sendable, Equatable, Codable {
  public let sessionID: String?
  public let title: String?

  public init(
    sessionID: String? = nil,
    title: String? = nil
  ) {
    self.sessionID = sessionID
    self.title = title
  }
}

/// Structured web-search command for the search capability chain.
public struct PraxisCapabilitySearchWebCommand: Sendable, Equatable, Codable {
  public let query: String
  public let locale: String?
  public let preferredDomains: [String]
  public let limit: Int

  public init(
    query: String,
    locale: String? = nil,
    preferredDomains: [String] = [],
    limit: Int = 5
  ) {
    self.query = query
    self.locale = locale
    self.preferredDomains = preferredDomains
    self.limit = limit
  }
}

/// Structured fetch command for the search capability chain.
public struct PraxisCapabilitySearchFetchCommand: Sendable, Equatable, Codable {
  public let url: String
  public let preferredTitle: String?
  public let captureSnapshot: Bool
  public let waitPolicy: PraxisBrowserWaitPolicy
  public let timeoutSeconds: Double?

  public init(
    url: String,
    preferredTitle: String? = nil,
    captureSnapshot: Bool = true,
    waitPolicy: PraxisBrowserWaitPolicy = .domReady,
    timeoutSeconds: Double? = 2
  ) {
    self.url = url
    self.preferredTitle = preferredTitle
    self.captureSnapshot = captureSnapshot
    self.waitPolicy = waitPolicy
    self.timeoutSeconds = timeoutSeconds
  }
}

/// Structured grounding command for the search capability chain.
public struct PraxisCapabilitySearchGroundCommand: Sendable, Equatable, Codable {
  public let taskSummary: String
  public let exampleURL: String?
  public let requestedFacts: [String]
  public let locale: String?
  public let maxPages: Int

  public init(
    taskSummary: String,
    exampleURL: String? = nil,
    requestedFacts: [String] = [],
    locale: String? = nil,
    maxPages: Int = 5
  ) {
    self.taskSummary = taskSummary
    self.exampleURL = exampleURL
    self.requestedFacts = requestedFacts
    self.locale = locale
    self.maxPages = maxPages
  }
}

/// Result snapshot for one thin generation call.
public struct PraxisCapabilityGenerationSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let outputText: String
  public let structuredFields: [String: PraxisValue]
  public let backend: String
  public let providerOperationID: String?
  public let completedAt: String?
  public let preferredModel: String?

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    outputText: String,
    structuredFields: [String: PraxisValue],
    backend: String,
    providerOperationID: String? = nil,
    completedAt: String? = nil,
    preferredModel: String? = nil
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.outputText = outputText
    self.structuredFields = structuredFields
    self.backend = backend
    self.providerOperationID = providerOperationID
    self.completedAt = completedAt
    self.preferredModel = preferredModel
  }
}

/// One bounded stream chunk projected from a thin generation stream call.
public struct PraxisCapabilityGenerationChunkSnapshot: Sendable, Equatable, Codable {
  public let index: Int
  public let text: String
  public let isFinal: Bool

  public init(
    index: Int,
    text: String,
    isFinal: Bool
  ) {
    self.index = index
    self.text = text
    self.isFinal = isFinal
  }
}

/// Result snapshot for one bounded streaming-style generation call.
public struct PraxisCapabilityGenerationStreamSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let outputText: String
  public let chunks: [PraxisCapabilityGenerationChunkSnapshot]
  public let backend: String
  public let providerOperationID: String?
  public let completedAt: String?
  public let preferredModel: String?

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    outputText: String,
    chunks: [PraxisCapabilityGenerationChunkSnapshot],
    backend: String,
    providerOperationID: String? = nil,
    completedAt: String? = nil,
    preferredModel: String? = nil
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.outputText = outputText
    self.chunks = chunks
    self.backend = backend
    self.providerOperationID = providerOperationID
    self.completedAt = completedAt
    self.preferredModel = preferredModel
  }
}

/// Result snapshot for one thin embedding call.
public struct PraxisCapabilityEmbeddingSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let vectorLength: Int
  public let preferredModel: String?

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    vectorLength: Int,
    preferredModel: String? = nil
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.vectorLength = vectorLength
    self.preferredModel = preferredModel
  }
}

/// Result snapshot for one bounded code execution.
public struct PraxisCapabilityCodeRunSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let runtime: PraxisCodeRuntime
  public let launcher: String
  public let workingDirectory: String?
  public let environmentKeys: [String]
  public let outputMode: PraxisToolingOutputMode
  public let riskLabel: String
  public let stdout: String
  public let stderr: String
  public let exitCode: Int32
  public let durationMilliseconds: Int?
  public let terminationReason: PraxisShellTerminationReason
  public let outputWasTruncated: Bool

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    runtime: PraxisCodeRuntime,
    launcher: String,
    workingDirectory: String?,
    environmentKeys: [String],
    outputMode: PraxisToolingOutputMode,
    riskLabel: String,
    stdout: String,
    stderr: String,
    exitCode: Int32,
    durationMilliseconds: Int? = nil,
    terminationReason: PraxisShellTerminationReason,
    outputWasTruncated: Bool = false
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.runtime = runtime
    self.launcher = launcher
    self.workingDirectory = workingDirectory
    self.environmentKeys = environmentKeys
    self.outputMode = outputMode
    self.riskLabel = riskLabel
    self.stdout = stdout
    self.stderr = stderr
    self.exitCode = exitCode
    self.durationMilliseconds = durationMilliseconds
    self.terminationReason = terminationReason
    self.outputWasTruncated = outputWasTruncated
  }
}

/// Result snapshot for one bounded workspace patch execution.
public struct PraxisCapabilityCodePatchSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let changedPaths: [String]
  public let appliedChangeCount: Int
  public let riskLabel: String

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    changedPaths: [String],
    appliedChangeCount: Int,
    riskLabel: String
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.changedPaths = changedPaths
    self.appliedChangeCount = appliedChangeCount
    self.riskLabel = riskLabel
  }
}

/// Result snapshot for one bounded code sandbox contract readback.
public struct PraxisCapabilityCodeSandboxSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let profile: PraxisCodeSandboxProfile
  public let enforcementMode: PraxisCodeSandboxEnforcementMode
  public let allowedRuntimes: [PraxisCodeRuntime]
  public let readableRoots: [String]
  public let writableRoots: [String]
  public let allowsNetworkAccess: Bool
  public let allowsSubprocesses: Bool

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    profile: PraxisCodeSandboxProfile,
    enforcementMode: PraxisCodeSandboxEnforcementMode,
    allowedRuntimes: [PraxisCodeRuntime],
    readableRoots: [String],
    writableRoots: [String],
    allowsNetworkAccess: Bool,
    allowsSubprocesses: Bool
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.profile = profile
    self.enforcementMode = enforcementMode
    self.allowedRuntimes = allowedRuntimes
    self.readableRoots = readableRoots
    self.writableRoots = writableRoots
    self.allowsNetworkAccess = allowsNetworkAccess
    self.allowsSubprocesses = allowsSubprocesses
  }
}

/// Result snapshot for one bounded shell execution.
public struct PraxisCapabilityShellRunSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
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

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    command: String,
    workingDirectory: String?,
    environmentKeys: [String],
    outputMode: PraxisToolingOutputMode,
    requiresPTY: Bool,
    riskLabel: String,
    stdout: String,
    stderr: String,
    exitCode: Int32,
    durationMilliseconds: Int? = nil,
    terminationReason: PraxisShellTerminationReason,
    outputWasTruncated: Bool = false
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.command = command
    self.workingDirectory = workingDirectory
    self.environmentKeys = environmentKeys
    self.outputMode = outputMode
    self.requiresPTY = requiresPTY
    self.riskLabel = riskLabel
    self.stdout = stdout
    self.stderr = stderr
    self.exitCode = exitCode
    self.durationMilliseconds = durationMilliseconds
    self.terminationReason = terminationReason
    self.outputWasTruncated = outputWasTruncated
  }
}

/// Result snapshot for one bounded shell approval request.
public struct PraxisCapabilityShellApprovalSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let approvedCapabilityID: PraxisCapabilityID
  public let summary: String
  public let projectID: String
  public let agentID: String
  public let targetAgentID: String
  public let requestedTier: PraxisTapCapabilityTier
  public let route: String
  public let outcome: String
  public let tapMode: String
  public let riskLevel: String
  public let humanGateState: String
  public let requestedAt: String
  public let decisionSummary: String

  public init(
    capabilityID: PraxisCapabilityID,
    approvedCapabilityID: PraxisCapabilityID,
    summary: String,
    projectID: String,
    agentID: String,
    targetAgentID: String,
    requestedTier: PraxisTapCapabilityTier,
    route: String,
    outcome: String,
    tapMode: String,
    riskLevel: String,
    humanGateState: String,
    requestedAt: String,
    decisionSummary: String
  ) {
    self.capabilityID = capabilityID
    self.approvedCapabilityID = approvedCapabilityID
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.requestedTier = requestedTier
    self.route = route
    self.outcome = outcome
    self.tapMode = tapMode
    self.riskLevel = riskLevel
    self.humanGateState = humanGateState
    self.requestedAt = requestedAt
    self.decisionSummary = decisionSummary
  }
}

/// Result snapshot for one bounded shell approval readback.
public struct PraxisCapabilityShellApprovalReadbackSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let approvedCapabilityID: PraxisCapabilityID?
  public let summary: String
  public let projectID: String
  public let agentID: String?
  public let targetAgentID: String?
  public let requestedTier: PraxisTapCapabilityTier?
  public let route: String?
  public let outcome: String?
  public let tapMode: String?
  public let riskLevel: String?
  public let humanGateState: String?
  public let requestedAt: String?
  public let decisionSummary: String?
  public let found: Bool

  public init(
    capabilityID: PraxisCapabilityID,
    approvedCapabilityID: PraxisCapabilityID? = nil,
    summary: String,
    projectID: String,
    agentID: String? = nil,
    targetAgentID: String? = nil,
    requestedTier: PraxisTapCapabilityTier? = nil,
    route: String? = nil,
    outcome: String? = nil,
    tapMode: String? = nil,
    riskLevel: String? = nil,
    humanGateState: String? = nil,
    requestedAt: String? = nil,
    decisionSummary: String? = nil,
    found: Bool
  ) {
    self.capabilityID = capabilityID
    self.approvedCapabilityID = approvedCapabilityID
    self.summary = summary
    self.projectID = projectID
    self.agentID = agentID
    self.targetAgentID = targetAgentID
    self.requestedTier = requestedTier
    self.route = route
    self.outcome = outcome
    self.tapMode = tapMode
    self.riskLevel = riskLevel
    self.humanGateState = humanGateState
    self.requestedAt = requestedAt
    self.decisionSummary = decisionSummary
    self.found = found
  }
}

/// Result snapshot for one thin provider-skill list capability.
public struct PraxisCapabilitySkillListSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let skillKeys: [String]

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    skillKeys: [String]
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.skillKeys = skillKeys
  }
}

/// Result snapshot for one thin provider-skill activation capability.
public struct PraxisCapabilitySkillActivateSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let skillKey: String
  public let activated: Bool

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    skillKey: String,
    activated: Bool
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.skillKey = skillKey
    self.activated = activated
  }
}

/// Result snapshot for one provider MCP-tool list readback.
public struct PraxisCapabilityProviderMCPToolListSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let toolNames: [String]

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    toolNames: [String]
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.toolNames = toolNames
  }
}

/// Result snapshot for one thin tool-call capability.
public struct PraxisCapabilityToolCallSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let toolName: String
  public let status: PraxisHostCapabilityExecutionStatus
  public let summary: String

  public init(
    capabilityID: PraxisCapabilityID,
    toolName: String,
    status: PraxisHostCapabilityExecutionStatus,
    summary: String
  ) {
    self.capabilityID = capabilityID
    self.toolName = toolName
    self.status = status
    self.summary = summary
  }
}

/// Result snapshot for one thin file-upload capability.
public struct PraxisCapabilityFileUploadSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let fileID: String
  public let backend: String

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    fileID: String,
    backend: String
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.fileID = fileID
    self.backend = backend
  }
}

/// Result snapshot for one thin batch-submit capability.
public struct PraxisCapabilityBatchSubmitSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let batchID: String
  public let backend: String

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    batchID: String,
    backend: String
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.batchID = batchID
    self.backend = backend
  }
}

/// Result snapshot for one runtime session-open capability call.
public struct PraxisRuntimeSessionSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let sessionID: PraxisSessionID
  public let title: String
  public let temperature: PraxisSessionTemperature
  public let summary: String

  public init(
    capabilityID: PraxisCapabilityID,
    sessionID: PraxisSessionID,
    title: String,
    temperature: PraxisSessionTemperature,
    summary: String
  ) {
    self.capabilityID = capabilityID
    self.sessionID = sessionID
    self.title = title
    self.temperature = temperature
    self.summary = summary
  }
}

/// One projected web-search result snapshot.
public struct PraxisCapabilitySearchWebResultSnapshot: Sendable, Equatable, Codable {
  public let title: String
  public let snippet: String
  public let url: String
  public let source: String?

  public init(
    title: String,
    snippet: String,
    url: String,
    source: String? = nil
  ) {
    self.title = title
    self.snippet = snippet
    self.url = url
    self.source = source
  }
}

/// Result snapshot for one web-search capability call.
public struct PraxisCapabilitySearchWebSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let query: String
  public let summary: String
  public let provider: String?
  public let results: [PraxisCapabilitySearchWebResultSnapshot]

  public init(
    capabilityID: PraxisCapabilityID,
    query: String,
    summary: String,
    provider: String? = nil,
    results: [PraxisCapabilitySearchWebResultSnapshot]
  ) {
    self.capabilityID = capabilityID
    self.query = query
    self.summary = summary
    self.provider = provider
    self.results = results
  }
}

/// Result snapshot for one fetch capability call.
public struct PraxisCapabilitySearchFetchSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let requestedURL: String
  public let finalURL: String
  public let title: String?
  public let snapshotPath: String?
  public let summary: String

  public init(
    capabilityID: PraxisCapabilityID,
    requestedURL: String,
    finalURL: String,
    title: String? = nil,
    snapshotPath: String? = nil,
    summary: String
  ) {
    self.capabilityID = capabilityID
    self.requestedURL = requestedURL
    self.finalURL = finalURL
    self.title = title
    self.snapshotPath = snapshotPath
    self.summary = summary
  }
}

/// One projected page record for grounded search evidence.
public struct PraxisCapabilityGroundedPageSnapshot: Sendable, Equatable, Codable {
  public let role: PraxisBrowserGroundingSourceRole
  public let url: String
  public let title: String?
  public let snapshotPath: String?
  public let screenshotPath: String?
  public let capturedAt: String?

  public init(page: PraxisBrowserGroundingPageEvidence) {
    role = page.role
    url = page.url
    title = page.title
    snapshotPath = page.snapshotPath
    screenshotPath = page.screenshotPath
    capturedAt = page.capturedAt
  }
}

/// One projected fact record for grounded search evidence.
public struct PraxisCapabilityGroundedFactSnapshot: Sendable, Equatable, Codable {
  public let name: String
  public let status: PraxisBrowserGroundingFactStatus
  public let value: String?
  public let unit: String?
  public let detail: String?
  public let sourceRole: PraxisBrowserGroundingSourceRole?
  public let sourceURL: String?
  public let sourceTitle: String?
  public let citationSnippet: String?
  public let observedAt: String?

  public init(fact: PraxisBrowserGroundingFactEvidence) {
    name = fact.name
    status = fact.status
    value = fact.value
    unit = fact.unit
    detail = fact.detail
    sourceRole = fact.sourceRole
    sourceURL = fact.sourceURL
    sourceTitle = fact.sourceTitle
    citationSnippet = fact.citationSnippet
    observedAt = fact.observedAt
  }
}

/// Result snapshot for one grounding capability call.
public struct PraxisCapabilitySearchGroundSnapshot: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let summary: String
  public let pages: [PraxisCapabilityGroundedPageSnapshot]
  public let facts: [PraxisCapabilityGroundedFactSnapshot]
  public let generatedAt: String?
  public let blockedReason: String?

  public init(
    capabilityID: PraxisCapabilityID,
    summary: String,
    pages: [PraxisCapabilityGroundedPageSnapshot],
    facts: [PraxisCapabilityGroundedFactSnapshot],
    generatedAt: String? = nil,
    blockedReason: String? = nil
  ) {
    self.capabilityID = capabilityID
    self.summary = summary
    self.pages = pages
    self.facts = facts
    self.generatedAt = generatedAt
    self.blockedReason = blockedReason
  }
}

private func normalizedCapabilityText(_ rawValue: String?, fieldName: String) throws -> String {
  guard let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
    throw PraxisError.invalidInput("Thin capability \(fieldName) must not be empty.")
  }
  return trimmed
}

private func normalizedCapabilityPath(_ rawValue: String?) -> String? {
  guard let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
    return nil
  }
  return trimmed
}

private func normalizedOptionalCapabilityText(_ rawValue: String?) -> String? {
  guard let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
    return nil
  }
  return trimmed
}

private func normalizedCapabilityEnvironment(
  _ environment: [String: String]
) throws -> [String: String] {
  var normalized: [String: String] = [:]
  for (rawKey, rawValue) in environment {
    let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !key.isEmpty else {
      throw PraxisError.invalidInput("Thin capability shell.run environment keys must not be blank.")
    }
    normalized[key] = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  return normalized
}

private func normalizedCapabilityRootPaths(_ paths: [String]) -> [String] {
  paths.map { URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL.path }
}

private func capabilityPath(
  _ rawValue: String
) -> String {
  URL(fileURLWithPath: rawValue, isDirectory: true).standardizedFileURL.path
}

private func capabilityPathIsContained(
  _ candidatePath: String,
  within allowedRoots: [String]
) -> Bool {
  let normalizedCandidate = capabilityPath(candidatePath)
  return normalizedCapabilityRootPaths(allowedRoots).contains { rootPath in
    normalizedCandidate == rootPath || normalizedCandidate.hasPrefix(rootPath + "/")
  }
}

private func chunkedCapabilityText(_ text: String, chunkCharacterCount: Int) -> [PraxisCapabilityGenerationChunkSnapshot] {
  guard !text.isEmpty else {
    return [.init(index: 0, text: "", isFinal: true)]
  }

  var chunks: [PraxisCapabilityGenerationChunkSnapshot] = []
  var currentIndex = text.startIndex
  var chunkIndex = 0
  while currentIndex < text.endIndex {
    let nextIndex = text.index(currentIndex, offsetBy: chunkCharacterCount, limitedBy: text.endIndex) ?? text.endIndex
    let chunkText = String(text[currentIndex..<nextIndex])
    chunks.append(
      .init(
        index: chunkIndex,
        text: chunkText,
        isFinal: nextIndex == text.endIndex
      )
    )
    currentIndex = nextIndex
    chunkIndex += 1
  }
  return chunks
}

private let boundedShellExecutionCapabilityKey = PraxisThinCapabilityKey.shellRun.capabilityID
private let localRuntimeAuditProjectID = "cmp.local-runtime"
private let localRuntimeAuditAgentID = "runtime.local"

private func thinCapabilityManifestIDs(
  providerSurface: (any PraxisProviderRequestSurfaceProtocol)?,
  supportsShellApproval: Bool,
  shellExecutor: (any PraxisShellExecutor)?,
  codeExecutor: (any PraxisCodeExecutor)?,
  codeSandboxDescriber: (any PraxisCodeSandboxDescriber)?,
  supportsCodePatch: Bool,
  browserExecutor: (any PraxisBrowserExecutor)?,
  browserGroundingCollector: (any PraxisBrowserGroundingCollector)?,
  supportsSessionOpen: Bool
) -> Set<PraxisCapabilityID> {
  var capabilityIDs: Set<PraxisCapabilityID> = supportsSessionOpen
    ? [PraxisThinCapabilityKey.sessionOpen.capabilityID]
    : []

  if providerSurface?.supportsInference == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.generateCreate.capabilityID)
    capabilityIDs.insert(PraxisThinCapabilityKey.generateStream.capabilityID)
  }
  if providerSurface?.supportsEmbedding == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.embedCreate.capabilityID)
  }
  if codeExecutor != nil && codeSandboxDescriber != nil {
    capabilityIDs.insert(PraxisThinCapabilityKey.codeRun.capabilityID)
  }
  if supportsCodePatch {
    capabilityIDs.insert(PraxisThinCapabilityKey.codePatch.capabilityID)
  }
  if codeSandboxDescriber != nil {
    capabilityIDs.insert(PraxisThinCapabilityKey.codeSandbox.capabilityID)
  }
  if supportsShellApproval {
    capabilityIDs.insert(PraxisThinCapabilityKey.shellApprove.capabilityID)
  }
  if shellExecutor != nil {
    capabilityIDs.insert(PraxisThinCapabilityKey.shellRun.capabilityID)
  }
  if providerSurface?.supportsSkillRegistry == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.skillList.capabilityID)
  }
  if providerSurface?.supportsSkillRegistry == true,
     providerSurface?.supportsSkillActivation == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.skillActivate.capabilityID)
  }
  if providerSurface?.supportsToolCalls == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.toolCall.capabilityID)
  }
  if providerSurface?.supportsFileUpload == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.fileUpload.capabilityID)
  }
  if providerSurface?.supportsBatchSubmission == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.batchSubmit.capabilityID)
  }
  if providerSurface?.supportsWebSearch == true {
    capabilityIDs.insert(PraxisThinCapabilityKey.searchWeb.capabilityID)
  }
  if browserExecutor != nil {
    capabilityIDs.insert(PraxisThinCapabilityKey.searchFetch.capabilityID)
  }
  if browserGroundingCollector != nil {
    capabilityIDs.insert(PraxisThinCapabilityKey.searchGround.capabilityID)
  }

  return capabilityIDs
}

/// Facade for the Phase 3 thin-capability baseline.
///
/// This surface exposes provider-backed generation, embedding, tool, file, batch, and session
/// calls without leaking composition or transport-specific details to RuntimeKit callers.
public final class PraxisCapabilityFacade: Sendable {
  private let providerSurface: (any PraxisProviderRequestSurfaceProtocol)?
  private let cmpRolesFacade: PraxisCmpRolesFacade?
  private let cmpReadbackFacade: PraxisCmpReadbackFacade?
  private let supportsShellApproval: Bool
  private let shellExecutor: (any PraxisShellExecutor)?
  private let codeExecutor: (any PraxisCodeExecutor)?
  private let codeSandboxDescriber: (any PraxisCodeSandboxDescriber)?
  private let workspaceWriter: (any PraxisWorkspaceWriter)?
  private let supportsCodePatch: Bool
  private let browserExecutor: (any PraxisBrowserExecutor)?
  private let browserGroundingCollector: (any PraxisBrowserGroundingCollector)?
  private let supportsSessionOpen: Bool
  private let sessionRegistry: PraxisSessionRegistry
  private let catalogBuilder: PraxisCapabilityCatalogBuilder
  private let tapRuntimeEventStore: (any PraxisTapRuntimeEventStoreContract)?

  public init(
    dependencies: PraxisDependencyGraph,
    sessionRegistry: PraxisSessionRegistry = .init(),
    catalogBuilder: PraxisCapabilityCatalogBuilder = .init()
  ) {
    self.providerSurface = dependencies.providerRequestSurface
    self.cmpRolesFacade = PraxisCmpRolesFacade(dependencies: dependencies)
    self.cmpReadbackFacade = PraxisCmpReadbackFacade(dependencies: dependencies)
    self.supportsShellApproval = dependencies.hostAdapters.cmpPeerApprovalStore != nil
    self.shellExecutor = dependencies.hostAdapters.shellExecutor
    self.codeExecutor = dependencies.hostAdapters.codeExecutor
    self.codeSandboxDescriber = dependencies.hostAdapters.codeSandboxDescriber
    self.workspaceWriter = dependencies.hostAdapters.workspaceWriter
    self.supportsCodePatch = dependencies.hostAdapters.workspaceWriter?.supportedChangeKinds.contains(.applyPatch) == true
    self.browserExecutor = dependencies.hostAdapters.browserExecutor
    self.browserGroundingCollector = dependencies.hostAdapters.browserGroundingCollector
    self.supportsSessionOpen = true
    self.sessionRegistry = sessionRegistry
    self.catalogBuilder = catalogBuilder
    self.tapRuntimeEventStore = dependencies.hostAdapters.tapRuntimeEventStore
  }

  public static func unsupported() -> PraxisCapabilityFacade {
    PraxisCapabilityFacade(
      providerSurface: nil,
      cmpRolesFacade: nil,
      cmpReadbackFacade: nil,
      supportsShellApproval: false,
      shellExecutor: nil,
      codeExecutor: nil,
      codeSandboxDescriber: nil,
      workspaceWriter: nil,
      supportsCodePatch: false,
      browserExecutor: nil,
      browserGroundingCollector: nil,
      supportsSessionOpen: false
    )
  }

  private init(
    providerSurface: (any PraxisProviderRequestSurfaceProtocol)?,
    cmpRolesFacade: PraxisCmpRolesFacade? = nil,
    cmpReadbackFacade: PraxisCmpReadbackFacade? = nil,
    supportsShellApproval: Bool,
    shellExecutor: (any PraxisShellExecutor)? = nil,
    codeExecutor: (any PraxisCodeExecutor)? = nil,
    codeSandboxDescriber: (any PraxisCodeSandboxDescriber)? = nil,
    workspaceWriter: (any PraxisWorkspaceWriter)? = nil,
    supportsCodePatch: Bool = false,
    browserExecutor: (any PraxisBrowserExecutor)? = nil,
    browserGroundingCollector: (any PraxisBrowserGroundingCollector)? = nil,
    supportsSessionOpen: Bool,
    sessionRegistry: PraxisSessionRegistry = .init(),
    catalogBuilder: PraxisCapabilityCatalogBuilder = .init(),
    tapRuntimeEventStore: (any PraxisTapRuntimeEventStoreContract)? = nil
  ) {
    self.providerSurface = providerSurface
    self.cmpRolesFacade = cmpRolesFacade
    self.cmpReadbackFacade = cmpReadbackFacade
    self.supportsShellApproval = supportsShellApproval
    self.shellExecutor = shellExecutor
    self.codeExecutor = codeExecutor
    self.codeSandboxDescriber = codeSandboxDescriber
    self.workspaceWriter = workspaceWriter
    self.supportsCodePatch = supportsCodePatch
    self.browserExecutor = browserExecutor
    self.browserGroundingCollector = browserGroundingCollector
    self.supportsSessionOpen = supportsSessionOpen
    self.sessionRegistry = sessionRegistry
    self.catalogBuilder = catalogBuilder
    self.tapRuntimeEventStore = tapRuntimeEventStore
  }

  /// Reads the currently available thin-capability catalog snapshot.
  ///
  /// - Returns: Catalog entries currently wired for the active host profile.
  public func catalog() -> PraxisCapabilityCatalogSnapshot {
    guard providerSurface != nil || supportsShellApproval || shellExecutor != nil || codeExecutor != nil || codeSandboxDescriber != nil || browserExecutor != nil || browserGroundingCollector != nil || supportsSessionOpen else {
      return catalogBuilder.buildSnapshot(manifests: [])
    }

    let baseline = catalogBuilder.buildThinCapabilityBaseline()
    let availableIDs = thinCapabilityManifestIDs(
      providerSurface: providerSurface,
      supportsShellApproval: supportsShellApproval,
      shellExecutor: shellExecutor,
      codeExecutor: codeExecutor,
      codeSandboxDescriber: codeSandboxDescriber,
      supportsCodePatch: supportsCodePatch,
      browserExecutor: browserExecutor,
      browserGroundingCollector: browserGroundingCollector,
      supportsSessionOpen: supportsSessionOpen
    )
    let manifests = baseline.manifests.filter { availableIDs.contains($0.id) }
    return catalogBuilder.buildSnapshot(manifests: manifests)
  }

  /// Executes one bounded generation request.
  ///
  /// - Parameter command: The caller-friendly generation command.
  /// - Returns: The normalized generation snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func generate(_ command: PraxisCapabilityGenerateCommand) async throws -> PraxisCapabilityGenerationSnapshot {
    let prompt = try normalizedCapabilityText(command.prompt, fieldName: "prompt")
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsInference },
      errorMessage: "Thin capability \(PraxisThinCapabilityKey.generateCreate.rawValue) requires a provider inference executor."
    )
    let response = try await providerSurface.infer(
      .init(
        systemPrompt: command.systemPrompt,
        prompt: prompt,
        contextSummary: command.contextSummary,
        preferredModel: command.preferredModel,
        temperature: command.temperature,
        requiredCapabilities: command.requiredCapabilityIDs.map(\.rawValue)
      )
    )

    return PraxisCapabilityGenerationSnapshot(
      capabilityID: PraxisThinCapabilityKey.generateCreate.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.generateCreate.rawValue) returned a bounded generation response.",
      outputText: response.output.summary,
      structuredFields: response.output.structuredFields,
      backend: response.receipt.backend,
      providerOperationID: response.receipt.providerOperationID,
      completedAt: response.receipt.completedAt,
      preferredModel: command.preferredModel
    )
  }

  /// Executes one bounded streaming-style generation request.
  ///
  /// - Parameters:
  ///   - command: The caller-friendly generation command.
  ///   - chunkCharacterCount: Maximum number of characters in each projected chunk.
  /// - Returns: The normalized streaming snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func stream(
    _ command: PraxisCapabilityGenerateCommand,
    chunkCharacterCount: Int = 80
  ) async throws -> PraxisCapabilityGenerationStreamSnapshot {
    guard chunkCharacterCount > 0 else {
      throw PraxisError.invalidInput("Thin capability generate.stream requires a positive chunkCharacterCount.")
    }

    let generated = try await generate(command)
    let chunks = chunkedCapabilityText(generated.outputText, chunkCharacterCount: chunkCharacterCount)
    return PraxisCapabilityGenerationStreamSnapshot(
      capabilityID: PraxisThinCapabilityKey.generateStream.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.generateStream.rawValue) projected \(chunks.count) bounded chunk(s).",
      outputText: generated.outputText,
      chunks: chunks,
      backend: generated.backend,
      providerOperationID: generated.providerOperationID,
      completedAt: generated.completedAt,
      preferredModel: generated.preferredModel
    )
  }

  /// Executes one embedding request.
  ///
  /// - Parameter command: The caller-friendly embedding command.
  /// - Returns: The normalized embedding snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func embed(_ command: PraxisCapabilityEmbedCommand) async throws -> PraxisCapabilityEmbeddingSnapshot {
    let content = try normalizedCapabilityText(command.content, fieldName: "content")
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsEmbedding },
      errorMessage: "Thin capability embed.create requires a provider embedding executor."
    )
    let response = try await providerSurface.embed(
      .init(
        content: content,
        preferredModel: command.preferredModel
      )
    )
    return PraxisCapabilityEmbeddingSnapshot(
      capabilityID: PraxisThinCapabilityKey.embedCreate.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.embedCreate.rawValue) created an embedding response with vector length \(response.vectorLength).",
      vectorLength: response.vectorLength,
      preferredModel: response.model ?? command.preferredModel
    )
  }

  /// Executes one bounded code snippet through the current host code lane.
  ///
  /// - Parameter command: The caller-friendly code-run command.
  /// - Returns: The normalized bounded code execution snapshot.
  /// - Throws: Propagates code adapter or validation failures.
  public func runCode(_ command: PraxisCapabilityCodeRunCommand) async throws -> PraxisCapabilityCodeRunSnapshot {
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    let source = try normalizedCapabilityText(command.source, fieldName: "source")
    let workingDirectory = normalizedCapabilityPath(command.workingDirectory)
    let environment = try normalizedCapabilityEnvironment(command.environment)
    if let timeoutSeconds = command.timeoutSeconds, timeoutSeconds <= 0 {
      throw PraxisError.invalidInput("Thin capability code.run requires timeoutSeconds > 0 when provided.")
    }
    guard command.outputMode == .buffered else {
      throw PraxisError.unsupportedOperation(
        "Thin capability code.run currently supports buffered output only."
      )
    }

    let sandbox = try await describeCodeSandbox(
      .init(
        profile: .workspaceWriteLimited,
        workingDirectory: workingDirectory,
        requestedRuntime: command.runtime
      )
    )
    guard sandbox.allowedRuntimes.contains(command.runtime) else {
      throw PraxisError.unsupportedOperation(
        "Thin capability code.run does not allow runtime \(command.runtime.rawValue) under the current code sandbox contract."
      )
    }
    if let workingDirectory,
       !capabilityPathIsContained(workingDirectory, within: sandbox.writableRoots) {
      throw PraxisError.invalidInput(
        "Thin capability code.run requires workingDirectory to stay within the writable code sandbox roots."
      )
    }

    let executor = try requireCodeExecutor()
    let receipt = try await executor.run(
      .init(
        runtime: command.runtime,
        source: source,
        workingDirectory: workingDirectory,
        environment: environment,
        timeoutSeconds: command.timeoutSeconds,
        outputMode: command.outputMode
      )
    )
    let riskLabel = "risky"
    let completionWord = receipt.exitCode == 0 && receipt.terminationReason == .exited
      ? "completed"
      : "finished"
    return PraxisCapabilityCodeRunSnapshot(
      capabilityID: PraxisThinCapabilityKey.codeRun.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.codeRun.rawValue) \(completionWord) bounded \(command.runtime.rawValue) execution for \(summary) with exit code \(receipt.exitCode) under \(riskLabel) side-effect labeling.",
      runtime: receipt.runtime,
      launcher: receipt.launcher,
      workingDirectory: workingDirectory,
      environmentKeys: environment.keys.sorted(),
      outputMode: command.outputMode,
      riskLabel: riskLabel,
      stdout: receipt.stdout,
      stderr: receipt.stderr,
      exitCode: receipt.exitCode,
      durationMilliseconds: receipt.durationMilliseconds,
      terminationReason: receipt.terminationReason,
      outputWasTruncated: receipt.outputWasTruncated
    )
  }

  /// Applies one bounded workspace patch through the current host patch lane.
  ///
  /// - Parameter command: The caller-friendly code-patch command.
  /// - Returns: The normalized bounded code patch snapshot.
  /// - Throws: Propagates workspace writer or validation failures.
  public func patchCode(_ command: PraxisCapabilityCodePatchCommand) async throws -> PraxisCapabilityCodePatchSnapshot {
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    guard !command.changes.isEmpty else {
      throw PraxisError.invalidInput("Thin capability code.patch requires at least one change.")
    }

    let writer = try requireCodePatchWriter()
    let normalizedChanges = try command.changes.map { change in
      PraxisWorkspaceFileChange(
        kind: .applyPatch,
        path: try normalizedCapabilityText(change.path, fieldName: "path"),
        patch: try normalizedCapabilityText(change.patch, fieldName: "patch"),
        expectedRevisionToken: normalizedOptionalCapabilityText(change.expectedRevisionToken)
      )
    }
    let receipt = try await writer.apply(
      .init(
        changes: normalizedChanges,
        changeSummary: summary
      )
    )

    return PraxisCapabilityCodePatchSnapshot(
      capabilityID: PraxisThinCapabilityKey.codePatch.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.codePatch.rawValue) applied \(receipt.appliedChangeCount) bounded workspace patch change(s) for \(summary) under risky side-effect labeling.",
      changedPaths: receipt.changedPaths,
      appliedChangeCount: receipt.appliedChangeCount,
      riskLabel: "risky"
    )
  }

  /// Describes the current bounded code sandbox contract.
  ///
  /// - Parameter command: The caller-friendly code-sandbox command.
  /// - Returns: The normalized bounded code sandbox snapshot.
  /// - Throws: Propagates sandbox-describer or validation failures.
  public func describeCodeSandbox(
    _ command: PraxisCapabilityCodeSandboxCommand = .init()
  ) async throws -> PraxisCapabilityCodeSandboxSnapshot {
    let describer = try requireCodeSandboxDescriber()
    let descriptor = try await describer.describe(
      .init(
        profile: command.profile,
        workingDirectory: normalizedCapabilityPath(command.workingDirectory),
        requestedRuntime: command.requestedRuntime
      )
    )

    return PraxisCapabilityCodeSandboxSnapshot(
      capabilityID: PraxisThinCapabilityKey.codeSandbox.capabilityID,
      summary: descriptor.summary,
      profile: descriptor.profile,
      enforcementMode: descriptor.enforcementMode,
      allowedRuntimes: descriptor.allowedRuntimes,
      readableRoots: descriptor.readableRoots,
      writableRoots: descriptor.writableRoots,
      allowsNetworkAccess: descriptor.allowsNetworkAccess,
      allowsSubprocesses: descriptor.allowsSubprocesses
    )
  }

  /// Requests shell execution approval through the current CMP/TAP review path.
  ///
  /// - Parameter command: The caller-friendly shell-approval command.
  /// - Returns: The normalized shell-approval snapshot.
  /// - Throws: Propagates approval or validation failures.
  public func requestShellApproval(
    _ command: PraxisCapabilityShellApprovalCommand
  ) async throws -> PraxisCapabilityShellApprovalSnapshot {
    let projectID = try normalizedCapabilityText(command.projectID, fieldName: "projectID")
    let agentID = try normalizedCapabilityText(command.agentID, fieldName: "agentID")
    let targetAgentID = try normalizedCapabilityText(command.targetAgentID, fieldName: "targetAgentID")
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    let rolesFacade = try requireCmpRolesFacade()
    let approval = try await rolesFacade.requestPeerApproval(
      .init(
        projectID: projectID,
        agentID: agentID,
        targetAgentID: targetAgentID,
        capabilityKey: boundedShellExecutionCapabilityKey,
        requestedTier: command.requestedTier,
        summary: summary
      )
    )
    return mapShellApprovalSnapshot(approval)
  }

  /// Reads the latest shell execution approval state through the current CMP/TAP recovery path.
  ///
  /// - Parameter command: The caller-friendly shell-approval readback query.
  /// - Returns: The normalized shell-approval readback snapshot.
  /// - Throws: Propagates readback or validation failures.
  public func readbackShellApproval(
    _ command: PraxisCapabilityShellApprovalReadbackCommand
  ) async throws -> PraxisCapabilityShellApprovalReadbackSnapshot {
    let projectID = try normalizedCapabilityText(command.projectID, fieldName: "projectID")
    let readbackFacade = try requireCmpReadbackFacade()
    let readback = try await readbackFacade.readbackPeerApproval(
      .init(
        projectID: projectID,
        agentID: normalizedCapabilityPath(command.agentID),
        targetAgentID: normalizedCapabilityPath(command.targetAgentID),
        capabilityKey: boundedShellExecutionCapabilityKey
      )
    )
    return mapShellApprovalReadbackSnapshot(readback)
  }

  /// Executes one bounded shell command through the current host shell lane.
  ///
  /// - Parameter command: The caller-friendly shell-run command.
  /// - Returns: The normalized bounded shell execution snapshot.
  /// - Throws: Propagates shell adapter or validation failures.
  public func runShell(_ command: PraxisCapabilityShellRunCommand) async throws -> PraxisCapabilityShellRunSnapshot {
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    let shellCommand = try normalizedCapabilityText(command.command, fieldName: "command")
    let environment = try normalizedCapabilityEnvironment(command.environment)
    if let timeoutSeconds = command.timeoutSeconds, timeoutSeconds <= 0 {
      throw PraxisError.invalidInput("Thin capability shell.run requires timeoutSeconds > 0 when provided.")
    }
    guard command.outputMode == .buffered else {
      throw PraxisError.unsupportedOperation(
        "Thin capability shell.run currently supports buffered output only."
      )
    }
    guard !command.requiresPTY else {
      throw PraxisError.unsupportedOperation(
        "Thin capability shell.run does not support PTY execution yet."
      )
    }

    let executor = try requireShellExecutor()
    let receipt = try await executor.run(
      .init(
        command: shellCommand,
        workingDirectory: normalizedCapabilityPath(command.workingDirectory),
        environment: environment,
        timeoutSeconds: command.timeoutSeconds,
        outputMode: command.outputMode,
        requiresPTY: command.requiresPTY
      )
    )
    let riskLabel = "risky"
    let completionWord = receipt.exitCode == 0 && receipt.terminationReason == .exited
      ? "completed"
      : "finished"
    return PraxisCapabilityShellRunSnapshot(
      capabilityID: PraxisThinCapabilityKey.shellRun.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.shellRun.rawValue) \(completionWord) bounded shell execution for \(summary) with exit code \(receipt.exitCode) under \(riskLabel) side-effect labeling.",
      command: shellCommand,
      workingDirectory: normalizedCapabilityPath(command.workingDirectory),
      environmentKeys: environment.keys.sorted(),
      outputMode: command.outputMode,
      requiresPTY: command.requiresPTY,
      riskLabel: riskLabel,
      stdout: receipt.stdout,
      stderr: receipt.stderr,
      exitCode: receipt.exitCode,
      durationMilliseconds: receipt.durationMilliseconds,
      terminationReason: receipt.terminationReason,
      outputWasTruncated: receipt.outputWasTruncated
    )
  }

  /// Lists stable provider skill keys through the aggregated provider skill surface.
  ///
  /// - Parameter command: The caller-friendly list query.
  /// - Returns: The normalized provider-skill list snapshot.
  /// - Throws: Propagates provider failures when the skill registry is unavailable.
  public func listSkills(
    _ command: PraxisCapabilitySkillListCommand = .init()
  ) async throws -> PraxisCapabilitySkillListSnapshot {
    _ = command
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsSkillRegistry },
      errorMessage: "Thin capability skill.list requires a provider skill registry."
    )
    let skillKeys = try await providerSurface.listSkillKeys()
    let normalizedSkillKeys = normalizedCapabilityKeys(skillKeys)
    return PraxisCapabilitySkillListSnapshot(
      capabilityID: PraxisThinCapabilityKey.skillList.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.skillList.rawValue) listed \(normalizedSkillKeys.count) registered provider skill key(s).",
      skillKeys: normalizedSkillKeys
    )
  }

  /// Activates one registered provider skill through the aggregated provider skill surface.
  ///
  /// - Parameter command: The caller-friendly skill activation command.
  /// - Returns: The normalized provider-skill activation snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func activateSkill(
    _ command: PraxisCapabilitySkillActivateCommand
  ) async throws -> PraxisCapabilitySkillActivateSnapshot {
    let skillKey = try normalizedCapabilityText(command.skillKey, fieldName: "skillKey")
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsSkillRegistry && $0.supportsSkillActivation },
      errorMessage: "Thin capability skill.activate requires a provider skill registry and activator."
    )
    let availableSkillKeys = Set(normalizedCapabilityKeys(try await providerSurface.listSkillKeys()))
    guard availableSkillKeys.contains(skillKey) else {
      throw PraxisError.unsupportedOperation(
        "Thin capability skill.activate does not allow unregistered provider skill key \(skillKey)."
      )
    }
    let receipt = try await providerSurface.activate(
      .init(
        skillKey: skillKey,
        reason: command.reason?.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    )
    if receipt.activated {
      try await appendCapabilityAuditEvent(
        eventKind: .providerSkillActivated,
        capabilityID: PraxisThinCapabilityKey.skillActivate.capabilityID,
        summary: "Activated provider skill \(receipt.skillKey).",
        detail: "Thin capability \(PraxisThinCapabilityKey.skillActivate.rawValue) activated provider skill \(receipt.skillKey).",
        metadata: [
          "capabilityKey": .string(PraxisThinCapabilityKey.skillActivate.rawValue),
          "skillKey": .string(receipt.skillKey),
          "requestedTier": .string(PraxisTapCapabilityTier.b0.rawValue),
          "route": .string("autoApprove"),
          "outcome": .string("baseline_approved"),
          "humanGateState": .string(PraxisHumanGateState.notRequired.rawValue),
          "decisionSummary": .string("Activated provider skill \(receipt.skillKey)."),
        ]
      )
    }
    return PraxisCapabilitySkillActivateSnapshot(
      capabilityID: PraxisThinCapabilityKey.skillActivate.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.skillActivate.rawValue) attempted provider skill activation for \(receipt.skillKey).",
      skillKey: receipt.skillKey,
      activated: receipt.activated
    )
  }

  /// Lists registered provider MCP tool names through the aggregated provider MCP-tool surface.
  ///
  /// - Parameter command: The caller-friendly list query.
  /// - Returns: The normalized provider MCP-tool list snapshot.
  /// - Throws: Propagates provider failures when the MCP tool registry is unavailable.
  public func listProviderMCPTools(
    _ command: PraxisCapabilityProviderMCPToolListCommand = .init()
  ) async throws -> PraxisCapabilityProviderMCPToolListSnapshot {
    _ = command
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsMCPToolRegistry },
      errorMessage: "Thin capability provider.mcp.list requires a provider MCP tool registry."
    )
    let toolNames = normalizedCapabilityKeys(try await providerSurface.listToolNames())
    return PraxisCapabilityProviderMCPToolListSnapshot(
      capabilityID: PraxisThinCapabilityKey.toolCall.capabilityID,
      summary: "Provider MCP tool registry listed \(toolNames.count) registered tool name(s).",
      toolNames: toolNames
    )
  }

  /// Executes one tool call through the MCP-backed tool lane.
  ///
  /// - Parameter command: The caller-friendly tool-call command.
  /// - Returns: The normalized tool-call snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func callTool(_ command: PraxisCapabilityToolCallCommand) async throws -> PraxisCapabilityToolCallSnapshot {
    let toolName = try normalizedCapabilityText(command.toolName, fieldName: "toolName")
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsToolCalls && $0.supportsMCPToolRegistry },
      errorMessage: "Thin capability tool.call requires a provider MCP tool registry and executor."
    )
    let registeredToolNames = Set(normalizedCapabilityKeys(try await providerSurface.listToolNames()))
    guard registeredToolNames.contains(toolName) else {
      throw PraxisError.unsupportedOperation(
        "Thin capability tool.call does not allow unregistered provider MCP tool \(toolName)."
      )
    }
    let receipt = try await providerSurface.callTool(
      .init(
        toolName: toolName,
        summary: summary,
        serverName: command.serverName?.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    )
    if receipt.status == .succeeded {
      try await appendCapabilityAuditEvent(
        eventKind: .providerMCPToolCalled,
        capabilityID: PraxisThinCapabilityKey.toolCall.capabilityID,
        summary: "Called provider MCP tool \(receipt.toolName).",
        detail: "Thin capability \(PraxisThinCapabilityKey.toolCall.rawValue) called provider MCP tool \(receipt.toolName).",
        metadata: [
          "capabilityKey": .string(PraxisThinCapabilityKey.toolCall.rawValue),
          "toolName": .string(receipt.toolName),
          "requestedTier": .string(PraxisTapCapabilityTier.b0.rawValue),
          "route": .string("autoApprove"),
          "outcome": .string("baseline_approved"),
          "humanGateState": .string(PraxisHumanGateState.notRequired.rawValue),
          "decisionSummary": .string("Called provider MCP tool \(receipt.toolName)."),
        ]
      )
    }
    return PraxisCapabilityToolCallSnapshot(
      capabilityID: PraxisThinCapabilityKey.toolCall.capabilityID,
      toolName: receipt.toolName,
      status: receipt.status,
      summary: receipt.summary
    )
  }

  /// Uploads one provider file payload.
  ///
  /// - Parameter command: The caller-friendly file-upload command.
  /// - Returns: The normalized file-upload snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func uploadFile(_ command: PraxisCapabilityFileUploadCommand) async throws -> PraxisCapabilityFileUploadSnapshot {
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsFileUpload },
      errorMessage: "Thin capability file.upload requires a provider file store."
    )
    let receipt = try await providerSurface.upload(
      .init(
        summary: summary,
        purpose: command.purpose?.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    )
    return PraxisCapabilityFileUploadSnapshot(
      capabilityID: PraxisThinCapabilityKey.fileUpload.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.fileUpload.rawValue) uploaded one provider file payload.",
      fileID: receipt.fileID,
      backend: receipt.backend
    )
  }

  /// Submits one provider batch workload.
  ///
  /// - Parameter command: The caller-friendly batch-submit command.
  /// - Returns: The normalized batch-submit snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func submitBatch(_ command: PraxisCapabilityBatchSubmitCommand) async throws -> PraxisCapabilityBatchSubmitSnapshot {
    let summary = try normalizedCapabilityText(command.summary, fieldName: "summary")
    guard command.itemCount > 0 else {
      throw PraxisError.invalidInput("Thin capability batch.submit requires itemCount > 0.")
    }
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsBatchSubmission },
      errorMessage: "Thin capability batch.submit requires a provider batch executor."
    )
    let receipt = try await providerSurface.enqueue(
      .init(
        summary: summary,
        itemCount: command.itemCount
      )
    )
    return PraxisCapabilityBatchSubmitSnapshot(
      capabilityID: PraxisThinCapabilityKey.batchSubmit.capabilityID,
      summary: "Thin capability \(PraxisThinCapabilityKey.batchSubmit.rawValue) enqueued \(command.itemCount) batch item(s).",
      batchID: receipt.batchID,
      backend: receipt.backend
    )
  }

  /// Opens one runtime session header for repeated caller workflows.
  ///
  /// - Parameter command: The caller-friendly session-open command.
  /// - Returns: The normalized session snapshot.
  /// - Throws: Propagates validation failures.
  public func openSession(_ command: PraxisOpenRuntimeSessionCommand = .init()) async throws -> PraxisRuntimeSessionSnapshot {
    guard supportsSessionOpen else {
      throw PraxisError.unsupportedOperation("Thin capability session.open is not available in this facade profile.")
    }

    let rawSessionID = command.sessionID?.trimmingCharacters(in: .whitespacesAndNewlines)
    let sessionID = PraxisSessionID(
      rawValue: (rawSessionID?.isEmpty == false ? rawSessionID : "runtime.session.\(UUID().uuidString.lowercased())")!
    )
    let rawTitle = command.title?.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = rawTitle?.isEmpty == false ? rawTitle! : "Runtime Session \(sessionID.rawValue)"
    let metadata: [String: PraxisValue] = [
      "openedBy": .string("PraxisCapabilityFacade"),
      "capabilityID": .string(PraxisThinCapabilityKey.sessionOpen.rawValue),
    ]
    let header = await sessionRegistry.create(
      id: sessionID,
      title: title,
      metadata: metadata
    )
    return PraxisRuntimeSessionSnapshot(
      capabilityID: PraxisThinCapabilityKey.sessionOpen.capabilityID,
      sessionID: header.id,
      title: header.title,
      temperature: header.temperature,
      summary: "Thin capability \(PraxisThinCapabilityKey.sessionOpen.rawValue) opened runtime session \(header.id.rawValue)."
    )
  }

  /// Executes one web search request.
  ///
  /// - Parameter command: The caller-friendly web-search command.
  /// - Returns: The normalized web-search snapshot.
  /// - Throws: Propagates provider or validation failures.
  public func searchWeb(_ command: PraxisCapabilitySearchWebCommand) async throws -> PraxisCapabilitySearchWebSnapshot {
    let query = try normalizedCapabilityText(command.query, fieldName: "query")
    guard command.limit > 0 else {
      throw PraxisError.invalidInput("Thin capability search.web requires limit > 0.")
    }
    let providerSurface = try requireProviderSurface(
      isSupported: { $0.supportsWebSearch },
      errorMessage: "Thin capability search.web requires a provider web search executor."
    )
    let response = try await providerSurface.search(
      .init(
        query: query,
        locale: command.locale?.trimmingCharacters(in: .whitespacesAndNewlines),
        preferredDomains: command.preferredDomains.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
        limit: command.limit
      )
    )
    return PraxisCapabilitySearchWebSnapshot(
      capabilityID: PraxisThinCapabilityKey.searchWeb.capabilityID,
      query: response.query,
      summary: response.summary ?? "Thin capability \(PraxisThinCapabilityKey.searchWeb.rawValue) returned \(response.results.count) result(s).",
      provider: response.provider,
      results: response.results.map {
        .init(
          title: $0.title,
          snippet: $0.snippet,
          url: $0.url,
          source: $0.source
        )
      }
    )
  }

  /// Executes one fetch request for a candidate URL.
  ///
  /// - Parameter command: The caller-friendly fetch command.
  /// - Returns: The normalized fetch snapshot.
  /// - Throws: Propagates browser or validation failures.
  public func fetchSearchResult(_ command: PraxisCapabilitySearchFetchCommand) async throws -> PraxisCapabilitySearchFetchSnapshot {
    let url = try normalizedCapabilityText(command.url, fieldName: "url")
    let executor = try requireBrowserExecutor()
    let receipt = try await executor.navigate(
      .init(
        url: url,
        waitPolicy: command.waitPolicy,
        timeoutSeconds: command.timeoutSeconds,
        preferredTitle: command.preferredTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
        captureSnapshot: command.captureSnapshot
      )
    )
    return PraxisCapabilitySearchFetchSnapshot(
      capabilityID: PraxisThinCapabilityKey.searchFetch.capabilityID,
      requestedURL: receipt.requestedURL,
      finalURL: receipt.finalURL,
      title: receipt.title,
      snapshotPath: receipt.snapshotPath,
      summary: "Thin capability \(PraxisThinCapabilityKey.searchFetch.rawValue) fetched candidate page \(receipt.finalURL)."
    )
  }

  /// Collects grounded evidence for one candidate URL.
  ///
  /// - Parameter command: The caller-friendly grounding command.
  /// - Returns: The normalized grounded evidence snapshot.
  /// - Throws: Propagates collector or validation failures.
  public func groundSearchResult(_ command: PraxisCapabilitySearchGroundCommand) async throws -> PraxisCapabilitySearchGroundSnapshot {
    let taskSummary = try normalizedCapabilityText(command.taskSummary, fieldName: "taskSummary")
    guard command.maxPages > 0 else {
      throw PraxisError.invalidInput("Thin capability search.ground requires maxPages > 0.")
    }
    let collector = try requireBrowserGroundingCollector()
    let bundle = try await collector.collectEvidence(
      .init(
        taskSummary: taskSummary,
        exampleURL: command.exampleURL?.trimmingCharacters(in: .whitespacesAndNewlines),
        requestedFacts: command.requestedFacts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
        locale: command.locale?.trimmingCharacters(in: .whitespacesAndNewlines),
        maxPages: command.maxPages
      )
    )
    let summary: String
    if let blockedReason = bundle.blockedReason {
      summary = "Thin capability \(PraxisThinCapabilityKey.searchGround.rawValue) returned blocked grounding evidence: \(blockedReason)"
    } else {
      summary = "Thin capability \(PraxisThinCapabilityKey.searchGround.rawValue) collected \(bundle.pages.count) page(s) and \(bundle.facts.count) fact(s)."
    }
    return PraxisCapabilitySearchGroundSnapshot(
      capabilityID: PraxisThinCapabilityKey.searchGround.capabilityID,
      summary: summary,
      pages: bundle.pages.map(PraxisCapabilityGroundedPageSnapshot.init(page:)),
      facts: bundle.facts.map(PraxisCapabilityGroundedFactSnapshot.init(fact:)),
      generatedAt: bundle.generatedAt,
      blockedReason: bundle.blockedReason
    )
  }

  private func requireProviderSurface(
    isSupported: @Sendable (any PraxisProviderRequestSurfaceProtocol) -> Bool,
    errorMessage: String
  ) throws -> any PraxisProviderRequestSurfaceProtocol {
    guard let providerSurface, isSupported(providerSurface) else {
      throw PraxisError.dependencyMissing(errorMessage)
    }
    return providerSurface
  }

  private func normalizedCapabilityKeys(_ values: [String]) -> [String] {
    Array(
      Set(
        values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }
      )
    ).sorted()
  }

  private func appendCapabilityAuditEvent(
    eventKind: PraxisTapRuntimeEventKind,
    capabilityID: PraxisCapabilityID,
    summary: String,
    detail: String,
    metadata: [String: PraxisValue]
  ) async throws {
    guard let tapRuntimeEventStore else {
      return
    }
    _ = try await tapRuntimeEventStore.append(
      .init(
        eventID: "tap.\(eventKind.rawValue).\(UUID().uuidString.lowercased())",
        projectID: localRuntimeAuditProjectID,
        agentID: localRuntimeAuditAgentID,
        targetAgentID: localRuntimeAuditAgentID,
        eventKind: eventKind,
        capabilityKey: capabilityID.rawValue,
        summary: summary,
        detail: detail,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        metadata: metadata
      )
    )
  }

  private func requireCmpRolesFacade() throws -> PraxisCmpRolesFacade {
    guard let cmpRolesFacade, supportsShellApproval else {
      throw PraxisError.dependencyMissing("Thin capability shell.approve requires the CMP approval path.")
    }
    return cmpRolesFacade
  }

  private func requireCmpReadbackFacade() throws -> PraxisCmpReadbackFacade {
    guard let cmpReadbackFacade, supportsShellApproval else {
      throw PraxisError.dependencyMissing("Thin capability shell.approve readback requires the CMP approval path.")
    }
    return cmpReadbackFacade
  }

  private func requireShellExecutor() throws -> any PraxisShellExecutor {
    guard let shellExecutor else {
      throw PraxisError.dependencyMissing("Thin capability shell.run requires a shell executor.")
    }
    return shellExecutor
  }

  private func requireCodeExecutor() throws -> any PraxisCodeExecutor {
    guard let codeExecutor else {
      throw PraxisError.dependencyMissing("Thin capability code.run requires a code executor.")
    }
    return codeExecutor
  }

  private func requireCodePatchWriter() throws -> any PraxisWorkspaceWriter {
    guard let workspaceWriter, supportsCodePatch else {
      throw PraxisError.dependencyMissing("Thin capability code.patch requires a workspace writer with applyPatch support.")
    }
    return workspaceWriter
  }

  private func requireCodeSandboxDescriber() throws -> any PraxisCodeSandboxDescriber {
    guard let codeSandboxDescriber else {
      throw PraxisError.dependencyMissing("Thin capability code.sandbox requires a code sandbox describer.")
    }
    return codeSandboxDescriber
  }

  private func requireBrowserExecutor() throws -> any PraxisBrowserExecutor {
    guard let browserExecutor else {
      throw PraxisError.dependencyMissing("Thin capability search.fetch requires a browser executor.")
    }
    return browserExecutor
  }

  private func requireBrowserGroundingCollector() throws -> any PraxisBrowserGroundingCollector {
    guard let browserGroundingCollector else {
      throw PraxisError.dependencyMissing("Thin capability search.ground requires a browser grounding collector.")
    }
    return browserGroundingCollector
  }
}

private func mapShellApprovalSnapshot(
  _ approval: PraxisCmpPeerApprovalSnapshot
) -> PraxisCapabilityShellApprovalSnapshot {
  PraxisCapabilityShellApprovalSnapshot(
    capabilityID: PraxisThinCapabilityKey.shellApprove.capabilityID,
    approvedCapabilityID: PraxisThinCapabilityKey.shellRun.capabilityID,
    summary: approval.summary,
    projectID: approval.projectID,
    agentID: approval.agentID,
    targetAgentID: approval.targetAgentID,
    requestedTier: approval.requestedTier,
    route: approval.route.rawValue,
    outcome: approval.outcome.rawValue,
    tapMode: approval.tapMode.rawValue,
    riskLevel: approval.riskLevel.rawValue,
    humanGateState: approval.humanGateState.rawValue,
    requestedAt: approval.requestedAt,
    decisionSummary: approval.decisionSummary
  )
}

private func mapShellApprovalReadbackSnapshot(
  _ readback: PraxisCmpPeerApprovalReadbackSnapshot
) -> PraxisCapabilityShellApprovalReadbackSnapshot {
  PraxisCapabilityShellApprovalReadbackSnapshot(
    capabilityID: PraxisThinCapabilityKey.shellApprove.capabilityID,
    approvedCapabilityID: readback.found ? PraxisThinCapabilityKey.shellRun.capabilityID : nil,
    summary: readback.summary,
    projectID: readback.projectID,
    agentID: readback.agentID,
    targetAgentID: readback.targetAgentID,
    requestedTier: readback.requestedTier,
    route: readback.route?.rawValue,
    outcome: readback.outcome?.rawValue,
    tapMode: readback.tapMode?.rawValue,
    riskLevel: readback.riskLevel?.rawValue,
    humanGateState: readback.humanGateState?.rawValue,
    requestedAt: readback.requestedAt,
    decisionSummary: readback.decisionSummary,
    found: readback.found
  )
}
