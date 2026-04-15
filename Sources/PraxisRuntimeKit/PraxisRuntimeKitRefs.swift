/// Stable RuntimeKit wrapper for one project identifier.
public struct PraxisRuntimeProjectRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one agent identifier.
public struct PraxisRuntimeAgentRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one session identifier.
public struct PraxisRuntimeSessionRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one run identifier.
public struct PraxisRuntimeRunRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one memory identifier.
public struct PraxisRuntimeMemoryRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one capability identifier.
public struct PraxisRuntimeCapabilityRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one replay identifier.
public struct PraxisRuntimeReplayRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one CMP package identifier.
public struct PraxisRuntimeCmpPackageRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one CMP snapshot identifier.
public struct PraxisRuntimeCmpSnapshotRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}

/// Stable RuntimeKit wrapper for one CMP projection identifier.
public struct PraxisRuntimeCmpProjectionRef: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  public var description: String {
    rawValue
  }
}
