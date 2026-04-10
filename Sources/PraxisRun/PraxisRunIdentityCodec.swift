/// Encodes and decodes run identifiers while preserving backward compatibility.
///
/// This codec owns the string-level contract for `run:<session>:<goal>` identifiers,
/// including the compatibility rules required to read older persisted run IDs.
public struct PraxisRunIdentityCodec: Sendable {
  public static let encodedSessionPrefix = "pct~"

  /// Creates the default run identity codec.
  public init() {}

  /// Builds the default session raw value for a goal.
  ///
  /// - Parameter goalID: Goal identifier that needs a synthesized session.
  /// - Returns: The synthesized session raw value.
  public func makeDefaultSessionRawValue(for goalID: String) -> String {
    "session.\(goalID)"
  }

  /// Builds a stable run identifier from raw session and goal identifiers.
  ///
  /// - Parameters:
  ///   - sessionRawValue: Raw session identifier.
  ///   - goalID: Goal identifier that the run belongs to.
  /// - Returns: A run identifier that preserves the session component losslessly.
  public func makeRunID(sessionRawValue: String, goalID: String) -> PraxisRunID {
    .init(rawValue: "run:\(encodeSessionComponent(sessionRawValue)):\(goalID)")
  }

  /// Returns the primary session raw value implied by a run identifier.
  ///
  /// - Parameter runID: Run identifier to decode.
  /// - Returns: The preferred session raw value for the supplied run identifier.
  public func sessionRawValue(from runID: PraxisRunID) -> String {
    sessionRawValueCandidates(from: runID).first ?? makeDefaultSessionRawValue(for: runID.rawValue)
  }

  /// Returns compatible session raw values that may resolve the supplied run identifier.
  ///
  /// The first candidate is always the preferred modern interpretation. Additional
  /// candidates exist only to preserve older persisted run IDs during lookup.
  ///
  /// - Parameter runID: Run identifier to decode.
  /// - Returns: Ordered session raw value candidates.
  public func sessionRawValueCandidates(from runID: PraxisRunID) -> [String] {
    if let rawSessionComponent = rawRunSessionComponent(from: runID) {
      var candidates: [String] = [decodeSessionComponent(rawSessionComponent)]

      if !rawSessionComponent.hasPrefix(Self.encodedSessionPrefix),
         let decodedLegacyComponent = rawSessionComponent.removingPercentEncoding,
         decodedLegacyComponent != rawSessionComponent,
         !candidates.contains(decodedLegacyComponent) {
        candidates.append(decodedLegacyComponent)
      }

      return candidates
    }

    if runID.rawValue.hasPrefix("run.") {
      let suffix = runID.rawValue.dropFirst(4)
      if let goalMarker = suffix.range(of: ".goal.") {
        return [String(suffix[..<goalMarker.lowerBound])]
      }
      if let dotIndex = suffix.lastIndex(of: ".") {
        return [String(suffix[..<dotIndex])]
      }
    }

    return [makeDefaultSessionRawValue(for: runID.rawValue)]
  }

  private func encodeSessionComponent(_ rawValue: String) -> String {
    let requiresEncoding =
      rawValue.contains(":")
      || rawValue.contains("%")
      || rawValue.hasPrefix(Self.encodedSessionPrefix)
    guard requiresEncoding else {
      return rawValue
    }

    return Self.encodedSessionPrefix + rawValue
      .replacingOccurrences(of: "%", with: "%25")
      .replacingOccurrences(of: ":", with: "%3A")
  }

  private func decodeSessionComponent(_ rawValue: String) -> String {
    guard rawValue.hasPrefix(Self.encodedSessionPrefix) else {
      return rawValue
    }

    let encodedComponent = String(rawValue.dropFirst(Self.encodedSessionPrefix.count))
    return encodedComponent.removingPercentEncoding ?? encodedComponent
  }

  private func rawRunSessionComponent(from runID: PraxisRunID) -> String? {
    guard runID.rawValue.hasPrefix("run:") else {
      return nil
    }
    let parts = runID.rawValue.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
    guard parts.count >= 3 else {
      return nil
    }
    return String(parts[1])
  }
}
