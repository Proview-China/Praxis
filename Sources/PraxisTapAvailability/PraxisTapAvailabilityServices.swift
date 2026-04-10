import PraxisCapabilityContracts
import PraxisTapTypes

/// Default TAP availability auditor.
/// This type derives the Core-side availability view from collected observations, but it does not execute live audits on its own.
public struct PraxisAvailabilityAuditor: Sendable {
  public init() {}

  /// Builds a TAP availability report from the current observations and gate rules.
  ///
  /// - Parameters:
  ///   - rules: The gate rules that need to be evaluated.
  ///   - currentMode: The TAP mode currently used by runtime.
  ///   - blockedCapabilities: The set of capabilities that are hard-blocked.
  ///   - degradedCapabilities: The set of capabilities that can run only in a degraded mode.
  ///   - backlogCapabilities: The set of capabilities that remain in backlog or missing state.
  /// - Returns: An availability report aggregating the gating result for each capability.
  public func audit(
    rules: [PraxisTapGateRule],
    currentMode: PraxisTapMode,
    blockedCapabilities: Set<PraxisCapabilityID> = [],
    degradedCapabilities: Set<PraxisCapabilityID> = [],
    backlogCapabilities: Set<PraxisCapabilityID> = []
  ) -> PraxisAvailabilityReport {
    let records = rules.compactMap { rule -> PraxisTapCapabilityAvailabilityRecord? in
      guard let capabilityID = rule.capabilityID else { return nil }

      if backlogCapabilities.contains(capabilityID) {
        return PraxisTapCapabilityAvailabilityRecord(
          capabilityID: capabilityID,
          state: .unavailable,
          decision: .pendingBacklog,
          summary: rule.summary,
          reviewRequired: false,
          runtimeAllowed: false,
          failures: [.dependencyMissing]
        )
      }

      // Mode mismatch is treated as a hard gate before we consider softer review/degraded states.
      if blockedCapabilities.contains(capabilityID) || currentMode.canonicalMode.rawValue != rule.requiredMode.canonicalMode.rawValue {
        return PraxisTapCapabilityAvailabilityRecord(
          capabilityID: capabilityID,
          state: .gated,
          decision: .blocked,
          summary: rule.summary,
          reviewRequired: false,
          runtimeAllowed: false,
          failures: [.policyBlocked]
        )
      }

      if degradedCapabilities.contains(capabilityID) {
        return PraxisTapCapabilityAvailabilityRecord(
          capabilityID: capabilityID,
          state: .degraded,
          decision: .reviewOnly,
          summary: rule.summary,
          reviewRequired: true,
          runtimeAllowed: true,
          failures: [.runtimeUnavailable]
        )
      }

      if rule.reviewRequired {
        return PraxisTapCapabilityAvailabilityRecord(
          capabilityID: capabilityID,
          state: .available,
          decision: .reviewOnly,
          summary: rule.summary,
          reviewRequired: true,
          runtimeAllowed: true
        )
      }

      return PraxisTapCapabilityAvailabilityRecord(
        capabilityID: capabilityID,
        state: .available,
        decision: .baseline,
        summary: rule.summary,
        reviewRequired: false,
        runtimeAllowed: true
      )
    }

    let state: PraxisAvailabilityState
    if records.contains(where: { $0.decision == PraxisAvailabilityGateDecision.blocked }) {
      state = .gated
    } else if records.contains(where: { $0.state == PraxisAvailabilityState.degraded }) {
      state = .degraded
    } else if records.isEmpty || records.allSatisfy({ $0.runtimeAllowed }) {
      state = .available
    } else {
      state = .unavailable
    }

    let summary = "Availability audit produced \(records.count) TAP capability records."
    return PraxisAvailabilityReport(state: state, summary: summary, records: records)
  }
}
