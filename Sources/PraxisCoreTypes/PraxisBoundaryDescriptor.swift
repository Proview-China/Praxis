public struct PraxisBoundaryDescriptor: Sendable, Equatable, Identifiable, Codable {
  public let name: String
  public let responsibility: String
  public let tsModules: [String]

  public var id: String {
    name
  }

  public init(
    name: String,
    responsibility: String,
    tsModules: [String] = [],
  ) {
    self.name = name
    self.responsibility = responsibility
    self.tsModules = tsModules
  }
}

public extension PraxisBoundaryDescriptor {
  var displayLabel: String {
    "\(name): \(responsibility)"
  }
}
