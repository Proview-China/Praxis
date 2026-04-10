public actor PraxisFiveAgentCoordinator {
  public private(set) var protocolDefinition: PraxisFiveAgentProtocolDefinition?

  public init(protocolDefinition: PraxisFiveAgentProtocolDefinition? = nil) {
    self.protocolDefinition = protocolDefinition
  }
}
