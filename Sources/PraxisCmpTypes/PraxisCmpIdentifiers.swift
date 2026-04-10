import PraxisCoreTypes

public struct PraxisCmpSectionID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisCmpPackageID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisCmpProjectionID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct PraxisCmpLineageID: PraxisIdentifier {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
