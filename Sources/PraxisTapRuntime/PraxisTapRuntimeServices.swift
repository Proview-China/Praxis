public struct PraxisActivationLifecycleService: Sendable {
  public init() {}
}

public actor PraxisTapRuntimeCoordinator {
  public private(set) var snapshot: PraxisTapRuntimeSnapshot?

  public init(snapshot: PraxisTapRuntimeSnapshot? = nil) {
    self.snapshot = snapshot
  }
}
