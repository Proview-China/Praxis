import PraxisRun
import PraxisRuntimeFacades
import PraxisSession

public enum PraxisRuntimeInterfaceCommandKind: String, Sendable, Equatable, Codable {
  case inspectArchitecture
  case runGoal
  case resumeRun
  case inspectTap
  case inspectCmp
  case inspectMp
  case buildCapabilityCatalog
}

public struct PraxisRuntimeInterfaceRequest: Sendable, Equatable, Codable {
  public let kind: PraxisRuntimeInterfaceCommandKind
  public let payloadSummary: String
  public let goalID: String?
  public let goalTitle: String?
  public let sessionID: String?
  public let runID: String?

  public init(
    kind: PraxisRuntimeInterfaceCommandKind,
    payloadSummary: String = "",
    goalID: String? = nil,
    goalTitle: String? = nil,
    sessionID: String? = nil,
    runID: String? = nil
  ) {
    self.kind = kind
    self.payloadSummary = payloadSummary
    self.goalID = goalID
    self.goalTitle = goalTitle
    self.sessionID = sessionID
    self.runID = runID
  }
}

public enum PraxisRuntimeInterfaceSnapshotKind: String, Sendable, Equatable, Codable {
  case architecture
  case run
  case inspection
  case catalog
}

public struct PraxisRuntimeInterfaceSnapshot: Sendable, Equatable, Codable {
  public let kind: PraxisRuntimeInterfaceSnapshotKind
  public let title: String
  public let summary: String
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let phase: PraxisRunPhase?
  public let tickCount: Int?
  public let lifecycleDisposition: PraxisRunLifecycleDisposition?
  public let checkpointReference: String?
  public let pendingIntentID: String?
  public let recoveredEventCount: Int?

  public init(
    kind: PraxisRuntimeInterfaceSnapshotKind,
    title: String,
    summary: String,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    phase: PraxisRunPhase? = nil,
    tickCount: Int? = nil,
    lifecycleDisposition: PraxisRunLifecycleDisposition? = nil,
    checkpointReference: String? = nil,
    pendingIntentID: String? = nil,
    recoveredEventCount: Int? = nil
  ) {
    self.kind = kind
    self.title = title
    self.summary = summary
    self.runID = runID
    self.sessionID = sessionID
    self.phase = phase
    self.tickCount = tickCount
    self.lifecycleDisposition = lifecycleDisposition
    self.checkpointReference = checkpointReference
    self.pendingIntentID = pendingIntentID
    self.recoveredEventCount = recoveredEventCount
  }
}

public struct PraxisRuntimeInterfaceEvent: Sendable, Equatable, Codable {
  public let name: String
  public let detail: String
  public let runID: PraxisRunID?
  public let sessionID: PraxisSessionID?
  public let intentID: String?

  public init(
    name: String,
    detail: String,
    runID: PraxisRunID? = nil,
    sessionID: PraxisSessionID? = nil,
    intentID: String? = nil
  ) {
    self.name = name
    self.detail = detail
    self.runID = runID
    self.sessionID = sessionID
    self.intentID = intentID
  }
}

public struct PraxisRuntimeInterfaceResponse: Sendable, Equatable, Codable {
  public let snapshot: PraxisRuntimeInterfaceSnapshot
  public let events: [PraxisRuntimeInterfaceEvent]

  public init(
    snapshot: PraxisRuntimeInterfaceSnapshot,
    events: [PraxisRuntimeInterfaceEvent] = []
  ) {
    self.snapshot = snapshot
    self.events = events
  }
}
