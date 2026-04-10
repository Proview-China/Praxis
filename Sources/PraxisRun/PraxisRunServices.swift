public struct PraxisRunLifecycleService: Sendable {
  public init() {}
}

public actor PraxisRunCoordinator {
  public private(set) var activeRun: PraxisRunAggregate?

  public init(activeRun: PraxisRunAggregate? = nil) {
    self.activeRun = activeRun
  }
}
