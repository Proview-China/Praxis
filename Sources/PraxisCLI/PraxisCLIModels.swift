import PraxisRuntimePresentationBridge

public struct PraxisCLIConfiguration: Sendable, Equatable, Codable {
  public let interactive: Bool

  public init(interactive: Bool) {
    self.interactive = interactive
  }
}

public struct PraxisCLICommand: Sendable, Equatable, Codable {
  public let intent: PraxisPresentationIntent
  public let payloadSummary: String

  public init(intent: PraxisPresentationIntent, payloadSummary: String) {
    self.intent = intent
    self.payloadSummary = payloadSummary
  }

  public var presentationCommand: PraxisPresentationCommand {
    PraxisPresentationCommand(intent: intent, payloadSummary: payloadSummary)
  }
}
