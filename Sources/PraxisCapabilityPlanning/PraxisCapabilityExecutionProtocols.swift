import PraxisCapabilityContracts

public protocol PraxisCapabilityGatewaying: Sendable {
  func acquire(plan: PraxisCapabilityInvocationPlan) async throws -> PraxisCapabilityLease
  func prepare(
    lease: PraxisCapabilityLease,
    plan: PraxisCapabilityInvocationPlan
  ) async throws -> PraxisPreparedCapabilityCall
  func dispatch(_ prepared: PraxisPreparedCapabilityCall) async throws -> PraxisCapabilityExecutionHandle
  func cancel(executionID: String) async throws
}

public protocol PraxisCapabilityPooling: Sendable {
  func listBindings() async throws -> [PraxisCapabilityBinding]
  func enqueue(_ entry: PraxisCapabilityQueueEntry) async throws
  func currentBackpressure() async throws -> PraxisCapabilityBackpressureState
}

public protocol PraxisCapabilityPortBrokering: Sendable {
  func record(intent: PraxisCapabilityPortIntent) async throws
  func settle(_ result: PraxisCapabilityPortResult) async throws
}
