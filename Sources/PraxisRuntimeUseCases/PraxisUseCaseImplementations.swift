import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCheckpoint
import PraxisCmpDelivery
import PraxisCmpDbModel
import PraxisCmpFiveAgent
import PraxisCmpGitModel
import PraxisCmpMqModel
import PraxisCmpProjection
import PraxisCmpSections
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisInfraContracts
import PraxisJournal
import PraxisRuntimeComposition
import PraxisRun
import PraxisSession
import PraxisState
import PraxisToolingContracts
import PraxisTapGovernance
import PraxisTapReview
import PraxisTapRuntime
import PraxisTapTypes
import PraxisTransition
import Foundation

private let tapInspectionSessionID = PraxisSessionID(rawValue: "tap.session.snapshot")
private let tapInspectionCheckpointPointer = PraxisCheckpointPointer(
  checkpointID: PraxisCheckpointID(rawValue: "tap.checkpoint.snapshot"),
  sessionID: tapInspectionSessionID
)
private let checkpointReplayPageSize = 50
private let runIdentityCodec = PraxisRunIdentityCodec()
private let cmpLocalRuntimeProjectID = "cmp.local-runtime"
private let cmpLocalRuntimeDeliveryTopic = "cmp.delivery"

private struct PraxisContractBackedJournalReader: PraxisJournalReading {
  let store: any PraxisJournalStoreContract

  func read(after cursor: PraxisJournalCursor?, limit: Int?) async throws -> PraxisJournalSlice {
    throw PraxisError.unsupportedOperation("Global journal reads are not used by HostRuntime checkpoint recovery.")
  }

  func read(
    sessionID: PraxisSessionID,
    after cursor: PraxisJournalCursor?,
    limit: Int?
  ) async throws -> PraxisJournalSlice {
    if let limit {
      return try await store.read(
        .init(
          sessionID: sessionID.rawValue,
          afterCursor: cursor,
          limit: limit
        )
      )
    }

    var replayedEvents: [PraxisJournalEvent] = []
    var nextCursor = cursor

    while true {
      let slice = try await store.read(
        .init(
          sessionID: sessionID.rawValue,
          afterCursor: nextCursor,
          limit: checkpointReplayPageSize
        )
      )
      guard !slice.events.isEmpty else {
        return PraxisJournalSlice(
          events: replayedEvents,
          nextCursor: replayedEvents.last.map { PraxisJournalCursor(sequence: $0.sequence) }
        )
      }

      replayedEvents.append(contentsOf: slice.events)
      nextCursor = slice.nextCursor

      if slice.events.count < checkpointReplayPageSize {
        return PraxisJournalSlice(events: replayedEvents, nextCursor: nextCursor)
      }
    }
  }

  func read(
    runReference: String,
    after cursor: PraxisJournalCursor?,
    limit: Int?
  ) async throws -> PraxisJournalSlice {
    throw PraxisError.unsupportedOperation("Run-only journal reads are not used by HostRuntime checkpoint recovery.")
  }

  func latestEvent(runReference: String) async -> PraxisJournalEvent? {
    nil
  }
}

private func runtimeNow() -> String {
  ISO8601DateFormatter().string(from: Date())
}

private func defaultSessionID(for goalID: String) -> PraxisSessionID {
  .init(rawValue: runIdentityCodec.makeDefaultSessionRawValue(for: goalID))
}

private func sessionIDCandidates(from runID: PraxisRunID) -> [PraxisSessionID] {
  runIdentityCodec.sessionRawValueCandidates(from: runID).map(PraxisSessionID.init(rawValue:))
}

private func runID(for sessionID: PraxisSessionID, goalID: String) -> PraxisRunID {
  runIdentityCodec.makeRunID(sessionRawValue: sessionID.rawValue, goalID: goalID)
}

private func sessionID(from runID: PraxisRunID) -> PraxisSessionID {
  .init(rawValue: runIdentityCodec.sessionRawValue(from: runID))
}

private func checkpointPointer(for runID: PraxisRunID, sessionID: PraxisSessionID) -> PraxisCheckpointPointer {
  .init(
    checkpointID: .init(rawValue: "checkpoint.\(runID.rawValue)"),
    sessionID: sessionID
  )
}

private func journalSummary(for payload: PraxisKernelEventPayload) -> String {
  switch payload {
  case .runCreated(let goalID):
    return "Run created for goal \(goalID)"
  case .runResumed(let checkpointID):
    return "Run resumed from checkpoint \(checkpointID ?? "none")"
  case .runPaused(let reason):
    return "Run paused: \(reason)"
  case .runCompleted(let resultID):
    return "Run completed with result \(resultID ?? "none")"
  case .runFailed(let code, let message):
    return "Run failed (\(code)): \(message)"
  case .stateDeltaApplied(_, let previousStatus, let nextStatus):
    return "State delta applied from \(previousStatus?.rawValue ?? "unknown") to \(nextStatus?.rawValue ?? "unknown")"
  case .intentQueued(let intentID, let kind, _):
    return "Intent \(intentID) queued for \(kind)"
  case .intentDispatched(let intentID, let dispatchTarget):
    return "Intent \(intentID) dispatched to \(dispatchTarget)"
  case .capabilityResultReceived(_, let resultID, let status):
    return "Capability result \(resultID) received with status \(status)"
  case .checkpointCreated(let checkpointID, let tier):
    return "Checkpoint \(checkpointID) created in \(tier) tier"
  }
}

private func journalMetadata(for payload: PraxisKernelEventPayload) -> [String: PraxisValue] {
  switch payload {
  case .runCreated(let goalID):
    return ["goalID": .string(goalID)]
  case .runResumed(let checkpointID):
    return ["checkpointID": checkpointID.map { PraxisValue.string($0) } ?? .null]
  case .runPaused(let reason):
    return ["reason": .string(reason)]
  case .runCompleted(let resultID):
    return ["resultID": resultID.map { PraxisValue.string($0) } ?? .null]
  case .runFailed(let code, let message):
    return ["code": .string(code), "message": .string(message)]
  case .stateDeltaApplied(let delta, let previousStatus, let nextStatus):
    var metadata: [String: PraxisValue] = [
      "previousStatus": previousStatus.map { .string($0.rawValue) } ?? .null,
      "nextStatus": nextStatus.map { .string($0.rawValue) } ?? .null,
    ]
    if let deltaJSON = try? encodeJSONString(delta) {
      metadata["deltaJSON"] = .string(deltaJSON)
    }
    return metadata
  case .intentQueued(let intentID, let kind, let priority):
    return ["intentID": .string(intentID), "kind": .string(kind), "priority": .string(priority)]
  case .intentDispatched(let intentID, let dispatchTarget):
    return ["intentID": .string(intentID), "dispatchTarget": .string(dispatchTarget)]
  case .capabilityResultReceived(let requestID, let resultID, let status):
    return ["requestID": .string(requestID), "resultID": .string(resultID), "status": .string(status)]
  case .checkpointCreated(let checkpointID, let tier):
    return ["checkpointID": .string(checkpointID), "tier": .string(tier)]
  }
}

private func makeJournalEvent(from kernelEvent: PraxisKernelEvent) -> PraxisJournalEvent {
  var metadata = kernelEvent.metadata ?? [:]
  metadata["kernelEventType"] = .string(kernelEvent.type.rawValue)
  metadata["kernelEventID"] = .string(kernelEvent.eventID)
  metadata["createdAt"] = .string(kernelEvent.createdAt)
  for (key, value) in journalMetadata(for: kernelEvent.payload) {
    metadata[key] = value
  }

  return PraxisJournalEvent(
    sequence: 0,
    sessionID: .init(rawValue: kernelEvent.sessionID),
    runReference: kernelEvent.runID,
    correlationID: kernelEvent.correlationID,
    type: kernelEvent.type.rawValue,
    summary: journalSummary(for: kernelEvent.payload),
    metadata: metadata
  )
}

private func status(from rawValue: String?) -> PraxisAgentStatus? {
  guard let rawValue else {
    return nil
  }
  return PraxisAgentStatus(rawValue: rawValue)
}

private func kernelEvent(from journalEvent: PraxisJournalEvent) throws -> PraxisKernelEvent? {
  let metadata = journalEvent.metadata ?? [:]
  guard let typeRawValue = metadata["kernelEventType"]?.stringValue ?? journalEvent.type,
        let eventType = PraxisKernelEventType(rawValue: typeRawValue),
        let runID = journalEvent.runReference else {
    return nil
  }

  let payload: PraxisKernelEventPayload
  switch eventType {
  case .runCreated:
    guard let goalID = metadata["goalID"]?.stringValue else {
      return nil
    }
    payload = .runCreated(goalID: goalID)
  case .runResumed:
    payload = .runResumed(checkpointID: metadata["checkpointID"]?.stringValue)
  case .runPaused:
    guard let reason = metadata["reason"]?.stringValue else {
      return nil
    }
    payload = .runPaused(reason: reason)
  case .runCompleted:
    payload = .runCompleted(resultID: metadata["resultID"]?.stringValue)
  case .runFailed:
    guard let code = metadata["code"]?.stringValue,
          let message = metadata["message"]?.stringValue else {
      return nil
    }
    payload = .runFailed(code: code, message: message)
  case .stateDeltaApplied:
    guard let deltaJSON = metadata["deltaJSON"]?.stringValue else {
      return nil
    }
    let delta = try decodeJSONString(PraxisStateDelta.self, from: ["deltaJSON": .string(deltaJSON)], key: "deltaJSON")
    guard let delta else {
      return nil
    }
    payload = .stateDeltaApplied(
      delta: delta,
      previousStatus: status(from: metadata["previousStatus"]?.stringValue),
      nextStatus: status(from: metadata["nextStatus"]?.stringValue)
    )
  case .intentQueued:
    guard let intentID = metadata["intentID"]?.stringValue,
          let kind = metadata["kind"]?.stringValue,
          let priority = metadata["priority"]?.stringValue else {
      return nil
    }
    payload = .intentQueued(intentID: intentID, kind: kind, priority: priority)
  case .intentDispatched:
    guard let intentID = metadata["intentID"]?.stringValue,
          let dispatchTarget = metadata["dispatchTarget"]?.stringValue else {
      return nil
    }
    payload = .intentDispatched(intentID: intentID, dispatchTarget: dispatchTarget)
  case .capabilityResultReceived:
    guard let requestID = metadata["requestID"]?.stringValue,
          let resultID = metadata["resultID"]?.stringValue,
          let status = metadata["status"]?.stringValue else {
      return nil
    }
    payload = .capabilityResultReceived(requestID: requestID, resultID: resultID, status: status)
  case .checkpointCreated:
    guard let checkpointID = metadata["checkpointID"]?.stringValue,
          let tier = metadata["tier"]?.stringValue else {
      return nil
    }
    payload = .checkpointCreated(checkpointID: checkpointID, tier: tier)
  }

  return PraxisKernelEvent(
    eventID: metadata["kernelEventID"]?.stringValue ?? "evt.replayed.\(journalEvent.sequence)",
    sessionID: journalEvent.sessionID.rawValue,
    runID: runID,
    createdAt: metadata["createdAt"]?.stringValue ?? runtimeNow(),
    correlationID: journalEvent.correlationID,
    payload: payload,
    metadata: metadata
  )
}

private func encodeJSONString<T: Codable>(_ value: T) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  guard let string = String(data: try encoder.encode(value), encoding: .utf8) else {
    throw PraxisError.invariantViolation("Failed to encode runtime payload as UTF-8 JSON.")
  }
  return string
}

private func decodeJSONString<T: Codable>(_ type: T.Type, from payload: [String: PraxisValue]?, key: String) throws -> T? {
  guard let string = payload?[key]?.stringValue else {
    return nil
  }
  guard let data = string.data(using: String.Encoding.utf8) else {
    throw PraxisError.invalidInput("Runtime payload \(key) is not valid UTF-8 JSON.")
  }
  return try JSONDecoder().decode(type, from: data)
}

private func checkpointPayload(
  runAggregate: PraxisRunAggregate,
  sessionHeader: PraxisSessionHeader,
  goalTitle: String
) throws -> [String: PraxisValue] {
  [
    "runAggregateJSON": .string(try encodeJSONString(runAggregate)),
    "sessionHeaderJSON": .string(try encodeJSONString(sessionHeader)),
    "goalTitle": .string(goalTitle),
  ]
}

private func runPhase(for status: PraxisAgentStatus) -> PraxisRunPhase {
  switch status {
  case .created:
    return .created
  case .idle, .deciding:
    return .queued
  case .acting, .waiting:
    return .running
  case .paused:
    return .paused
  case .completed:
    return .completed
  case .failed:
    return .failed
  case .cancelled:
    return .cancelled
  }
}

private func runFailure(from state: PraxisStateSnapshot) -> PraxisRunFailure? {
  guard state.control.status == .failed else {
    return nil
  }
  return .init(
    summary: state.recovery.lastErrorMessage ?? "Run failed.",
    code: state.recovery.lastErrorCode
  )
}

private func normalizedRunForResume(
  _ restoredRun: PraxisRunAggregate,
  checkpointID: String
) -> PraxisRunAggregate {
  switch restoredRun.latestState.control.status {
  case .paused, .waiting, .failed:
    return restoredRun
  default:
    let normalizedState = PraxisStateSnapshot(
      control: .init(
        status: .paused,
        phase: .recovery,
        retryCount: restoredRun.latestState.control.retryCount,
        pendingIntentID: restoredRun.latestState.control.pendingIntentID,
        pendingCheckpointReason: restoredRun.latestState.control.pendingCheckpointReason
      ),
      working: restoredRun.latestState.working,
      observed: restoredRun.latestState.observed,
      recovery: .init(
        lastCheckpointRef: checkpointID,
        resumePointer: restoredRun.latestState.recovery.resumePointer,
        lastErrorCode: restoredRun.latestState.recovery.lastErrorCode,
        lastErrorMessage: restoredRun.latestState.recovery.lastErrorMessage
      ),
      derived: restoredRun.latestState.derived
    )
    return PraxisRunAggregate(
      id: restoredRun.id,
      phase: .paused,
      tickCount: restoredRun.tickCount,
      lastEventID: restoredRun.lastEventID,
      pendingIntentID: restoredRun.pendingIntentID,
      lastCheckpointReference: checkpointID,
      failure: restoredRun.failure,
      latestState: normalizedState
    )
  }
}

private func persistFollowUpIntent(
  on run: PraxisRunAggregate,
  intentID: String?
) -> PraxisRunAggregate {
  guard let intentID else {
    return run
  }

  let updatedState = PraxisStateSnapshot(
    control: .init(
      status: run.latestState.control.status,
      phase: run.latestState.control.phase,
      retryCount: run.latestState.control.retryCount,
      pendingIntentID: intentID,
      pendingCheckpointReason: run.latestState.control.pendingCheckpointReason
    ),
    working: run.latestState.working,
    observed: run.latestState.observed,
    recovery: run.latestState.recovery,
    derived: run.latestState.derived
  )

  return PraxisRunAggregate(
    id: run.id,
    phase: run.phase,
    tickCount: run.tickCount,
    lastEventID: run.lastEventID,
    pendingIntentID: intentID,
    lastCheckpointReference: run.lastCheckpointReference,
    failure: run.failure,
    latestState: updatedState
  )
}

private func replayRecoveredEvents(
  from recovery: PraxisRecoveryEnvelope?,
  onto restoredRun: PraxisRunAggregate,
  lifecycle: PraxisRunLifecycleService
) throws -> PraxisRunAggregate {
  guard let recovery else {
    return restoredRun
  }

  return try recovery.replayedEvents.reduce(restoredRun) { currentRun, journalEvent in
    guard journalEvent.runReference == currentRun.id.rawValue,
          let kernelEvent = try kernelEvent(from: journalEvent) else {
      return currentRun
    }
    return try lifecycle.advance(currentRun, with: kernelEvent).run
  }
}

private func shouldIssueResumeEvent(for run: PraxisRunAggregate) -> Bool {
  switch run.latestState.control.status {
  case .completed, .cancelled:
    return false
  case .created, .idle, .deciding, .acting, .waiting, .paused, .failed:
    return true
  }
}

private func runFollowUpAction(from decision: PraxisNextActionDecision?) -> PraxisRunFollowUpAction? {
  guard let decision else {
    return nil
  }
  return PraxisRunFollowUpAction(
    kind: decision.kind,
    reason: decision.reason,
    intentID: decision.intent?.intentID,
    intentKind: decision.intent?.kind
  )
}

private func buildCapabilityCatalogSummary(from dependencies: PraxisDependencyGraph) -> String {
  let boundaryNames = dependencies.boundaries.map(\.name).joined(separator: ", ")
  let hostSurfaceSummary = summarizeRegisteredHostSurfaces(from: dependencies)
  return "Capability catalog assembled from current boundaries: \(boundaryNames). \(hostSurfaceSummary)"
}

private func hostCapabilityIDs(from dependencies: PraxisDependencyGraph) -> [PraxisCapabilityID] {
  var capabilityIDs: [PraxisCapabilityID] = []
  let adapters = dependencies.hostAdapters

  if adapters.workspaceReader != nil {
    capabilityIDs.append(.init(rawValue: "workspace.read"))
  }
  if adapters.workspaceSearcher != nil {
    capabilityIDs.append(.init(rawValue: "workspace.search"))
  }
  if adapters.workspaceWriter != nil {
    capabilityIDs.append(.init(rawValue: "workspace.write"))
  }
  if adapters.shellExecutor != nil {
    capabilityIDs.append(.init(rawValue: "tool.shell"))
  }
  if adapters.browserExecutor != nil {
    capabilityIDs.append(.init(rawValue: "tool.browser"))
  }
  if adapters.providerInferenceExecutor != nil {
    capabilityIDs.append(.init(rawValue: "provider.infer"))
  }
  if adapters.providerMCPExecutor != nil {
    capabilityIDs.append(.init(rawValue: "provider.mcp"))
  }
  if adapters.semanticMemoryStore != nil {
    capabilityIDs.append(.init(rawValue: "memory.semantic"))
  }
  if adapters.gitExecutor != nil || adapters.gitAvailabilityProbe != nil {
    capabilityIDs.append(.init(rawValue: "tool.git"))
  }

  return capabilityIDs.sorted { $0.rawValue < $1.rawValue }
}

private func summarizeRegisteredHostSurfaces(from dependencies: PraxisDependencyGraph) -> String {
  let capabilityIDs = hostCapabilityIDs(from: dependencies).map(\.rawValue)
  if capabilityIDs.isEmpty {
    return "No host capability surfaces are currently registered."
  }
  return "Registered host capability surfaces: \(capabilityIDs.joined(separator: ", "))"
}

private func cmpGitStatusSummary(_ report: PraxisGitAvailabilityReport?) -> (statusWord: String, summary: String, issue: String?) {
  guard let report else {
    return ("missing", "System git probe is not wired into HostRuntime yet.", "System git readiness still needs a host adapter.")
  }

  switch report.status {
  case .ready:
    return ("ready", "System git is ready at \(report.executablePath ?? "unknown path").", nil)
  case .installPromptExpected:
    return (
      "install_prompt_expected",
      "System git is expected to prompt for Command Line Tools on first use.",
      report.remediationHint ?? "System git may still need Command Line Tools installation."
    )
  case .unavailable:
    return (
      "unavailable",
      "System git is currently unavailable for local runtime use.",
      report.remediationHint ?? "System git is unavailable."
    )
  }
}

private func cmpStructuredStoreSummary(
  checkpointStoreAvailable: Bool,
  journalStoreAvailable: Bool,
  projectionDescriptors: [PraxisProjectionRecordDescriptor]
) -> String {
  let availability = checkpointStoreAvailable && journalStoreAvailable
    ? "Checkpoint and journal persistence are wired through HostContracts."
    : "Checkpoint and journal persistence are still incomplete."
  return "\(availability) Projection descriptors available: \(projectionDescriptors.count)."
}

private func cmpDeliverySummary(
  deliveryTruthRecords: [PraxisDeliveryTruthRecord],
  messageBusAvailable: Bool
) -> String {
  let expired = deliveryTruthRecords.filter { $0.status == .expired }.count
  let retryScheduled = deliveryTruthRecords.filter { $0.status == .retryScheduled }.count
  let transport = messageBusAvailable
    ? "Actor-style message transport is registered."
    : "Message transport is not registered yet."
  return "\(transport) Delivery truth records: \(deliveryTruthRecords.count) total, \(retryScheduled) retrying, \(expired) expired."
}

private func cmpSemanticIndexSummary(
  semanticSearchAvailable: Bool,
  semanticMemoryAvailable: Bool,
  embeddingStoreAvailable: Bool
) -> String {
  if semanticSearchAvailable && semanticMemoryAvailable && embeddingStoreAvailable {
    return "Semantic search, semantic memory, and embedding metadata stores are all wired for local-first inspection."
  }
  return "Semantic memory/search remains partial until search index, memory store, and embedding store are all present."
}

private func cmpWorkspaceSummary(
  from dependencies: PraxisDependencyGraph
) async -> (statusWord: String, summary: String, issue: String?) {
  let workspaceRoot = dependencies.hostAdapters.workspaceRootDirectory
  var findings: [String] = []
  var issues: [String] = []

  if let workspaceRoot {
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: workspaceRoot.path, isDirectory: &isDirectory), isDirectory.boolValue {
      findings.append("root ready (\(workspaceRoot.path))")
    } else {
      issues.append("configured workspace root is unavailable: \(workspaceRoot.path)")
    }
  } else {
    findings.append("workspace root inherited from host process")
  }

  if let reader = dependencies.hostAdapters.workspaceReader {
    _ = reader
    findings.append("reader registered")
  } else {
    issues.append("workspace reader is missing")
  }

  if let searcher = dependencies.hostAdapters.workspaceSearcher {
    _ = searcher
    findings.append("searcher registered")
  } else {
    issues.append("workspace searcher is missing")
  }

  if dependencies.hostAdapters.workspaceWriter != nil {
    findings.append("writer registered")
  } else {
    issues.append("workspace writer is missing")
  }

  let statusWord: String
  switch (findings.isEmpty, issues.isEmpty) {
  case (false, true):
    statusWord = "ready"
  case (false, false):
    statusWord = "degraded"
  default:
    statusWord = "missing"
  }

  let summary = issues.isEmpty
    ? "Workspace surface is \(statusWord): \(findings.joined(separator: ", "))."
    : "Workspace surface is \(statusWord): \(findings.joined(separator: ", ")). Issues: \(issues.joined(separator: "; "))."
  return (statusWord, summary, issues.isEmpty ? nil : issues.joined(separator: "; "))
}

private func cmpGitExecutorSummary(
  from dependencies: PraxisDependencyGraph
) async -> (statusWord: String, summary: String, issue: String?) {
  let repositoryRoot = dependencies.hostAdapters.workspaceRootDirectory?.path
    ?? FileManager.default.currentDirectoryPath
  guard let gitExecutor = dependencies.hostAdapters.gitExecutor else {
    return ("missing", "System git executor is not wired into HostRuntime yet.", "System git executor is still missing from HostRuntime composition.")
  }

  do {
    let receipt = try await gitExecutor.apply(
      .init(
        operationID: "cmp.inspect.git.verify",
        repositoryRoot: repositoryRoot,
        steps: [
          .init(kind: .verifyRepository, summary: "Verify runtime workspace is a git repository.")
        ],
        summary: "Verify local CMP repository readiness."
      )
    )
    switch receipt.status {
    case .applied:
      return ("ready", "System git executor verified repository access at \(repositoryRoot).", nil)
    case .partial:
      return ("degraded", "System git executor partially verified repository access: \(receipt.outputSummary)", receipt.outputSummary)
    case .rejected:
      return ("degraded", "System git executor could not verify repository access: \(receipt.outputSummary)", receipt.outputSummary)
    }
  } catch {
    return ("degraded", "System git executor failed during repository verification.", "System git executor failed: \(error)")
  }
}

private func cmpLineageSummary(
  projectionDescriptors: [PraxisProjectionRecordDescriptor],
  dependencies: PraxisDependencyGraph
) async -> (statusWord: String, summary: String, issue: String?) {
  guard let lineageStore = dependencies.hostAdapters.lineageStore else {
    return ("missing", "Lineage store is not wired into HostRuntime yet.", "Lineage persistence is still missing from HostRuntime composition.")
  }

  let lineageIDs = Array(Set(projectionDescriptors.compactMap(\.lineageID)))
    .sorted { $0.rawValue < $1.rawValue }

  guard !lineageIDs.isEmpty else {
    return ("ready", "Lineage store is wired, but no projection descriptors currently reference stored lineages.", nil)
  }

  var resolvedCount = 0
  var unresolvedIDs: [String] = []
  for lineageID in lineageIDs {
    do {
      let descriptor = try await lineageStore.describe(.init(lineageID: lineageID))
      if descriptor == nil {
        unresolvedIDs.append(lineageID.rawValue)
      } else {
        resolvedCount += 1
      }
    } catch {
      unresolvedIDs.append(lineageID.rawValue)
    }
  }

  let issue = unresolvedIDs.isEmpty
    ? nil
    : "Lineage store is missing descriptors for \(unresolvedIDs.joined(separator: ", "))."
  let statusWord = unresolvedIDs.isEmpty ? "ready" : "degraded"
  let summary = "Lineage persistence resolved \(resolvedCount) of \(lineageIDs.count) projected lineages."
  return (statusWord, summary, issue)
}

private func mpMultimodalSummary(from dependencies: PraxisDependencyGraph) -> String {
  let adapters = dependencies.hostAdapters
  let chips = [
    adapters.audioTranscriptionDriver != nil ? "audio.transcribe" : nil,
    adapters.speechSynthesisDriver != nil ? "speech.synthesize" : nil,
    adapters.imageGenerationDriver != nil ? "image.generate" : nil,
    adapters.browserGroundingCollector != nil ? "browser.ground" : nil,
  ].compactMap { $0 }

  if chips.isEmpty {
    return "No multimodal host chips are currently registered."
  }
  return "Multimodal host chips: \(chips.joined(separator: ", "))"
}

private func cmpComponentStatus(
  ready: Bool,
  missing: Bool = false
) -> String {
  if ready {
    return "ready"
  }
  return missing ? "missing" : "degraded"
}

private func cmpProjectHostProfile(
  structuredStoreAvailable: Bool,
  deliveryStoreAvailable: Bool,
  messageBusAvailable: Bool,
  gitAvailable: Bool,
  semanticSearchAvailable: Bool,
  semanticMemoryAvailable: Bool,
  embeddingStoreAvailable: Bool
) -> PraxisCmpProjectHostProfile {
  PraxisCmpProjectHostProfile(
    executionStyle: "local-first",
    structuredStore: structuredStoreAvailable ? "sqlite" : "incomplete",
    deliveryStore: deliveryStoreAvailable ? "sqlite" : "missing",
    messageTransport: messageBusAvailable ? "in_process_actor_bus" : "missing",
    gitAccess: gitAvailable ? "system_git" : "degraded",
    semanticIndex: semanticSearchAvailable && semanticMemoryAvailable && embeddingStoreAvailable
      ? "local_semantic_index"
      : "partial"
    )
}

private func cmpPackageDescriptor(
  projectID: String,
  package: PraxisCmpContextPackage,
  status: PraxisCmpPackageStatus? = nil,
  updatedAt: String? = nil
) -> PraxisCmpContextPackageDescriptor {
  PraxisCmpContextPackageDescriptor(
    projectID: projectID,
    packageID: package.id,
    sourceProjectionID: package.sourceProjectionID,
    sourceSnapshotID: package.sourceSnapshotID,
    sourceAgentID: package.sourceAgentID,
    targetAgentID: package.targetAgentID,
    packageKind: package.kind,
    fidelityLabel: package.fidelityLabel,
    packageRef: package.packageRef,
    status: status ?? package.status,
    sourceSectionIDs: package.sourceSectionIDs,
    createdAt: package.createdAt,
    updatedAt: updatedAt ?? package.createdAt,
    metadata: package.metadata
  )
}

private func cmpContextPackage(
  from descriptor: PraxisCmpContextPackageDescriptor
) -> PraxisCmpContextPackage {
  PraxisCmpContextPackage(
    id: descriptor.packageID,
    sourceProjectionID: descriptor.sourceProjectionID,
    sourceSnapshotID: descriptor.sourceSnapshotID,
    sourceAgentID: descriptor.sourceAgentID,
    targetAgentID: descriptor.targetAgentID,
    kind: descriptor.packageKind,
    packageRef: descriptor.packageRef,
    fidelityLabel: descriptor.fidelityLabel,
    createdAt: descriptor.createdAt,
    status: descriptor.status,
    sourceSectionIDs: descriptor.sourceSectionIDs,
    metadata: descriptor.metadata
  )
}

private func cmpProjectPackageDescriptors(
  projectID: String,
  sourceAgentID: String? = nil,
  targetAgentID: String? = nil,
  sourceSnapshotID: PraxisCmpSnapshotID? = nil,
  packageKind: PraxisCmpContextPackageKind? = nil,
  dependencies: PraxisDependencyGraph
) async throws -> [PraxisCmpContextPackageDescriptor] {
  try await dependencies.hostAdapters.cmpContextPackageStore?.describe(
    .init(
      projectID: projectID,
      sourceAgentID: sourceAgentID,
      targetAgentID: targetAgentID,
      sourceSnapshotID: sourceSnapshotID,
      packageKind: packageKind
    )
  ) ?? []
}

private func cmpProjectDeliveryTruthRecords(
  projectID: String,
  packageIDs: Set<PraxisCmpPackageID> = [],
  dependencies: PraxisDependencyGraph
) async throws -> [PraxisDeliveryTruthRecord] {
  let allRecords = try await dependencies.hostAdapters.deliveryTruthStore?.lookup(.init()) ?? []
  return allRecords.filter { record in
    if let packageID = record.packageID, packageIDs.contains(packageID) {
      return true
    }
    if projectID == cmpLocalRuntimeProjectID && record.topic == cmpLocalRuntimeDeliveryTopic {
      return true
    }
    return record.topic.hasPrefix("cmp.\(projectID).")
  }
}

private func buildCmpProjectReadback(
  projectID: String,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpProjectReadback {
  let gitReport = await dependencies.hostAdapters.gitAvailabilityProbe?.probeGitReadiness()
  let gitStatus = cmpGitStatusSummary(gitReport)
  let projectionDescriptors = try await dependencies.hostAdapters.projectionStore?.describe(
    .init(projectID: projectID)
  ) ?? []
  let packageDescriptors = try await cmpProjectPackageDescriptors(
    projectID: projectID,
    dependencies: dependencies
  )
  let deliveryTruthRecords = try await cmpProjectDeliveryTruthRecords(
    projectID: projectID,
    packageIDs: Set(packageDescriptors.map(\.packageID)),
    dependencies: dependencies
  )
  let checkpointStoreAvailable = dependencies.hostAdapters.checkpointStore != nil
  let journalStoreAvailable = dependencies.hostAdapters.journalStore != nil
  let projectionStoreAvailable = dependencies.hostAdapters.projectionStore != nil
  let packageStoreAvailable = dependencies.hostAdapters.cmpContextPackageStore != nil
  let deliveryTruthStoreAvailable = dependencies.hostAdapters.deliveryTruthStore != nil
  let messageBusAvailable = dependencies.hostAdapters.messageBus != nil
  let semanticSearchAvailable = dependencies.hostAdapters.semanticSearchIndex != nil
  let semanticMemoryAvailable = dependencies.hostAdapters.semanticMemoryStore != nil
  let embeddingStoreAvailable = dependencies.hostAdapters.embeddingStore != nil
  let workspaceStatus = await cmpWorkspaceSummary(from: dependencies)
  let gitExecutorStatus = await cmpGitExecutorSummary(from: dependencies)
  let lineageStatus = await cmpLineageSummary(
    projectionDescriptors: projectionDescriptors,
    dependencies: dependencies
  )
  let structuredStoreSummary = cmpStructuredStoreSummary(
    checkpointStoreAvailable: checkpointStoreAvailable,
    journalStoreAvailable: journalStoreAvailable,
    projectionDescriptors: projectionDescriptors
  ) + " " + lineageStatus.summary
  let coordinationSummary = messageBusAvailable
    ? "Neighborhood fan-out can flow through the registered host message bus."
    : "Neighborhood fan-out still needs a host message bus adapter."
  var issues: [String] = []
  if projectionDescriptors.isEmpty {
    issues.append("Projection store is wired but currently has no descriptors for \(projectID).")
  }
  if packageDescriptors.isEmpty && packageStoreAvailable {
    issues.append("CMP package registry is wired but currently has no descriptors for \(projectID).")
  }
  if deliveryTruthRecords.contains(where: { $0.status == .retryScheduled || $0.status == .expired }) {
    issues.append("Delivery truth contains retry/expired records that still need operator attention.")
  }
  if let gitIssue = gitStatus.issue {
    issues.append(gitIssue)
  }
  if let workspaceIssue = workspaceStatus.issue {
    issues.append(workspaceIssue)
  }
  if let gitExecutorIssue = gitExecutorStatus.issue {
    issues.append(gitExecutorIssue)
  }
  if let lineageIssue = lineageStatus.issue {
    issues.append(lineageIssue)
  }
  if !messageBusAvailable {
    issues.append("Message bus adapter is still missing from HostRuntime composition.")
  }
  if !semanticSearchAvailable || !semanticMemoryAvailable || !embeddingStoreAvailable {
    issues.append("Semantic memory/search still needs the full local-first adapter set.")
  }

  let componentStatuses: [String: String] = [
    "workspace": workspaceStatus.statusWord,
    "structuredStore": cmpComponentStatus(
      ready: checkpointStoreAvailable && journalStoreAvailable && projectionStoreAvailable,
      missing: !(checkpointStoreAvailable || journalStoreAvailable || projectionStoreAvailable)
    ),
    "packageRegistry": packageDescriptors.isEmpty
      ? (packageStoreAvailable ? "degraded" : "missing")
      : "ready",
    "deliveryTruth": deliveryTruthRecords.isEmpty
      ? (deliveryTruthStoreAvailable ? "degraded" : "missing")
      : deliveryTruthRecords.contains(where: { $0.status == .retryScheduled || $0.status == .expired })
        ? "degraded"
        : "ready",
    "messageBus": cmpComponentStatus(ready: messageBusAvailable, missing: !messageBusAvailable),
    "gitProbe": gitStatus.statusWord == "ready" ? "ready" : "degraded",
    "gitExecutor": gitExecutorStatus.statusWord,
    "lineageStore": lineageStatus.statusWord,
    "semanticIndex": semanticSearchAvailable ? "ready" : "missing",
    "semanticMemory": semanticMemoryAvailable ? "ready" : "missing",
    "embeddingStore": embeddingStoreAvailable ? "ready" : "missing",
  ]

  let hostSummary = "macOS local runtime / workspace (\(workspaceStatus.statusWord)) / sqlite persistence (\(projectionDescriptors.count) projections, \(packageDescriptors.count) packages) / lineage store (\(lineageStatus.statusWord)) / sqlite delivery truth (\(deliveryTruthRecords.count) records) / actor message bus (\(messageBusAvailable ? "ready" : "missing")) / system git probe (\(gitStatus.statusWord)) / system git executor (\(gitExecutorStatus.statusWord)) / accelerate-like semantic index (\(semanticSearchAvailable ? "ready" : "missing"))"
  return PraxisCmpProjectReadback(
    projectID: projectID,
    summary: "CMP project readback now reads the current HostRuntime local profile, workspace, git, and lineage state through a host-neutral project surface.",
    hostSummary: hostSummary,
    persistenceSummary: structuredStoreSummary,
    coordinationSummary: coordinationSummary,
    hostProfile: cmpProjectHostProfile(
      structuredStoreAvailable: checkpointStoreAvailable && journalStoreAvailable && projectionStoreAvailable,
      deliveryStoreAvailable: deliveryTruthStoreAvailable,
      messageBusAvailable: messageBusAvailable,
      gitAvailable: dependencies.hostAdapters.gitAvailabilityProbe != nil && dependencies.hostAdapters.gitExecutor != nil,
      semanticSearchAvailable: semanticSearchAvailable,
      semanticMemoryAvailable: semanticMemoryAvailable,
      embeddingStoreAvailable: embeddingStoreAvailable
    ),
    componentStatuses: componentStatuses,
    issues: issues
  )
}

private func cmpBootstrapDefaultRepoRootPath() -> String {
  FileManager.default.currentDirectoryPath
}

private func cmpBootstrapDefaultRepoName(repoRootPath: String) -> String {
  let candidate = URL(fileURLWithPath: repoRootPath, isDirectory: true).lastPathComponent
  return candidate.isEmpty ? "praxis" : candidate.lowercased()
}

private func cmpBootstrapDefaultDatabaseName(projectID: String) -> String {
  projectID
    .lowercased()
    .replacingOccurrences(of: ".", with: "_")
    .replacingOccurrences(of: "-", with: "_")
}

private func cmpBootstrapUniqueAgentIDs(_ agentIDs: [String]) -> [String] {
  var seen = Set<String>()
  return agentIDs.compactMap { rawValue in
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
      return nil
    }
    return trimmed
  }
}

private func cmpBootstrapAgentIDs(
  for command: PraxisBootstrapCmpProjectCommand,
  dependencies: PraxisDependencyGraph
) async throws -> [String] {
  let explicitAgentIDs = cmpBootstrapUniqueAgentIDs(command.agentIDs)
  if !explicitAgentIDs.isEmpty {
    return explicitAgentIDs
  }

  let projectedAgentIDs = try await (
    dependencies.hostAdapters.projectionStore?.describe(
      .init(projectID: command.projectID)
    ) ?? []
  ).compactMap(\.agentID)
  let inferredAgentIDs = cmpBootstrapUniqueAgentIDs(projectedAgentIDs)
  if !inferredAgentIDs.isEmpty {
    return inferredAgentIDs
  }

  if let defaultAgentID = command.defaultAgentID?
    .trimmingCharacters(in: .whitespacesAndNewlines),
    !defaultAgentID.isEmpty {
    return [defaultAgentID]
  }

  return ["runtime.local"]
}

private func cmpBootstrapLineages(
  projectID: String,
  agentIDs: [String],
  defaultAgentID: String
) -> [PraxisCmpAgentLineage] {
  let normalizedAgentIDs = cmpBootstrapUniqueAgentIDs([defaultAgentID] + agentIDs)
  let rootAgentID = normalizedAgentIDs.first ?? defaultAgentID
  let childAgentIDs = normalizedAgentIDs.filter { $0 != rootAgentID }

  return normalizedAgentIDs.map { agentID in
    let isRoot = agentID == rootAgentID
    let peerAgentIDs = isRoot ? [] : childAgentIDs.filter { $0 != agentID }
    return PraxisCmpAgentLineage(
      id: .init(rawValue: "lineage.\(projectID).\(agentID)"),
      projectID: projectID,
      agentID: agentID,
      parentAgentID: isRoot ? nil : rootAgentID,
      depth: isRoot ? 0 : 1,
      branchFamily: .init(
        workBranch: "work/\(agentID)",
        cmpBranch: "cmp/\(agentID)",
        mpBranch: "mp/\(agentID)",
        tapBranch: "tap/\(agentID)"
      ),
      childAgentIDs: isRoot ? childAgentIDs : [],
      peerAgentIDs: peerAgentIDs
    )
  }
}

private func cmpBootstrapMqBindings(
  lineage: PraxisCmpAgentLineage,
  projectID: String,
  namespace: PraxisCmpMqNamespace,
  planner: PraxisCmpMqPlanner
) -> [PraxisCmpMqTopicBinding] {
  var relations: [PraxisCmpNeighborhoodRelation] = [.same]
  if lineage.parentAgentID != nil {
    relations.append(.parent)
  }
  if !lineage.peerAgentIDs.isEmpty {
    relations.append(.peer)
  }
  if !lineage.childAgentIDs.isEmpty {
    relations.append(.child)
  }

  return relations.map { relation in
    let topology = planner.topicTopology(projectID: projectID, agentID: lineage.agentID, relation: relation)
    return PraxisCmpMqTopicBinding(
      agentID: lineage.agentID,
      topicName: topology.topicName,
      channel: relation,
      transportKey: "\(namespace.keyPrefix):\(relation.rawValue)"
    )
  }
}

private func bootstrapCmpProject(
  command: PraxisBootstrapCmpProjectCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpProjectBootstrap {
  let structuredStoreAvailable = dependencies.hostAdapters.checkpointStore != nil
    && dependencies.hostAdapters.journalStore != nil
    && dependencies.hostAdapters.projectionStore != nil
  let deliveryStoreAvailable = dependencies.hostAdapters.deliveryTruthStore != nil
  let messageBusAvailable = dependencies.hostAdapters.messageBus != nil
  let gitAvailable = dependencies.hostAdapters.gitAvailabilityProbe != nil && dependencies.hostAdapters.gitExecutor != nil
  let semanticSearchAvailable = dependencies.hostAdapters.semanticSearchIndex != nil
  let semanticMemoryAvailable = dependencies.hostAdapters.semanticMemoryStore != nil
  let embeddingStoreAvailable = dependencies.hostAdapters.embeddingStore != nil

  let agentIDs = try await cmpBootstrapAgentIDs(for: command, dependencies: dependencies)
  let defaultAgentID = command.defaultAgentID ?? agentIDs.first ?? "runtime.local"
  let lineages = cmpBootstrapLineages(projectID: command.projectID, agentIDs: agentIDs, defaultAgentID: defaultAgentID)
  let gitPlanner = PraxisCmpGitPlanner()
  let dbPlanner = PraxisCmpDbPlanner()
  let mqPlanner = PraxisCmpMqPlanner()

  let repoRootPath = command.repoRootPath ?? cmpBootstrapDefaultRepoRootPath()
  let repoName = command.repoName ?? cmpBootstrapDefaultRepoName(repoRootPath: repoRootPath)
  let defaultBranchName = command.defaultBranchName ?? "main"
  let databaseName = command.databaseName ?? cmpBootstrapDefaultDatabaseName(projectID: command.projectID)
  let namespaceRoot = command.namespaceRoot ?? "cmp/\(command.projectID)"
  let namespaceKeyPrefix = namespaceRoot.replacingOccurrences(of: "/", with: ":")
  let gitPlan = PraxisCmpProjectRepoBootstrapPlan(
    projectID: command.projectID,
    repoName: repoName,
    repoRootPath: repoRootPath,
    defaultBranchName: defaultBranchName,
    lineages: lineages.map(\.id)
  )

  let gitBranchRuntimes = lineages.map { lineage in
    let branchFamily = gitPlanner.branchFamily(for: lineage)
    return PraxisCmpGitBranchRuntime(
      lineageID: lineage.id,
      worktreePath: "\(repoRootPath)/.cmp/\(lineage.agentID)",
      branches: branchFamily.branches
    )
  }
  let createdBranches = gitBranchRuntimes.flatMap(\.branches)
  let gitReceipt = PraxisCmpGitBackendReceipt(
    repoName: repoName,
    status: gitAvailable ? .bootstrapped : .conflicted,
    createdBranches: createdBranches
  )

  let topology = dbPlanner.makeProjectTopology(projectID: command.projectID, databaseName: databaseName)
  let dbContract = dbPlanner.bootstrapContract(topology: topology, agentIDs: lineages.map(\.agentID))
  let dbReadbackRecords = (dbContract.sharedTargets + dbContract.agentLocalTargets).map { target in
    PraxisCmpDbReadbackRecord(
      target: target,
      status: structuredStoreAvailable ? .present : .missing,
      tableReference: structuredStoreAvailable ? target : nil
    )
  }
  let dbReceipt = PraxisCmpDbBootstrapReceipt(
    contract: dbContract,
    readbackRecords: dbReadbackRecords,
    missingTargetCount: structuredStoreAvailable ? 0 : dbReadbackRecords.count
  )

  let mqReceipts = lineages.map { lineage in
    let namespace = PraxisCmpMqNamespace(
      projectID: command.projectID,
      namespaceRoot: namespaceRoot,
      keyPrefix: namespaceKeyPrefix,
      queuePrefix: "\(namespaceKeyPrefix):queue",
      streamPrefix: "\(namespaceKeyPrefix):stream"
    )
    return PraxisCmpMqBootstrapReceipt(
      projectID: command.projectID,
      agentID: lineage.agentID,
      namespace: namespace,
      bindings: cmpBootstrapMqBindings(
        lineage: lineage,
        projectID: command.projectID,
        namespace: namespace,
        planner: mqPlanner
      )
    )
  }

  if let lineageStore = dependencies.hostAdapters.lineageStore {
    for lineage in lineages {
      try await lineageStore.save(
        .init(
          lineageID: lineage.id,
          branchRef: lineage.branchFamily.cmpBranch,
          parentLineageID: lineage.parentAgentID.map {
            .init(rawValue: "lineage.\(command.projectID).\($0)")
          },
          summary: "CMP bootstrap lineage \(lineage.agentID) at depth \(lineage.depth)."
        )
      )
    }
  }

  var issues: [String] = []
  if !gitAvailable {
    issues.append("Git bootstrap remains planned-only until both git probe and git executor are registered.")
  }
  if !structuredStoreAvailable {
    issues.append("DB bootstrap readback is incomplete because checkpoint/journal/projection adapters are not fully registered.")
  }
  if !messageBusAvailable {
    issues.append("MQ bootstrap bindings were planned, but host message transport is still missing.")
  }
  if dependencies.hostAdapters.lineageStore == nil {
    issues.append("Lineage descriptors could not be persisted because the lineage store adapter is missing.")
  }

  let hostProfile = cmpProjectHostProfile(
    structuredStoreAvailable: structuredStoreAvailable,
    deliveryStoreAvailable: deliveryStoreAvailable,
    messageBusAvailable: messageBusAvailable,
    gitAvailable: gitAvailable,
    semanticSearchAvailable: semanticSearchAvailable,
    semanticMemoryAvailable: semanticMemoryAvailable,
    embeddingStoreAvailable: embeddingStoreAvailable
  )
  let persistenceSummary = "DB bootstrap prepared schema \(dbContract.schemaName) with \(dbContract.bootstrapStatements.count) bootstrap statements and \(dbReceipt.readbackRecords.count) readback targets."
  let coordinationSummary = "MQ bootstrap prepared \(mqReceipts.count) namespaces across \(mqReceipts.reduce(0) { $0 + $1.bindings.count }) bindings."
  let hostSummary = "CMP bootstrap aligned repo \(repoName) at \(repoRootPath), planned \(lineages.count) lineages, and exposed host-neutral git/db/mq receipts through HostRuntime."
    + " Default branch \(gitPlan.defaultBranchName) now anchors the neutral bootstrap contract."

  return PraxisCmpProjectBootstrap(
    projectID: command.projectID,
    summary: "CMP project bootstrap now exposes host-neutral git/db/mq bootstrap receipts and lineage descriptors without coupling callers to CLI or GUI surfaces.",
    hostSummary: hostSummary,
    persistenceSummary: persistenceSummary,
    coordinationSummary: coordinationSummary,
    hostProfile: hostProfile,
    gitReceipt: gitReceipt,
    gitBranchRuntimes: gitBranchRuntimes,
    dbReceipt: dbReceipt,
    mqReceipts: mqReceipts,
    lineages: lineages,
    issues: issues
  )
}

private func cmpFlowDefaultLineageID(
  projectID: String,
  agentID: String
) -> PraxisCmpLineageID {
  .init(rawValue: "lineage.\(projectID).\(agentID)")
}

private func cmpFlowDefaultBranchFamily(agentID: String) -> PraxisCmpBranchFamily {
  .init(
    workBranch: "work/\(agentID)",
    cmpBranch: "cmp/\(agentID)",
    mpBranch: "mp/\(agentID)",
    tapBranch: "tap/\(agentID)"
  )
}

private func cmpFlowParentAgentID(
  from parentLineageID: PraxisCmpLineageID?,
  projectID: String
) -> String? {
  guard let parentLineageID else {
    return nil
  }
  let prefix = "lineage.\(projectID)."
  guard parentLineageID.rawValue.hasPrefix(prefix) else {
    return nil
  }
  return String(parentLineageID.rawValue.dropFirst(prefix.count))
}

private func cmpFlowLineage(
  projectID: String,
  agentID: String,
  lineageIDRaw: String?,
  parentAgentID: String?,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpAgentLineage {
  let lineageID = lineageIDRaw.map(PraxisCmpLineageID.init(rawValue:)) ?? cmpFlowDefaultLineageID(projectID: projectID, agentID: agentID)
  let storedDescriptor = try await dependencies.hostAdapters.lineageStore?.describe(.init(lineageID: lineageID))
  let resolvedParentAgentID = parentAgentID
    ?? cmpFlowParentAgentID(from: storedDescriptor?.parentLineageID, projectID: projectID)
  let cmpBranch = storedDescriptor?.branchRef ?? "cmp/\(agentID)"
  let branchFamily = PraxisCmpBranchFamily(
    workBranch: cmpFlowDefaultBranchFamily(agentID: agentID).workBranch,
    cmpBranch: cmpBranch,
    mpBranch: cmpFlowDefaultBranchFamily(agentID: agentID).mpBranch,
    tapBranch: cmpFlowDefaultBranchFamily(agentID: agentID).tapBranch
  )
  return PraxisCmpAgentLineage(
    id: lineageID,
    projectID: projectID,
    agentID: agentID,
    parentAgentID: resolvedParentAgentID,
    depth: resolvedParentAgentID == nil ? 0 : 1,
    branchFamily: branchFamily
  )
}

private func ingestCmpFlow(
  command: PraxisIngestCmpFlowCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowIngest {
  let validator = PraxisCmpInterfaceValidator()
  let lineage = try await cmpFlowLineage(
    projectID: command.projectID,
    agentID: command.agentID,
    lineageIDRaw: command.lineageID,
    parentAgentID: command.parentAgentID,
    dependencies: dependencies
  )
  let input = PraxisIngestRuntimeContextInput(
    agentID: command.agentID,
    projectID: command.projectID,
    sessionID: command.sessionID,
    runID: command.runID,
    lineage: lineage,
    taskSummary: command.taskSummary,
    materials: command.materials,
    requiresActiveSync: command.requiresActiveSync
  )
  try validator.validate(input)

  let createdAt = runtimeNow()
  let requestID = PraxisCmpRequestID(rawValue: "request.\(UUID().uuidString.lowercased())")
  let sectionBuilder = PraxisSectionBuilder()
  let fiveAgentPlanner = PraxisCmpFiveAgentPlanner()
  let ingress = sectionBuilder.buildIngressRecord(
    from: input,
    requestID: requestID,
    createdAt: createdAt
  )
  let loweredSections = sectionBuilder.lower(ingress, with: sectionBuilder.defaultRulePack())
  let acceptedEventIDs = command.materials.enumerated().map { index, _ in
    PraxisCmpEventID(rawValue: "\(requestID.rawValue):event:\(index)")
  }
  let roleAssignments = fiveAgentPlanner.assignments(from: loweredSections)
  let result = PraxisIngestRuntimeContextResult(
    status: .accepted,
    acceptedEventIDs: acceptedEventIDs,
    nextAction: command.requiresActiveSync ? "commit_context_delta" : "noop",
    metadata: [
      "requestID": .string(requestID.rawValue),
      "sectionCount": .number(Double(ingress.sections.count)),
      "storedSectionCount": .number(Double(loweredSections.compactMap(\.storedSection).count)),
      "roleAssignments": .array(roleAssignments.map { .string($0.role.rawValue) }),
    ]
  )
  return PraxisCmpFlowIngest(
    projectID: command.projectID,
    agentID: command.agentID,
    sessionID: command.sessionID,
    summary: "CMP ingest accepted \(acceptedEventIDs.count) material(s) into \(ingress.sections.count) section(s) through the neutral flow surface.",
    requestID: requestID,
    result: result,
    ingress: ingress,
    loweredSections: loweredSections,
    roleAssignments: roleAssignments
  )
}

private func commitCmpFlow(
  command: PraxisCommitCmpFlowCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowCommit {
  let validator = PraxisCmpInterfaceValidator()
  let lineage = try await cmpFlowLineage(
    projectID: command.projectID,
    agentID: command.agentID,
    lineageIDRaw: command.lineageID,
    parentAgentID: command.parentAgentID,
    dependencies: dependencies
  )
  let createdAt = runtimeNow()
  let delta = PraxisCmpContextDelta(
    id: .init(rawValue: "delta.\(UUID().uuidString.lowercased())"),
    agentID: command.agentID,
    baseRef: command.baseRef,
    eventRefs: command.eventIDs.map(PraxisCmpEventID.init(rawValue:)),
    changeSummary: command.changeSummary,
    createdAt: createdAt,
    syncIntent: command.syncIntent,
    metadata: [
      "projectID": .string(command.projectID),
      "sessionID": .string(command.sessionID),
      "runID": command.runID.map(PraxisValue.string) ?? .null,
    ]
  )
  try validator.validate(delta)

  let gitPlanner = PraxisCmpGitPlanner()
  let gitSnapshotCandidate = gitPlanner.makeSnapshotCandidate(
    lineage: lineage,
    delta: delta,
    commitSha: "commit.\(delta.id.rawValue)",
    createdAt: createdAt
  )
  let snapshotCandidate = PraxisCmpSnapshotCandidate(
    id: gitSnapshotCandidate.id,
    lineageID: lineage.id,
    agentID: command.agentID,
    branchRef: gitSnapshotCandidate.branchRef.name,
    commitRef: gitSnapshotCandidate.commitSha,
    deltaRefs: gitSnapshotCandidate.deltaRefs,
    createdAt: gitSnapshotCandidate.createdAt,
    status: gitSnapshotCandidate.status
  )
  let deliveryPlanner = PraxisDeliveryPlanner()
  let activeLine = try deliveryPlanner.advance(
    .init(
      lineageID: lineage.id,
      stage: .captured,
      latestEventID: delta.eventRefs.last,
      deltaID: delta.id,
      updatedAt: createdAt
    ),
    to: .candidateReady,
    updatedAt: createdAt,
    snapshotID: snapshotCandidate.id
  )
  let result = PraxisCommitContextDeltaResult(
    status: .materialized,
    delta: delta,
    snapshotCandidateID: snapshotCandidate.id,
    metadata: [
      "lineageID": .string(lineage.id.rawValue),
      "branchRef": .string(snapshotCandidate.branchRef),
      "activeLineStage": .string(activeLine.stage.rawValue),
    ]
  )
  return PraxisCmpFlowCommit(
    projectID: command.projectID,
    agentID: command.agentID,
    summary: "CMP commit advanced \(delta.eventRefs.count) event(s) into delta \(delta.id.rawValue) and prepared snapshot candidate \(snapshotCandidate.id.rawValue).",
    result: result,
    snapshotCandidate: snapshotCandidate,
    activeLine: activeLine
  )
}

private func resolveCmpFlow(
  command: PraxisResolveCmpFlowCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowResolve {
  let lineage = try await cmpFlowLineage(
    projectID: command.projectID,
    agentID: command.agentID,
    lineageIDRaw: command.lineageID,
    parentAgentID: nil,
    dependencies: dependencies
  )
  let input = PraxisResolveCheckedSnapshotInput(
    agentID: command.agentID,
    projectID: command.projectID,
    lineageID: command.lineageID.map(PraxisCmpLineageID.init(rawValue:)),
    branchRef: command.branchRef ?? lineage.branchFamily.cmpBranch
  )
  let descriptors = try await dependencies.hostAdapters.projectionStore?.describe(
    .init(projectID: command.projectID, lineageID: input.lineageID, agentID: command.agentID)
  ) ?? []
  let latestDescriptor = descriptors.sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }.first
  let snapshot = latestDescriptor.map { descriptor in
    PraxisCmpCheckedSnapshot(
      id: .init(rawValue: "\(descriptor.projectionID.rawValue):checked"),
      lineageID: descriptor.lineageID ?? lineage.id,
      agentID: descriptor.agentID ?? command.agentID,
      branchRef: input.branchRef ?? lineage.branchFamily.cmpBranch,
      commitRef: descriptor.storageKey ?? descriptor.projectionID.rawValue,
      checkedAt: descriptor.updatedAt ?? runtimeNow(),
      qualityLabel: .usable,
      promotable: true,
      sourceDeltaRefs: [],
      metadata: descriptor.metadata
    )
  }
  if let snapshot {
    try PraxisCmpInterfaceValidator().validate(snapshot)
  }
  let result = PraxisResolveCheckedSnapshotResult(
    status: snapshot == nil ? .notFound : .resolved,
    found: snapshot != nil,
    snapshot: snapshot,
    metadata: [
      "lineageID": .string((input.lineageID ?? lineage.id).rawValue),
      "branchRef": .string(input.branchRef ?? lineage.branchFamily.cmpBranch),
    ]
  )
  let summary = snapshot.map {
    "CMP resolve selected checked snapshot \($0.id.rawValue) for agent \(command.agentID) through the neutral flow surface."
  } ?? "CMP resolve did not find a checked snapshot for agent \(command.agentID) in project \(command.projectID)."
  return PraxisCmpFlowResolve(
    projectID: command.projectID,
    agentID: command.agentID,
    summary: summary,
    result: result,
    snapshot: snapshot
  )
}

private func cmpProjectionDescriptorMatchesSnapshotID(
  _ descriptor: PraxisProjectionRecordDescriptor,
  snapshotID: PraxisCmpSnapshotID
) -> Bool {
  if descriptor.metadata["snapshotID"]?.stringValue == snapshotID.rawValue {
    return true
  }
  return "\(descriptor.projectionID.rawValue):checked" == snapshotID.rawValue
}

private func cmpProjectionDescriptors(
  projectID: String,
  agentID: String? = nil,
  lineageID: PraxisCmpLineageID? = nil,
  dependencies: PraxisDependencyGraph
) async throws -> [PraxisProjectionRecordDescriptor] {
  try await dependencies.hostAdapters.projectionStore?.describe(
    .init(projectID: projectID, lineageID: lineageID, agentID: agentID)
  ) ?? []
}

private func cmpProjectionDescriptor(
  projectID: String,
  agentID: String,
  lineageID: PraxisCmpLineageID?,
  projectionID: PraxisCmpProjectionID?,
  snapshotID: PraxisCmpSnapshotID?,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisProjectionRecordDescriptor? {
  let descriptors = try await cmpProjectionDescriptors(
    projectID: projectID,
    agentID: agentID,
    lineageID: lineageID,
    dependencies: dependencies
  )
  let matchingDescriptors = descriptors.filter { descriptor in
    if let projectionID, descriptor.projectionID != projectionID {
      return false
    }
    if let snapshotID, !cmpProjectionDescriptorMatchesSnapshotID(descriptor, snapshotID: snapshotID) {
      return false
    }
    return true
  }
  return matchingDescriptors.sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }.first
}

private func cmpProjectionSectionIDs(from descriptor: PraxisProjectionRecordDescriptor) -> [PraxisCmpSectionID] {
  let selectedKeys = ["selectedSectionIDs", "sectionIDs"]
  for key in selectedKeys {
    if let sectionIDs = descriptor.metadata[key]?.arrayValue?
      .compactMap(\.stringValue)
      .map(PraxisCmpSectionID.init(rawValue:)),
      !sectionIDs.isEmpty {
      return sectionIDs
    }
  }
  return [.init(rawValue: "\(descriptor.projectionID.rawValue):section")]
}

private func cmpProjectionStoredRefs(from descriptor: PraxisProjectionRecordDescriptor) -> [String] {
  if let storedRefs = descriptor.metadata["storedRefs"]?.arrayValue?
    .compactMap(\.stringValue),
    !storedRefs.isEmpty {
    return storedRefs
  }
  if let storageKey = descriptor.storageKey {
    return [storageKey]
  }
  return [descriptor.projectionID.rawValue]
}

private func cmpCheckedSnapshot(
  from descriptor: PraxisProjectionRecordDescriptor,
  defaultLineageID: PraxisCmpLineageID,
  defaultAgentID: String,
  defaultBranchRef: String
) -> PraxisCmpCheckedSnapshot {
  PraxisCmpCheckedSnapshot(
    id: .init(rawValue: descriptor.metadata["snapshotID"]?.stringValue ?? "\(descriptor.projectionID.rawValue):checked"),
    lineageID: descriptor.lineageID ?? defaultLineageID,
    agentID: descriptor.agentID ?? defaultAgentID,
    branchRef: descriptor.metadata["branchRef"]?.stringValue ?? defaultBranchRef,
    commitRef: descriptor.storageKey ?? descriptor.projectionID.rawValue,
    checkedAt: descriptor.updatedAt ?? runtimeNow(),
    qualityLabel: .usable,
    promotable: true,
    sourceDeltaRefs: [],
    metadata: descriptor.metadata
  )
}

private func cmpProjectionRecord(
  from descriptor: PraxisProjectionRecordDescriptor,
  snapshot: PraxisCmpCheckedSnapshot
) -> PraxisProjectionRecord {
  PraxisProjectionRecord(
    id: descriptor.projectionID,
    snapshotID: snapshot.id,
    lineageID: descriptor.lineageID ?? snapshot.lineageID,
    agentID: descriptor.agentID ?? snapshot.agentID,
    sectionIDs: cmpProjectionSectionIDs(from: descriptor),
    storedRefs: cmpProjectionStoredRefs(from: descriptor),
    visibilityLevel: descriptor.visibilityLevel ?? .localOnly,
    updatedAt: descriptor.updatedAt ?? snapshot.checkedAt,
    metadata: descriptor.metadata
  )
}

private func cmpContextPackage(
  projectID: String,
  projection: PraxisProjectionRecord,
  snapshot: PraxisCmpCheckedSnapshot,
  targetAgentID: String,
  packageKind: PraxisCmpContextPackageKind,
  fidelityLabel: PraxisCmpContextPackageFidelityLabel,
  createdAt: String
) -> PraxisCmpContextPackage {
  PraxisCmpContextPackage(
    id: .init(rawValue: "\(projection.id.rawValue):\(targetAgentID):\(packageKind.rawValue)"),
    sourceProjectionID: projection.id,
    sourceSnapshotID: snapshot.id,
    sourceAgentID: projection.agentID,
    targetAgentID: targetAgentID,
    kind: packageKind,
    packageRef: "context://\(projectID)/\(projection.id.rawValue)/\(targetAgentID)/\(packageKind.rawValue)",
    fidelityLabel: fidelityLabel,
    createdAt: createdAt,
    status: .materialized,
    sourceSectionIDs: projection.sectionIDs,
    metadata: [
      "projectID": .string(projectID),
      "projection_visibility": .string(projection.visibilityLevel.rawValue),
      "source_branch_ref": .string(snapshot.branchRef),
    ]
  )
}

private func materializeCmpFlow(
  command: PraxisMaterializeCmpFlowCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowMaterialize {
  let lineage = try await cmpFlowLineage(
    projectID: command.projectID,
    agentID: command.agentID,
    lineageIDRaw: nil,
    parentAgentID: nil,
    dependencies: dependencies
  )
  let descriptor = try await cmpProjectionDescriptor(
    projectID: command.projectID,
    agentID: command.agentID,
    lineageID: nil,
    projectionID: command.projectionID.map(PraxisCmpProjectionID.init(rawValue:)),
    snapshotID: command.snapshotID.map(PraxisCmpSnapshotID.init(rawValue:)),
    dependencies: dependencies
  )
  guard let descriptor else {
    throw PraxisError.invalidInput(
      "CMP materialize requires a projection descriptor for project \(command.projectID) and agent \(command.agentID)."
    )
  }

  let snapshot = cmpCheckedSnapshot(
    from: descriptor,
    defaultLineageID: descriptor.lineageID ?? lineage.id,
    defaultAgentID: command.agentID,
    defaultBranchRef: lineage.branchFamily.cmpBranch
  )
  let projection = cmpProjectionRecord(from: descriptor, snapshot: snapshot)
  let projectionMaterializer = PraxisProjectionMaterializer()
  let materializationPlan = projectionMaterializer.createMaterializationPlan(
    from: projection,
    targetAgentID: command.targetAgentID,
    packageKind: command.packageKind
  )
  let package = cmpContextPackage(
    projectID: command.projectID,
    projection: projection,
    snapshot: snapshot,
    targetAgentID: command.targetAgentID,
    packageKind: command.packageKind,
    fidelityLabel: command.fidelityLabel ?? .highSignal,
    createdAt: runtimeNow()
  )

  let validator = PraxisCmpInterfaceValidator()
  try validator.validate(snapshot)
  try validator.validate(package)

  let result = PraxisMaterializeContextPackageResult(
    status: .materialized,
    contextPackage: package,
    metadata: [
      "snapshotID": .string(snapshot.id.rawValue),
      "projectionID": .string(projection.id.rawValue),
      "targetAgentID": .string(command.targetAgentID),
    ]
  )
  if let packageStore = dependencies.hostAdapters.cmpContextPackageStore {
    _ = try await packageStore.save(
      cmpPackageDescriptor(
        projectID: command.projectID,
        package: package,
        status: .materialized,
        updatedAt: package.createdAt
      )
    )
  }
  return PraxisCmpFlowMaterialize(
    projectID: command.projectID,
    agentID: command.agentID,
    summary: "CMP materialize prepared \(materializationPlan.selectedSectionIDs.count) section(s) from projection \(projection.id.rawValue) for \(command.targetAgentID) through the neutral flow surface.",
    result: result,
    materializationPlan: materializationPlan
  )
}

private func dispatchCmpFlow(
  command: PraxisDispatchCmpFlowCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowDispatch {
  let validator = PraxisCmpInterfaceValidator()
  try validator.validate(command.contextPackage)

  let deliveryPlanner = PraxisDeliveryPlanner()
  let mqPlanner = PraxisCmpMqPlanner()
  let createdAt = runtimeNow()
  let deliveryPlan = deliveryPlanner.buildPlan(
    for: command.contextPackage,
    targets: [(command.targetKind, command.reason)]
  )
  guard let instruction = deliveryPlan.instructions.first else {
    throw PraxisError.invariantViolation("CMP dispatch requires at least one delivery instruction.")
  }
  let routingPlan = mqPlanner.routingPlan(for: deliveryPlan, projectID: command.projectID)
  let topicName = routingPlan.destinationTopics.first?.topicName ?? "cmp.\(command.projectID).\(command.agentID).same"

  let publishedAt = try await dependencies.hostAdapters.messageBus?.publish(
    .init(
      topic: topicName,
      payloadSummary: command.reason,
      projectID: command.projectID,
      publishedAt: createdAt,
      metadata: [
        "dispatchID": .string("\(instruction.packageID.rawValue):\(instruction.targetAgentID)"),
        "packageID": .string(command.contextPackage.id.rawValue),
        "targetKind": .string(command.targetKind.rawValue),
      ]
    )
  )
  let receipt = deliveryPlanner.buildReceipt(
    for: instruction,
    status: publishedAt == nil ? .prepared : .delivered,
    createdAt: publishedAt?.acceptedAt ?? createdAt
  )
  try validator.validate(receipt)
  if let packageStore = dependencies.hostAdapters.cmpContextPackageStore {
    _ = try await packageStore.save(
      cmpPackageDescriptor(
        projectID: command.projectID,
        package: command.contextPackage,
        status: publishedAt == nil ? .materialized : .dispatched,
        updatedAt: publishedAt?.acceptedAt ?? createdAt
      )
    )
  }

  if let deliveryTruthStore = dependencies.hostAdapters.deliveryTruthStore {
    _ = try await deliveryTruthStore.save(
      .init(
        id: "delivery.\(receipt.id.rawValue)",
        packageID: receipt.packageID,
        topic: topicName,
        targetAgentID: receipt.targetAgentID,
        status: publishedAt == nil ? .pending : .published,
        payloadSummary: command.reason,
        updatedAt: publishedAt?.acceptedAt ?? createdAt
      )
    )
  }

  let result = PraxisDispatchContextPackageResult(
    status: .dispatched,
    receipt: receipt,
    metadata: [
      "topicName": .string(topicName),
      "instructionCount": .number(Double(deliveryPlan.instructions.count)),
    ]
  )
  return PraxisCmpFlowDispatch(
    projectID: command.projectID,
    agentID: command.agentID,
    summary: "CMP dispatch routed package \(command.contextPackage.id.rawValue) toward \(receipt.targetAgentID) on \(topicName) through the neutral flow surface.",
    result: result,
    deliveryPlan: deliveryPlan
  )
}

private func requestCmpHistory(
  command: PraxisRequestCmpHistoryCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpFlowHistory {
  let descriptors = try await cmpProjectionDescriptors(
    projectID: command.projectID,
    agentID: nil,
    lineageID: command.query.lineageID,
    dependencies: dependencies
  )
  let snapshots = descriptors.compactMap { descriptor -> PraxisCmpCheckedSnapshot? in
    if let requestedSnapshotID = command.query.snapshotID,
       !cmpProjectionDescriptorMatchesSnapshotID(descriptor, snapshotID: requestedSnapshotID) {
      return nil
    }
    if let requestedBranchRef = command.query.branchRef,
       descriptor.metadata["branchRef"]?.stringValue != nil,
       descriptor.metadata["branchRef"]?.stringValue != requestedBranchRef {
      return nil
    }
    return cmpCheckedSnapshot(
      from: descriptor,
      defaultLineageID: descriptor.lineageID ?? cmpFlowDefaultLineageID(projectID: command.projectID, agentID: descriptor.agentID ?? command.requesterAgentID),
      defaultAgentID: descriptor.agentID ?? command.requesterAgentID,
      defaultBranchRef: descriptor.metadata["branchRef"]?.stringValue ?? "cmp/\(descriptor.agentID ?? command.requesterAgentID)"
    )
  }
  let storedPackages = try await cmpProjectPackageDescriptors(
    projectID: command.projectID,
    targetAgentID: command.requesterAgentID,
    sourceSnapshotID: command.query.snapshotID,
    packageKind: command.query.packageKindHint,
    dependencies: dependencies
  ).map(cmpContextPackage(from:))
  let reconstructedPackages = descriptors.compactMap { descriptor -> PraxisCmpContextPackage? in
    if let requestedVisibility = command.query.projectionVisibilityHint,
       descriptor.visibilityLevel != nil,
       descriptor.visibilityLevel != requestedVisibility {
      return nil
    }
    if let requestedSnapshotID = command.query.snapshotID,
       !cmpProjectionDescriptorMatchesSnapshotID(descriptor, snapshotID: requestedSnapshotID) {
      return nil
    }
    let snapshot = cmpCheckedSnapshot(
      from: descriptor,
      defaultLineageID: descriptor.lineageID ?? cmpFlowDefaultLineageID(projectID: command.projectID, agentID: descriptor.agentID ?? command.requesterAgentID),
      defaultAgentID: descriptor.agentID ?? command.requesterAgentID,
      defaultBranchRef: descriptor.metadata["branchRef"]?.stringValue ?? "cmp/\(descriptor.agentID ?? command.requesterAgentID)"
    )
    let projection = cmpProjectionRecord(from: descriptor, snapshot: snapshot)
    return cmpContextPackage(
      projectID: command.projectID,
      projection: projection,
      snapshot: snapshot,
      targetAgentID: command.requesterAgentID,
      packageKind: command.query.packageKindHint ?? .historicalReply,
      fidelityLabel: .highSignal,
      createdAt: runtimeNow()
    )
  }
  let packages = storedPackages.isEmpty ? reconstructedPackages : storedPackages

  let deliveryPlanner = PraxisDeliveryPlanner()
  let input = PraxisRequestHistoricalContextInput(
    requesterAgentID: command.requesterAgentID,
    projectID: command.projectID,
    reason: command.reason,
    query: command.query
  )
  let result = deliveryPlanner.requestHistoricalContext(
    input,
    snapshots: snapshots,
    packages: packages
  )
  let summary: String
  if result.found {
    summary = "CMP history request resolved reusable context for \(command.requesterAgentID) through the neutral flow surface."
  } else {
    let fallback = deliveryPlanner.buildFallbackPlan(for: command.query)
    summary = "CMP history request did not find reusable context for \(command.requesterAgentID). \(fallback.summary)"
  }
  return PraxisCmpFlowHistory(
    projectID: command.projectID,
    requesterAgentID: command.requesterAgentID,
    summary: summary,
    result: result
  )
}

private func cmpDefaultControlSurface(projectID: String, agentID: String?) -> PraxisCmpControlSurface {
  _ = projectID
  _ = agentID
  return PraxisCmpControlSurface(
    executionStyle: "automatic",
    mode: "active_preferred",
    readbackPriority: "git_first",
    fallbackPolicy: "git_rebuild",
    recoveryPreference: "reconcile",
    automation: [
      "autoIngest": true,
      "autoCommit": true,
      "autoResolve": true,
      "autoMaterialize": true,
      "autoDispatch": true,
      "autoReturnToCoreAgent": true,
      "autoSeedChildren": true,
    ]
  )
}

private func readbackCmpStatus(
  command: PraxisReadbackCmpStatusCommand,
  dependencies: PraxisDependencyGraph
) async throws -> PraxisCmpStatusReadback {
  let projectionDescriptors = try await cmpProjectionDescriptors(
    projectID: command.projectID,
    agentID: command.agentID,
    dependencies: dependencies
  )
  let packageDescriptors: [PraxisCmpContextPackageDescriptor]
  if let agentID = command.agentID?.trimmingCharacters(in: .whitespacesAndNewlines), !agentID.isEmpty {
    let outboundPackageDescriptors = try await cmpProjectPackageDescriptors(
      projectID: command.projectID,
      sourceAgentID: agentID,
      dependencies: dependencies
    )
    let inboundPackageDescriptors = try await cmpProjectPackageDescriptors(
      projectID: command.projectID,
      targetAgentID: agentID,
      dependencies: dependencies
    )
    var mergedPackageDescriptors: [PraxisCmpPackageID: PraxisCmpContextPackageDescriptor] = [:]
    for descriptor in outboundPackageDescriptors + inboundPackageDescriptors {
      if let existingDescriptor = mergedPackageDescriptors[descriptor.packageID],
        existingDescriptor.updatedAt > descriptor.updatedAt {
        continue
      }
      mergedPackageDescriptors[descriptor.packageID] = descriptor
    }
    packageDescriptors = Array(mergedPackageDescriptors.values)
  } else {
    packageDescriptors = try await cmpProjectPackageDescriptors(
      projectID: command.projectID,
      dependencies: dependencies
    )
  }
  let scopedPackageIDs = Set(packageDescriptors.map(\.packageID))
  let allDeliveryTruthRecords = try await cmpProjectDeliveryTruthRecords(
    projectID: command.projectID,
    packageIDs: scopedPackageIDs,
    dependencies: dependencies
  )
  let deliveryTruthRecords: [PraxisDeliveryTruthRecord]
  if command.agentID == nil {
    deliveryTruthRecords = allDeliveryTruthRecords
  } else {
    deliveryTruthRecords = allDeliveryTruthRecords.filter { record in
      guard let packageID = record.packageID else {
        return false
      }
      return scopedPackageIDs.contains(packageID)
    }
  }
  let latestPackage = packageDescriptors.sorted { $0.updatedAt > $1.updatedAt }.first
  let latestDispatchRecord = deliveryTruthRecords.sorted { $0.updatedAt > $1.updatedAt }.first
  let fiveAgentPlanner = PraxisCmpFiveAgentPlanner()
  let protocolDefinition = fiveAgentPlanner.defaultProtocolDefinition()

  let roles = protocolDefinition.roles.map { roleDefinition in
    let assignmentCount: Int
    let latestStage: String?
    switch roleDefinition.role {
    case .icma:
      assignmentCount = projectionDescriptors.isEmpty && packageDescriptors.isEmpty ? 0 : 1
      latestStage = assignmentCount == 0 ? nil : "ingested"
    case .iterator:
      assignmentCount = projectionDescriptors.isEmpty ? 0 : 1
      latestStage = assignmentCount == 0 ? nil : "candidateReady"
    case .checker:
      assignmentCount = projectionDescriptors.isEmpty ? 0 : 1
      latestStage = assignmentCount == 0 ? nil : "checkedReady"
    case .dbAgent:
      assignmentCount = projectionDescriptors.isEmpty && packageDescriptors.isEmpty ? 0 : 1
      latestStage = packageDescriptors.isEmpty ? (projectionDescriptors.isEmpty ? nil : "projectionReady") : "materialized"
    case .dispatcher:
      assignmentCount = packageDescriptors.isEmpty && deliveryTruthRecords.isEmpty ? 0 : 1
      latestStage = latestDispatchRecord?.status.rawValue ?? (packageDescriptors.isEmpty ? nil : "prepared")
    }
    return PraxisCmpRoleReadback(
      role: roleDefinition.role,
      assignmentCount: assignmentCount,
      latestStage: latestStage,
      summary: roleDefinition.responsibility
    )
  }
  let objectModel = PraxisCmpObjectModelReadback(
    projectionCount: projectionDescriptors.count,
    snapshotCount: projectionDescriptors.count,
    packageCount: packageDescriptors.count,
    deliveryCount: deliveryTruthRecords.count,
    packageStatusCounts: Dictionary(
      packageDescriptors.map(\.status.rawValue).map { ($0, 1) },
      uniquingKeysWith: +
    )
  )
  var issues: [String] = []
  if dependencies.hostAdapters.cmpContextPackageStore == nil {
    issues.append("CMP package registry adapter is still missing from HostRuntime composition.")
  }
  if packageDescriptors.isEmpty {
    issues.append("CMP package registry currently has no package descriptors for \(command.projectID).")
  }
  if deliveryTruthRecords.contains(where: { $0.status == .expired || $0.status == .retryScheduled }) {
    issues.append("CMP delivery truth still contains retry or expired records.")
  }

  let summary = "CMP status readback reconstructed role/control/object-model state from \(projectionDescriptors.count) projection(s), \(packageDescriptors.count) package(s), and \(deliveryTruthRecords.count) delivery record(s) without coupling callers to CLI or GUI."
  return PraxisCmpStatusReadback(
    projectID: command.projectID,
    agentID: command.agentID,
    summary: summary,
    control: cmpDefaultControlSurface(projectID: command.projectID, agentID: command.agentID),
    roles: roles,
    objectModel: objectModel,
    latestPackageID: latestPackage?.packageID.rawValue,
    latestDispatchStatus: latestDispatchRecord?.status.rawValue,
    latestTargetAgentID: latestPackage?.targetAgentID,
    issues: issues
  )
}

private func cmpLocalRuntimeLineageID(for sessionID: PraxisSessionID) -> PraxisCmpLineageID {
  .init(rawValue: "lineage.\(sessionID.rawValue)")
}

private func cmpLocalRuntimeProjectionID(for runID: PraxisRunID) -> PraxisCmpProjectionID {
  .init(rawValue: "projection.\(runID.rawValue)")
}

private func cmpLocalRuntimePackageID(for runID: PraxisRunID) -> PraxisCmpPackageID {
  .init(rawValue: "package.\(runID.rawValue)")
}

private func cmpLocalRuntimeDeliveryID(for runID: PraxisRunID) -> String {
  "delivery.\(runID.rawValue)"
}

private func cmpLocalRuntimeStorageKey(for runID: PraxisRunID) -> String {
  "sqlite://cmp.local-runtime/\(runID.rawValue)"
}

private func cmpLocalRuntimeMetadata(
  runID: PraxisRunID,
  sessionID: PraxisSessionID,
  checkpointReference: String,
  phase: PraxisRunPhase,
  goalTitle: String,
  followUpAction: PraxisRunFollowUpAction?
) -> [String: PraxisValue] {
  var metadata: [String: PraxisValue] = [
    "runID": .string(runID.rawValue),
    "sessionID": .string(sessionID.rawValue),
    "checkpointReference": .string(checkpointReference),
    "phase": .string(phase.rawValue),
    "goalTitle": .string(goalTitle),
  ]
  if let followUpAction {
    metadata["followUpKind"] = .string(followUpAction.kind.rawValue)
    if let intentID = followUpAction.intentID {
      metadata["followUpIntentID"] = .string(intentID)
    }
  }
  return metadata
}

private func persistCmpLocalRuntimeTruth(
  dependencies: PraxisDependencyGraph,
  runID: PraxisRunID,
  sessionID: PraxisSessionID,
  goalTitle: String,
  phase: PraxisRunPhase,
  checkpointReference: String,
  timestamp: String,
  followUpAction: PraxisRunFollowUpAction?
) async throws {
  let lineageID = cmpLocalRuntimeLineageID(for: sessionID)
  let projectionID = cmpLocalRuntimeProjectionID(for: runID)
  let packageID = cmpLocalRuntimePackageID(for: runID)
  let metadata = cmpLocalRuntimeMetadata(
    runID: runID,
    sessionID: sessionID,
    checkpointReference: checkpointReference,
    phase: phase,
    goalTitle: goalTitle,
    followUpAction: followUpAction
  )

  if let lineageStore = dependencies.hostAdapters.lineageStore {
    try await lineageStore.save(
      .init(
        lineageID: lineageID,
        branchRef: "local/\(sessionID.rawValue)",
        summary: "Local runtime lineage for session \(sessionID.rawValue)."
      )
    )
  }

  if let projectionStore = dependencies.hostAdapters.projectionStore {
    _ = try await projectionStore.save(
      .init(
        projectID: cmpLocalRuntimeProjectID,
        projectionID: projectionID,
        lineageID: lineageID,
        agentID: "runtime.local",
        visibilityLevel: .localOnly,
        storageKey: cmpLocalRuntimeStorageKey(for: runID),
        updatedAt: timestamp,
        summary: "Run \(runID.rawValue) is \(phase.rawValue) for \(goalTitle).",
        metadata: metadata
      )
    )
  }

  let publishedToBus: Bool
  if let followUpAction,
     let messageBus = dependencies.hostAdapters.messageBus {
    _ = try await messageBus.publish(
      .init(
        topic: cmpLocalRuntimeDeliveryTopic,
        payloadSummary: followUpAction.reason,
        projectID: cmpLocalRuntimeProjectID,
        publishedAt: timestamp,
        metadata: metadata
      )
    )
    publishedToBus = true
  } else {
    publishedToBus = false
  }

  if let deliveryTruthStore = dependencies.hostAdapters.deliveryTruthStore {
    let status: PraxisDeliveryTruthStatus = if followUpAction == nil {
      .acknowledged
    } else if publishedToBus {
      .published
    } else {
      .pending
    }
    _ = try await deliveryTruthStore.save(
      .init(
        id: cmpLocalRuntimeDeliveryID(for: runID),
        packageID: packageID,
        topic: cmpLocalRuntimeDeliveryTopic,
        targetAgentID: "runtime.local",
        status: status,
        payloadSummary: followUpAction?.reason ?? "Run \(runID.rawValue) reached \(phase.rawValue).",
        updatedAt: timestamp
      )
    )
  }
}

public final class PraxisRunGoalUseCase: PraxisRunGoalUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Generates or restores a runtime-recognizable run identifier from a goal command.
  ///
  /// - Parameters:
  ///   - command: The run-goal command to execute.
  /// - Returns: The resulting run execution receipt after the initial created event is persisted.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute(_ command: PraxisRunGoalCommand) async throws -> PraxisRunExecution {
    let lifecycle = PraxisRunLifecycleService()
    let sessionLifecycle = PraxisSessionLifecycleService()
    let sessionID = command.sessionID ?? defaultSessionID(for: command.goal.normalizedGoal.id.rawValue)
    let runID = runID(for: sessionID, goalID: command.goal.normalizedGoal.id.rawValue)
    let createdAt = runtimeNow()

    var sessionHeader = sessionLifecycle.createHeader(
      id: sessionID,
      title: command.goal.normalizedGoal.title,
      metadata: ["entry": "host_runtime", "goalID": .string(command.goal.normalizedGoal.id.rawValue)]
    )
    sessionHeader = sessionLifecycle.attachRun(runID.rawValue, to: sessionHeader)

    let initialRun = lifecycle.createRun(id: runID)
    let createdEvent = lifecycle.makeCreatedEvent(
      runID: runID.rawValue,
      sessionID: sessionID.rawValue,
      goalID: command.goal.normalizedGoal.id.rawValue,
      eventID: "evt.created.\(runID.rawValue)",
      createdAt: createdAt
    )
    let advanced = try lifecycle.advance(initialRun, with: createdEvent)

    let journalReceipt = try await dependencies.hostAdapters.journalStore?.append(
      .init(events: [makeJournalEvent(from: createdEvent)])
    )
    let checkpointPointer = checkpointPointer(for: runID, sessionID: sessionID)
    sessionHeader = sessionLifecycle.markCheckpoint(
      checkpointPointer.checkpointID.rawValue,
      on: sessionHeader,
      journalSequence: journalReceipt?.lastCursor?.sequence
    )

    if let checkpointStore = dependencies.hostAdapters.checkpointStore {
      let snapshot = PraxisCheckpointSnapshot(
        id: checkpointPointer.checkpointID,
        sessionID: sessionID,
        tier: .fast,
        createdAt: createdAt,
        lastCursor: journalReceipt?.lastCursor,
        payload: try checkpointPayload(
          runAggregate: advanced.run,
          sessionHeader: sessionHeader,
          goalTitle: command.goal.normalizedGoal.title
        )
      )
      _ = try await checkpointStore.save(.init(pointer: checkpointPointer, snapshot: snapshot))
    }

    let followUpAction = runFollowUpAction(from: advanced.decision.nextAction)
    try await persistCmpLocalRuntimeTruth(
      dependencies: dependencies,
      runID: runID,
      sessionID: sessionID,
      goalTitle: command.goal.normalizedGoal.title,
      phase: advanced.run.phase,
      checkpointReference: checkpointPointer.checkpointID.rawValue,
      timestamp: createdAt,
      followUpAction: followUpAction
    )

    return PraxisRunExecution(
      runID: runID,
      sessionID: sessionID,
      phase: advanced.run.phase,
      tickCount: advanced.run.tickCount,
      journalSequence: journalReceipt?.lastCursor?.sequence,
      checkpointReference: checkpointPointer.checkpointID.rawValue,
      followUpAction: followUpAction
    )
  }
}

public final class PraxisResumeRunUseCase: PraxisResumeRunUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Returns the run identifier that should continue executing.
  ///
  /// - Parameters:
  ///   - command: The run command to resume.
  /// - Returns: The resulting run execution receipt after the resume event is persisted.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute(_ command: PraxisResumeRunCommand) async throws -> PraxisRunExecution {
    guard let checkpointStore = dependencies.hostAdapters.checkpointStore else {
      throw PraxisError.dependencyMissing("HostRuntime resume requires a checkpoint store.")
    }

    let lifecycle = PraxisRunLifecycleService()
    let sessionLifecycle = PraxisSessionLifecycleService()
    let resumeRecovery = PraxisCheckpointRecoveryService()
    let sessionCandidates = sessionIDCandidates(from: command.runID)
    var resolvedSessionID: PraxisSessionID?
    var resolvedPointer: PraxisCheckpointPointer?
    var resolvedCheckpointRecord: PraxisCheckpointRecord?

    for candidate in sessionCandidates {
      let candidatePointer = checkpointPointer(for: command.runID, sessionID: candidate)
      if let candidateRecord = try await checkpointStore.load(pointer: candidatePointer) {
        resolvedSessionID = candidate
        resolvedPointer = candidatePointer
        resolvedCheckpointRecord = candidateRecord
        break
      }
    }

    guard let sessionID = resolvedSessionID,
          let pointer = resolvedPointer,
          let checkpointRecord = resolvedCheckpointRecord else {
      throw PraxisError.invalidInput("No checkpoint record found for run \(command.runID.rawValue).")
    }

    let restoredRun = try decodeJSONString(
      PraxisRunAggregate.self,
      from: checkpointRecord.snapshot.payload,
      key: "runAggregateJSON"
    ) ?? lifecycle.createRun(id: command.runID)
    var restoredSessionHeader = try decodeJSONString(
      PraxisSessionHeader.self,
      from: checkpointRecord.snapshot.payload,
      key: "sessionHeaderJSON"
    ) ?? sessionLifecycle.createHeader(
      id: sessionID,
      title: checkpointRecord.snapshot.payload?["goalTitle"]?.stringValue ?? command.runID.rawValue
    )

    let recovery: PraxisRecoveryEnvelope?
    if let journalStore = dependencies.hostAdapters.journalStore {
      recovery = try await resumeRecovery.recover(
        from: checkpointRecord.snapshot,
        journal: PraxisContractBackedJournalReader(store: journalStore)
      )
    } else {
      recovery = nil
    }

    let replayedRun = try replayRecoveredEvents(
      from: recovery,
      onto: restoredRun,
      lifecycle: lifecycle
    )

    restoredSessionHeader = sessionLifecycle.attachRun(command.runID.rawValue, to: restoredSessionHeader)
    restoredSessionHeader = sessionLifecycle.markCheckpoint(
      pointer.checkpointID.rawValue,
      on: restoredSessionHeader,
      journalSequence: recovery?.resumeCursor?.sequence ?? checkpointRecord.snapshot.lastCursor?.sequence
    )

    if !shouldIssueResumeEvent(for: replayedRun) {
      let replayedSnapshot = PraxisCheckpointSnapshot(
        id: pointer.checkpointID,
        sessionID: sessionID,
        tier: checkpointRecord.snapshot.tier,
        createdAt: checkpointRecord.snapshot.createdAt,
        lastCursor: recovery?.resumeCursor ?? checkpointRecord.snapshot.lastCursor,
        payload: try checkpointPayload(
          runAggregate: replayedRun,
          sessionHeader: restoredSessionHeader,
          goalTitle: restoredSessionHeader.title
        )
      )
      _ = try await checkpointStore.save(.init(pointer: pointer, snapshot: replayedSnapshot))
      try await persistCmpLocalRuntimeTruth(
        dependencies: dependencies,
        runID: command.runID,
        sessionID: sessionID,
        goalTitle: restoredSessionHeader.title,
        phase: replayedRun.phase,
        checkpointReference: pointer.checkpointID.rawValue,
        timestamp: replayedSnapshot.createdAt ?? runtimeNow(),
        followUpAction: nil
      )

      return PraxisRunExecution(
        runID: command.runID,
        sessionID: sessionID,
        phase: replayedRun.phase,
        tickCount: replayedRun.tickCount,
        journalSequence: recovery?.resumeCursor?.sequence ?? checkpointRecord.snapshot.lastCursor?.sequence,
        checkpointReference: pointer.checkpointID.rawValue,
        recoveredEventCount: recovery?.replayedEvents.count ?? 0,
        resumeIssued: false,
        followUpAction: nil
      )
    }

    let resumedAt = runtimeNow()
    let resumedEvent = lifecycle.makeResumedEvent(
      runID: command.runID.rawValue,
      sessionID: sessionID.rawValue,
      checkpointID: checkpointRecord.snapshot.id.rawValue,
      eventID: "evt.resumed.\(command.runID.rawValue)",
      createdAt: resumedAt
    )
    let seedRun = normalizedRunForResume(replayedRun, checkpointID: checkpointRecord.snapshot.id.rawValue)
    let advanced = try lifecycle.advance(seedRun, with: resumedEvent)
    let resumedRun = persistFollowUpIntent(
      on: advanced.run,
      intentID: advanced.decision.nextAction?.intent?.intentID
    )
    let followUpAction = runFollowUpAction(from: advanced.decision.nextAction)
    let journalReceipt = try await dependencies.hostAdapters.journalStore?.append(
      .init(events: [makeJournalEvent(from: resumedEvent)])
    )

    restoredSessionHeader = sessionLifecycle.markCheckpoint(
      pointer.checkpointID.rawValue,
      on: restoredSessionHeader,
      journalSequence: journalReceipt?.lastCursor?.sequence ?? recovery?.resumeCursor?.sequence
    )

    let updatedSnapshot = PraxisCheckpointSnapshot(
      id: pointer.checkpointID,
      sessionID: sessionID,
      tier: checkpointRecord.snapshot.tier,
      createdAt: resumedAt,
      lastCursor: journalReceipt?.lastCursor ?? recovery?.resumeCursor ?? checkpointRecord.snapshot.lastCursor,
      payload: try checkpointPayload(
        runAggregate: resumedRun,
        sessionHeader: restoredSessionHeader,
        goalTitle: restoredSessionHeader.title
      )
    )
    _ = try await checkpointStore.save(.init(pointer: pointer, snapshot: updatedSnapshot))
    try await persistCmpLocalRuntimeTruth(
      dependencies: dependencies,
      runID: command.runID,
      sessionID: sessionID,
      goalTitle: restoredSessionHeader.title,
      phase: resumedRun.phase,
      checkpointReference: pointer.checkpointID.rawValue,
      timestamp: resumedAt,
      followUpAction: followUpAction
    )

    return PraxisRunExecution(
      runID: command.runID,
      sessionID: sessionID,
      phase: resumedRun.phase,
      tickCount: resumedRun.tickCount,
      journalSequence: journalReceipt?.lastCursor?.sequence ?? recovery?.resumeCursor?.sequence,
      checkpointReference: pointer.checkpointID.rawValue,
      recoveredEventCount: recovery?.replayedEvents.count ?? 0,
      followUpAction: followUpAction
    )
  }
}

public final class PraxisInspectTapUseCase: PraxisInspectTapUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the current Swift TAP domain inspection snapshot for facades and presentation bridges.
  ///
  /// - Returns: A TAP inspection that aggregates governance, context, tool-review, and runtime layers.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisTapInspection {
    let capabilityIDs = hostCapabilityIDs(from: dependencies)
    let checkpointRecord = try await dependencies.hostAdapters.checkpointStore?.load(pointer: tapInspectionCheckpointPointer)
    let replaySlice = try await dependencies.hostAdapters.journalStore?.read(
      .init(sessionID: tapInspectionSessionID.rawValue, limit: 5)
    )
    let replayedEventCount = replaySlice?.events.count ?? 0
    let replaySummary = replayedEventCount > 0
      ? "Recent replay evidence contains \(replayedEventCount) journal events."
      : "No TAP replay events are currently stored for the inspection session."
    let persistenceSummary = checkpointRecord != nil
      ? "A TAP checkpoint snapshot is available for inspection and recovery."
      : "No TAP checkpoint snapshot has been persisted for the inspection session yet."

    let governance = PraxisTapGovernanceObject(
      mode: .standard,
      riskLevel: capabilityIDs.contains(.init(rawValue: "workspace.write")) || capabilityIDs.contains(.init(rawValue: "tool.shell"))
        ? .risky
        : .normal,
      capabilityIDs: capabilityIDs
    )
    let governanceSnapshot = PraxisGovernanceSnapshot(
      governance: governance,
      summary: "当前 TAP inspection 汇总了 governance、context、tool-review 和 runtime 四层状态。\(summarizeRegisteredHostSurfaces(from: dependencies))"
    )
    let reviewContext = PraxisReviewContextAperture(
      projectSummary: .init(summary: "Swift TAP domain rules are available for inspection.", status: .ready, source: "usecase"),
      runSummary: .init(summary: replaySummary, status: replayedEventCount > 0 ? .ready : .pending, source: "usecase"),
      userIntentSummary: .init(summary: "Inspect current TAP domain state", status: .ready, source: "usecase"),
      inventorySnapshot: .init(
        totalCapabilities: governance.capabilityIDs.count,
        availableCapabilityIDs: governance.capabilityIDs
      ),
      riskSummary: .init(
        requestedAction: "Inspect current TAP domain state",
        riskLevel: .risky,
        plainLanguageSummary: "这次 inspection 会读取已注册的宿主能力面与 replay/readback 状态，但不会触发真实工具执行。",
        whyItIsRisky: "如果把 inspection 暴露出来的已注册能力误当成“已经完全联通的 live 执行链”，后续集成会偏。",
        possibleConsequence: "调用方可能高估当前 HostRuntime 已接通的程度。",
        whatHappensIfNotRun: "TAP 当前仍缺少一条把宿主装配状态翻译成 plain-language inspection 的稳定入口。",
        availableUserActions: [
          .init(actionID: "review-domain", label: "查看规则", summary: "先确认 TAP 领域规则和 inspection 输出")
        ]
      ),
      sections: [
        .init(
          sectionID: "tap-bridge",
          title: "TAP bridge",
          summary: persistenceSummary,
          status: .ready,
          freshness: checkpointRecord != nil ? .fresh : .stale,
          trustLevel: .verified
        )
      ],
      forbiddenObjects: [
        .init(kind: .runtimeHandle, summary: "Live runtime handle 不会直接进入 governance aperture。")
      ],
      mode: governance.mode
    )
    let toolReviewReport = PraxisToolReviewReport(
      session: .init(
        sessionID: "tap-tool-review.snapshot",
        status: .open,
        actions: [
          .init(
            reviewID: "review.snapshot",
            sessionID: "tap-tool-review.snapshot",
            governanceKind: .activation,
            capabilityID: governance.capabilityIDs.last,
            status: .recorded,
            summary: "Current inspection includes a recorded governance action with host surface visibility but without live handoff execution.",
            recordedAt: "2026-04-10T12:00:00Z"
          )
        ]
      ),
      latestDecision: .init(route: .toolReview, summary: "High-side-effect capabilities still route through the tool-review surface."),
      latestResult: nil,
      signals: [
        .init(kind: "governance_snapshot", active: true, summary: "Inspection currently reports governance evidence without executing runtime handoff.")
      ],
      advisories: [
        .init(code: "runtime_integration_pending", severity: .risky, summary: "\(persistenceSummary) \(replaySummary)")
      ]
    )
    let runtimeSnapshot = PraxisTapRuntimeSnapshot(
      controlPlaneState: .init(
        sessionID: tapInspectionSessionID,
        governance: governance,
        humanGateState: .notRequired
      ),
      checkpointPointer: checkpointRecord?.pointer
    )
    return PraxisTapInspection(
      summary: "TAP inspection reports the current Swift TAP domain snapshot through HostRuntime. \(persistenceSummary) \(replaySummary)",
      governanceSnapshot: governanceSnapshot,
      reviewContext: reviewContext,
      toolReviewReport: toolReviewReport,
      runtimeSnapshot: runtimeSnapshot
    )
  }
}

public final class PraxisInspectCmpUseCase: PraxisInspectCmpUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the inspection output for the current CMP local-runtime assumptions.
  ///
  /// - Returns: An inspection result that describes the current Swift CMP runtime profile.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisCmpInspection {
    let readback = try await buildCmpProjectReadback(
      projectID: cmpLocalRuntimeProjectID,
      dependencies: dependencies
    )
    let deliveryTruthRecords = try await dependencies.hostAdapters.deliveryTruthStore?.lookup(
      .init(topic: cmpLocalRuntimeDeliveryTopic)
    ) ?? []
    let semanticSearchAvailable = dependencies.hostAdapters.semanticSearchIndex != nil
    let semanticMemoryAvailable = dependencies.hostAdapters.semanticMemoryStore != nil
    let embeddingStoreAvailable = dependencies.hostAdapters.embeddingStore != nil
    let gitReport = await dependencies.hostAdapters.gitAvailabilityProbe?.probeGitReadiness()
    let gitStatus = cmpGitStatusSummary(gitReport)
    let gitExecutorStatus = await cmpGitExecutorSummary(from: dependencies)

    let runtimeProfile = PraxisCmpLocalRuntimeProfile(
      structuredStoreSummary: readback.persistenceSummary,
      deliveryStoreSummary: cmpDeliverySummary(
        deliveryTruthRecords: deliveryTruthRecords,
        messageBusAvailable: dependencies.hostAdapters.messageBus != nil
      ),
      messageBusSummary: readback.coordinationSummary,
      gitSummary: "\(gitStatus.summary) \(gitExecutorStatus.summary)",
      semanticIndexSummary: cmpSemanticIndexSummary(
        semanticSearchAvailable: semanticSearchAvailable,
        semanticMemoryAvailable: semanticMemoryAvailable,
        embeddingStoreAvailable: embeddingStoreAvailable
      )
    )
    return PraxisCmpInspection(
      runtimeProfile: runtimeProfile,
      summary: "CMP inspection now reads the current HostRuntime local profile, workspace, git, and lineage state instead of a static assumption.",
      projectID: readback.projectID,
      issues: readback.issues,
      hostSummary: readback.hostSummary
    )
  }
}

public final class PraxisOpenCmpSessionUseCase: PraxisOpenCmpSessionUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Creates a host-neutral CMP session descriptor without binding callers to CLI or UI concerns.
  ///
  /// - Parameter command: The neutral session-open command.
  /// - Returns: A CMP session descriptor backed by the current host runtime profile.
  /// - Throws: Propagates any readback errors needed to summarize the project host profile.
  public func execute(_ command: PraxisOpenCmpSessionCommand) async throws -> PraxisCmpSession {
    let readback = try await buildCmpProjectReadback(projectID: command.projectID, dependencies: dependencies)
    let sessionID = command.sessionID ?? "cmp.session.\(UUID().uuidString.lowercased())"
    return PraxisCmpSession(
      sessionID: sessionID,
      projectID: command.projectID,
      summary: "Opened host-neutral CMP session \(sessionID) for project \(command.projectID). Local runtime profile: \(readback.hostSummary)",
      createdAt: runtimeNow(),
      hostProfile: readback.hostProfile,
      issues: readback.issues
    )
  }
}

public final class PraxisReadbackCmpProjectUseCase: PraxisReadbackCmpProjectUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Reads the current CMP project state through the neutral host runtime surface.
  ///
  /// - Parameter command: The project readback command.
  /// - Returns: A structured readback summary for the requested project.
  /// - Throws: Propagates host adapter failures encountered while reading local runtime truth.
  public func execute(_ command: PraxisReadbackCmpProjectCommand) async throws -> PraxisCmpProjectReadback {
    try await buildCmpProjectReadback(projectID: command.projectID, dependencies: dependencies)
  }
}

public final class PraxisBootstrapCmpProjectUseCase: PraxisBootstrapCmpProjectUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds a host-neutral CMP project bootstrap receipt by composing git, db, mq, and lineage planners.
  ///
  /// - Parameter command: The neutral project bootstrap command.
  /// - Returns: A structured bootstrap receipt for the requested project.
  /// - Throws: Propagates host adapter failures encountered while persisting lineage descriptors or inferring topology.
  public func execute(_ command: PraxisBootstrapCmpProjectCommand) async throws -> PraxisCmpProjectBootstrap {
    try await bootstrapCmpProject(command: command, dependencies: dependencies)
  }
}

public final class PraxisIngestCmpFlowUseCase: PraxisIngestCmpFlowUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Ingests runtime materials into the neutral CMP flow surface.
  ///
  /// - Parameter command: The neutral flow-ingest command.
  /// - Returns: A structured ingest receipt with section and role-assignment context.
  /// - Throws: Propagates validation or lineage lookup failures.
  public func execute(_ command: PraxisIngestCmpFlowCommand) async throws -> PraxisCmpFlowIngest {
    try await ingestCmpFlow(command: command, dependencies: dependencies)
  }
}

public final class PraxisCommitCmpFlowUseCase: PraxisCommitCmpFlowUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Commits accepted CMP flow events into a context delta and snapshot candidate.
  ///
  /// - Parameter command: The neutral flow-commit command.
  /// - Returns: A commit receipt containing the delta, candidate, and active-line stage.
  /// - Throws: Propagates validation or lineage lookup failures.
  public func execute(_ command: PraxisCommitCmpFlowCommand) async throws -> PraxisCmpFlowCommit {
    try await commitCmpFlow(command: command, dependencies: dependencies)
  }
}

public final class PraxisResolveCmpFlowUseCase: PraxisResolveCmpFlowUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Resolves the best available checked snapshot through the neutral CMP flow surface.
  ///
  /// - Parameter command: The neutral flow-resolve command.
  /// - Returns: A resolve receipt that either carries a checked snapshot or a stable not-found result.
  /// - Throws: Propagates lineage lookup failures.
  public func execute(_ command: PraxisResolveCmpFlowCommand) async throws -> PraxisCmpFlowResolve {
    try await resolveCmpFlow(command: command, dependencies: dependencies)
  }
}

public final class PraxisMaterializeCmpFlowUseCase: PraxisMaterializeCmpFlowUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Materializes a host-neutral CMP context package from projection-backed checked state.
  ///
  /// - Parameter command: The neutral flow-materialize command.
  /// - Returns: A materialization receipt with the selected projection and context package.
  /// - Throws: Propagates projection lookup or validation failures.
  public func execute(_ command: PraxisMaterializeCmpFlowCommand) async throws -> PraxisCmpFlowMaterialize {
    try await materializeCmpFlow(command: command, dependencies: dependencies)
  }
}

public final class PraxisDispatchCmpFlowUseCase: PraxisDispatchCmpFlowUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Dispatches a materialized CMP context package through the neutral delivery surface.
  ///
  /// - Parameter command: The neutral flow-dispatch command.
  /// - Returns: A dispatch receipt and delivery plan for the requested target.
  /// - Throws: Propagates validation or host transport failures.
  public func execute(_ command: PraxisDispatchCmpFlowCommand) async throws -> PraxisCmpFlowDispatch {
    try await dispatchCmpFlow(command: command, dependencies: dependencies)
  }
}

public final class PraxisRequestCmpHistoryUseCase: PraxisRequestCmpHistoryUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Requests reusable historical CMP context without binding the caller to a host shell.
  ///
  /// - Parameter command: The neutral history-request command.
  /// - Returns: A historical context result that may include a snapshot and pre-materialized package.
  /// - Throws: Propagates host projection lookup failures.
  public func execute(_ command: PraxisRequestCmpHistoryCommand) async throws -> PraxisCmpFlowHistory {
    try await requestCmpHistory(command: command, dependencies: dependencies)
  }
}

public final class PraxisReadbackCmpStatusUseCase: PraxisReadbackCmpStatusUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Reads a host-neutral CMP status panel that summarizes roles, control defaults, and object-model readiness.
  ///
  /// - Parameter command: The neutral status-readback command.
  /// - Returns: A compact status panel reconstructed from current host-backed runtime truth.
  /// - Throws: Propagates host store lookup failures.
  public func execute(_ command: PraxisReadbackCmpStatusCommand) async throws -> PraxisCmpStatusReadback {
    try await readbackCmpStatus(command: command, dependencies: dependencies)
  }
}

public final class PraxisSmokeCmpProjectUseCase: PraxisSmokeCmpProjectUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds a compact smoke report for one CMP project without exposing CLI-specific semantics.
  ///
  /// - Parameter command: The project smoke command.
  /// - Returns: A neutral smoke report summarizing the current project runtime readiness.
  /// - Throws: Propagates host adapter failures encountered while building the smoke report.
  public func execute(_ command: PraxisSmokeCmpProjectCommand) async throws -> PraxisCmpProjectSmoke {
    let readback = try await buildCmpProjectReadback(projectID: command.projectID, dependencies: dependencies)
    return PraxisCmpProjectSmoke(
      projectID: command.projectID,
      summary: "CMP smoke now summarizes project-level local runtime readiness through the neutral host runtime surface.",
      checks: [
        .init(
          id: "cmp.project.workspace",
          gate: "workspace",
          status: readback.componentStatuses["workspace"] ?? "missing",
          summary: "Workspace readiness is \(readback.componentStatuses["workspace"] ?? "missing")."
        ),
        .init(
          id: "cmp.project.persistence",
          gate: "persistence",
          status: readback.componentStatuses["structuredStore"] ?? "missing",
          summary: readback.persistenceSummary
        ),
        .init(
          id: "cmp.project.delivery",
          gate: "delivery",
          status: readback.componentStatuses["deliveryTruth"] ?? "missing",
          summary: "Delivery coordination summary: \(readback.coordinationSummary)"
        ),
        .init(
          id: "cmp.project.git",
          gate: "git",
          status: readback.componentStatuses["gitExecutor"] ?? "missing",
          summary: readback.hostSummary
        ),
        .init(
          id: "cmp.project.lineage",
          gate: "lineage",
          status: readback.componentStatuses["lineageStore"] ?? "missing",
          summary: readback.issues.first(where: { $0.contains("Lineage") }) ?? "Lineage readiness is \(readback.componentStatuses["lineageStore"] ?? "missing")."
        ),
      ]
    )
  }
}

public final class PraxisInspectMpUseCase: PraxisInspectMpUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Builds the inspection output for the current reserved MP workflow surface.
  ///
  /// - Returns: An inspection result that describes the MP workflow, memory store, and multimodal surface.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> PraxisMpInspection {
    let memoryBundle = try await dependencies.hostAdapters.semanticMemoryStore?.bundle(
      .init(
        projectID: "mp.local-runtime",
        query: "",
        scopeLevels: [.global, .project, .agent, .session],
        includeSuperseded: false
      )
    )
    let semanticMatches = try await dependencies.hostAdapters.semanticSearchIndex?.search(
      .init(query: "host runtime", limit: 3)
    ) ?? []
    let memoryStoreSummary: String
    if let memoryBundle {
      memoryStoreSummary = "Semantic memory bundle exposes \(memoryBundle.primaryMemoryIDs.count) primary records and omits \(memoryBundle.omittedSupersededMemoryIDs.count) superseded records."
    } else {
      memoryStoreSummary = "Semantic memory store is not wired into HostRuntime yet."
    }

    let workflowSummary = dependencies.hostAdapters.providerInferenceExecutor != nil
      ? "ICMA / Iterator / Checker / DbAgent / Dispatcher lanes now have a provider inference surface available for future host-backed execution."
      : "Five-agent lanes remain Core-side protocols until a provider inference surface is composed."

    var issues: [String] = []
    if dependencies.hostAdapters.semanticMemoryStore == nil {
      issues.append("MP runtime still needs a semantic memory store adapter on the Swift side.")
    }
    if dependencies.hostAdapters.semanticSearchIndex == nil {
      issues.append("MP runtime still needs a semantic search index adapter on the Swift side.")
    }
    if semanticMatches.isEmpty {
      issues.append("No semantic search matches are currently available for the local MP inspection query.")
    }
    if dependencies.hostAdapters.browserGroundingCollector == nil
      || dependencies.hostAdapters.audioTranscriptionDriver == nil
      || dependencies.hostAdapters.speechSynthesisDriver == nil
      || dependencies.hostAdapters.imageGenerationDriver == nil {
      issues.append("Browser grounding and multimodal chips still need the full host adapter set.")
    }

    return PraxisMpInspection(
      summary: "MP workflow surface is now reading HostRuntime memory and multimodal adapter state.",
      workflowSummary: workflowSummary,
      memoryStoreSummary: "\(memoryStoreSummary) Semantic search matches for inspection query: \(semanticMatches.count).",
      multimodalSummary: mpMultimodalSummary(from: dependencies),
      issues: issues
    )
  }
}

public final class PraxisBuildCapabilityCatalogUseCase: PraxisBuildCapabilityCatalogUseCaseProtocol {
  public let dependencies: PraxisDependencyGraph

  public init(dependencies: PraxisDependencyGraph) {
    self.dependencies = dependencies
  }

  /// Returns a summary description of the capability catalog from the current dependency graph.
  ///
  /// - Returns: A textual capability-catalog summary containing the current set of boundary names.
  /// - Throws: This implementation does not actively throw, but it propagates underlying errors from the call chain.
  public func execute() async throws -> String {
    buildCapabilityCatalogSummary(from: dependencies)
  }
}
