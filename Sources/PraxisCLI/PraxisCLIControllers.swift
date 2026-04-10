import PraxisRuntimePresentationBridge

public final class PraxisCLIApp {
  public let configuration: PraxisCLIConfiguration
  public let bridge: PraxisCLICommandBridge

  public init(configuration: PraxisCLIConfiguration, bridge: PraxisCLICommandBridge) {
    self.configuration = configuration
    self.bridge = bridge
  }

  public convenience init(
    configuration: PraxisCLIConfiguration
  ) throws {
    try self.init(
      configuration: configuration,
      bridge: PraxisRuntimeBridgeFactory.makeCLICommandBridge()
    )
  }

  public func bootstrapState() -> PraxisPresentationState {
    PraxisPresentationStateMapper().mapBlueprintSummary()
  }
}

public final class PraxisCLICommandRouter {
  public let bridge: PraxisCLICommandBridge

  public init(bridge: PraxisCLICommandBridge) {
    self.bridge = bridge
  }

  public convenience init() throws {
    try self.init(bridge: PraxisRuntimeBridgeFactory.makeCLICommandBridge())
  }

  public func route(_ command: PraxisCLICommand) async throws -> PraxisPresentationState {
    try await bridge.handle(command.presentationCommand)
  }
}

public actor PraxisInteractiveSessionController {
  public private(set) var history: [PraxisCLICommand]

  public init(history: [PraxisCLICommand] = []) {
    self.history = history
  }

  public func append(_ command: PraxisCLICommand) {
    history.append(command)
  }
}

public final class PraxisTerminalRenderer {
  public init() {}
}
