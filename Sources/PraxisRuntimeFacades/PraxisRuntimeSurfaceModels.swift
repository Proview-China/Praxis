public enum PraxisTruthLayerStatus: String, Sendable, Codable {
  case ready
  case degraded
  case failed
}

public struct PraxisRuntimeControlSurface: Sendable, Equatable, Codable {
  public let executionStyle: String
  public let readbackPriority: String
  public let fallbackPolicy: String

  public init(executionStyle: String, readbackPriority: String, fallbackPolicy: String) {
    self.executionStyle = executionStyle
    self.readbackPriority = readbackPriority
    self.fallbackPolicy = fallbackPolicy
  }
}

public struct PraxisCmpProjectReadbackSummary: Sendable, Equatable, Codable {
  public let projectID: String
  public let controlSurface: PraxisRuntimeControlSurface
  public let truthLayers: [String: PraxisTruthLayerStatus]
  public let issues: [String]

  public init(
    projectID: String,
    controlSurface: PraxisRuntimeControlSurface,
    truthLayers: [String: PraxisTruthLayerStatus],
    issues: [String]
  ) {
    self.projectID = projectID
    self.controlSurface = controlSurface
    self.truthLayers = truthLayers
    self.issues = issues
  }
}

public struct PraxisRuntimeSmokeCheck: Sendable, Equatable, Codable, Identifiable {
  public let id: String
  public let gate: String
  public let status: PraxisTruthLayerStatus
  public let summary: String

  public init(id: String, gate: String, status: PraxisTruthLayerStatus, summary: String) {
    self.id = id
    self.gate = gate
    self.status = status
    self.summary = summary
  }
}

public struct PraxisRuntimeSmokeResult: Sendable, Equatable, Codable {
  public let summary: String
  public let checks: [PraxisRuntimeSmokeCheck]

  public init(summary: String, checks: [PraxisRuntimeSmokeCheck]) {
    self.summary = summary
    self.checks = checks
  }
}
