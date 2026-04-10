public enum PraxisTapMode: String, Sendable, Codable {
  case normal
  case careful
  case restricted
}

public enum PraxisTapRiskLevel: String, Sendable, Codable {
  case low
  case medium
  case high
  case critical
}

public enum PraxisTapReviewKind: String, Sendable, Codable {
  case automated
  case human
  case tool
}

public enum PraxisTapProvisionKind: String, Sendable, Codable {
  case capability
  case tool
  case workspace
}

public enum PraxisHumanGateState: String, Sendable, Codable {
  case notRequired
  case waitingApproval
  case approved
  case rejected
}
