import PraxisCapabilityContracts
import PraxisGoal
import PraxisRun

public struct PraxisCapabilitySelection: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let reason: String

  public init(capabilityID: PraxisCapabilityID, reason: String) {
    self.capabilityID = capabilityID
    self.reason = reason
  }
}

public struct PraxisCapabilityLease: Sendable, Equatable, Codable {
  public let capabilityID: PraxisCapabilityID
  public let holder: String

  public init(capabilityID: PraxisCapabilityID, holder: String) {
    self.capabilityID = capabilityID
    self.holder = holder
  }
}

public struct PraxisCapabilityDispatchPlan: Sendable, Equatable, Codable {
  public let request: PraxisCapabilityInvocationRequest
  public let runID: PraxisRunID?

  public init(request: PraxisCapabilityInvocationRequest, runID: PraxisRunID?) {
    self.request = request
    self.runID = runID
  }
}

public struct PraxisCapabilityInvocationPlan: Sendable, Equatable, Codable {
  public let selection: PraxisCapabilitySelection
  public let dispatchPlan: PraxisCapabilityDispatchPlan
  public let lease: PraxisCapabilityLease?

  public init(
    selection: PraxisCapabilitySelection,
    dispatchPlan: PraxisCapabilityDispatchPlan,
    lease: PraxisCapabilityLease?,
  ) {
    self.selection = selection
    self.dispatchPlan = dispatchPlan
    self.lease = lease
  }
}
