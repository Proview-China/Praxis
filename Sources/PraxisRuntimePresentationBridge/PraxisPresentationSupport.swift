import PraxisRuntimeFacades

public struct PraxisPresentationStateMapper: Sendable {
  public init() {}

  public func mapBlueprintSummary() -> PraxisPresentationState {
    PraxisPresentationState(
      title: "Praxis Architecture",
      summary: "Foundation \(PraxisRuntimePresentationBridgeModule.bootstrap.foundationModules.count) / Domain \(PraxisRuntimePresentationBridgeModule.bootstrap.functionalDomainModules.count) / Host \(PraxisRuntimePresentationBridgeModule.bootstrap.hostContractModules.count + PraxisRuntimePresentationBridgeModule.bootstrap.runtimeModules.count)"
    )
  }

  public func map(runSummary: PraxisRunSummary) -> PraxisPresentationState {
    PraxisPresentationState(
      title: "Run \(runSummary.runID.rawValue)",
      summary: runSummary.phaseSummary,
      pendingIntentID: runSummary.followUpAction?.intentID,
      events: mapRunEvents(from: runSummary)
    )
  }

  public func map(tapInspection: PraxisTapInspectionSnapshot) -> PraxisPresentationState {
    PraxisPresentationState(
      title: "TAP Inspection",
      summary: "\(tapInspection.summary) Governance: \(tapInspection.governanceSummary)"
    )
  }

  public func map(cmpInspection: PraxisCmpInspectionSnapshot) -> PraxisPresentationState {
    PraxisPresentationState(
      title: "CMP Inspection",
      summary: "\(cmpInspection.projectID): \(cmpInspection.hostRuntimeSummary)"
    )
  }

  public func map(mpInspection: PraxisMpInspectionSnapshot) -> PraxisPresentationState {
    PraxisPresentationState(
      title: "MP Inspection",
      summary: "\(mpInspection.summary) Store: \(mpInspection.memoryStoreSummary)"
    )
  }

  public func map(catalogSnapshot: PraxisInspectionSnapshot) -> PraxisPresentationState {
    PraxisPresentationState(
      title: "Capability Catalog",
      summary: catalogSnapshot.summary
    )
  }

  public func mapRunEvents(from runSummary: PraxisRunSummary) -> [PraxisPresentationEvent] {
    let lifecycleEventName: String
    switch runSummary.lifecycleDisposition {
    case .started:
      lifecycleEventName = "run.started"
    case .resumed:
      lifecycleEventName = "run.resumed"
    case .recoveredWithoutResume:
      lifecycleEventName = "run.recovered"
    }

    var events: [PraxisPresentationEvent] = [
      PraxisPresentationEvent(
        name: lifecycleEventName,
        detail: runSummary.phaseSummary,
        runID: runSummary.runID.rawValue,
        sessionID: runSummary.sessionID.rawValue,
        intentID: runSummary.followUpAction?.intentID
      )
    ]

    if let followUpAction = runSummary.followUpAction {
      events.append(
        PraxisPresentationEvent(
          name: "run.follow_up_ready",
          detail: "\(followUpAction.kind.rawValue): \(followUpAction.reason)",
          runID: runSummary.runID.rawValue,
          sessionID: runSummary.sessionID.rawValue,
          intentID: followUpAction.intentID
        )
      )
    }

    return events
  }
}

public actor PraxisPresentationEventStream {
  public private(set) var events: [PraxisPresentationEvent]

  public init(events: [PraxisPresentationEvent] = []) {
    self.events = events
  }

  public func append(_ event: PraxisPresentationEvent) {
    events.append(event)
  }

  public func append(contentsOf newEvents: [PraxisPresentationEvent]) {
    events.append(contentsOf: newEvents)
  }

  public func snapshot() -> [PraxisPresentationEvent] {
    events
  }

  public func drain() -> [PraxisPresentationEvent] {
    let snapshot = events
    events = []
    return snapshot
  }
}
