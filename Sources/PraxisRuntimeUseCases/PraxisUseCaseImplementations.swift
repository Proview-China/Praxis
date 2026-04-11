import PraxisCapabilityContracts
import PraxisCapabilityPlanning
import PraxisCheckpoint
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
    let gitReport = await dependencies.hostAdapters.gitAvailabilityProbe?.probeGitReadiness()
    let gitStatus = cmpGitStatusSummary(gitReport)
    let projectionDescriptors = try await dependencies.hostAdapters.projectionStore?.describe(
      .init(projectID: "cmp.local-runtime")
    ) ?? []
    let deliveryTruthRecords = try await dependencies.hostAdapters.deliveryTruthStore?.lookup(
      .init(topic: "cmp.delivery")
    ) ?? []
    let checkpointStoreAvailable = dependencies.hostAdapters.checkpointStore != nil
    let journalStoreAvailable = dependencies.hostAdapters.journalStore != nil
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

    let runtimeProfile = PraxisCmpLocalRuntimeProfile(
      structuredStoreSummary: structuredStoreSummary,
      deliveryStoreSummary: cmpDeliverySummary(
        deliveryTruthRecords: deliveryTruthRecords,
        messageBusAvailable: messageBusAvailable
      ),
      messageBusSummary: messageBusAvailable
        ? "Neighborhood fan-out can flow through the registered host message bus."
        : "Neighborhood fan-out still needs a host message bus adapter.",
      gitSummary: "\(gitStatus.summary) \(gitExecutorStatus.summary)",
      semanticIndexSummary: cmpSemanticIndexSummary(
        semanticSearchAvailable: semanticSearchAvailable,
        semanticMemoryAvailable: semanticMemoryAvailable,
        embeddingStoreAvailable: embeddingStoreAvailable
      )
    )
    var issues: [String] = []
    if projectionDescriptors.isEmpty {
      issues.append("Projection store is wired but currently has no descriptors for cmp.local-runtime.")
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

    let hostSummary = "macOS local runtime / workspace (\(workspaceStatus.statusWord)) / sqlite persistence (\(projectionDescriptors.count) projections) / lineage store (\(lineageStatus.statusWord)) / sqlite delivery truth (\(deliveryTruthRecords.count) records) / actor message bus (\(messageBusAvailable ? "ready" : "missing")) / system git probe (\(gitStatus.statusWord)) / system git executor (\(gitExecutorStatus.statusWord)) / accelerate-like semantic index (\(semanticSearchAvailable ? "ready" : "missing"))"
    return PraxisCmpInspection(
      runtimeProfile: runtimeProfile,
      summary: "CMP inspection now reads the current HostRuntime local profile, workspace, git, and lineage state instead of a static assumption.",
      projectID: "cmp.local-runtime",
      issues: issues,
      hostSummary: hostSummary
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
