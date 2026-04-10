import PraxisCoreTypes

public struct PraxisSessionID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum PraxisSessionTemperature: String, Sendable, Codable {
  case hot
  case warm
  case cold
}

public struct PraxisSessionHeader: Sendable, Equatable, Codable {
  public let id: PraxisSessionID
  public let title: String
  public let temperature: PraxisSessionTemperature

  public init(id: PraxisSessionID, title: String, temperature: PraxisSessionTemperature) {
    self.id = id
    self.title = title
    self.temperature = temperature
  }
}

public struct PraxisSessionAttachment: Sendable, Equatable, Codable {
  public let sessionID: PraxisSessionID
  public let runReference: String?

  public init(sessionID: PraxisSessionID, runReference: String?) {
    self.sessionID = sessionID
    self.runReference = runReference
  }
}
