/// Identifies the stable host-neutral automation switches CMP control surfaces can toggle.
public enum PraxisCmpAutomationKey: String, Sendable, CaseIterable, Codable {
  case autoIngest
  case autoCommit
  case autoResolve
  case autoMaterialize
  case autoDispatch
  case autoReturnToCoreAgent
  case autoSeedChildren
}

/// Stores CMP automation toggles behind stable host-neutral keys while preserving raw-key codec compatibility.
public struct PraxisCmpAutomationMap: Sendable, Equatable, Codable {
  public static let empty = Self(values: [:])

  public static let allEnabled = Self(
    values: Dictionary(
      uniqueKeysWithValues: PraxisCmpAutomationKey.allCases.map { ($0, true) }
    )
  )

  public let values: [PraxisCmpAutomationKey: Bool]

  public init(values: [PraxisCmpAutomationKey: Bool]) {
    self.values = values
  }

  public subscript(_ key: PraxisCmpAutomationKey) -> Bool? {
    values[key]
  }

  public var isEmpty: Bool {
    values.isEmpty
  }

  public func isEnabled(_ key: PraxisCmpAutomationKey, default defaultValue: Bool = true) -> Bool {
    values[key] ?? defaultValue
  }

  public func merging(_ overrides: Self) -> Self {
    Self(values: values.merging(overrides.values) { _, new in new })
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: DynamicCodingKey.self)
    var decodedValues: [PraxisCmpAutomationKey: Bool] = [:]

    for key in container.allKeys {
      guard let automationKey = PraxisCmpAutomationKey(rawValue: key.stringValue) else {
        throw DecodingError.dataCorruptedError(
          forKey: key,
          in: container,
          debugDescription: "Invalid CMP automation key \(key.stringValue)."
        )
      }

      decodedValues[automationKey] = try container.decode(Bool.self, forKey: key)
    }

    self.init(values: decodedValues)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: DynamicCodingKey.self)

    for key in values.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
      let codingKey = DynamicCodingKey(stringValue: key.rawValue)!
      try container.encode(values[key], forKey: codingKey)
    }
  }

  private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
      self.stringValue = stringValue
      self.intValue = nil
    }

    init?(intValue: Int) {
      self.stringValue = String(intValue)
      self.intValue = intValue
    }
  }
}
