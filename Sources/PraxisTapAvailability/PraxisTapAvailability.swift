import PraxisCapabilityCatalog
import PraxisCoreTypes
import PraxisTapGovernance
import PraxisTapTypes

// TODO(reboot-plan):
// - The current implementation already covers availability records, gate decisions, and baseline auditor rules.
// - Next, add family-level audits, live evidence injection, and finer failure-taxonomy/report aggregation.
// - Keep availability as an independent subdomain rather than a scattered side judgment inside governance or runtime.
// - This file can later be split into AvailabilityState.swift, GateRules.swift, FailureTaxonomy.swift, and AvailabilityReport.swift.

public enum PraxisTapAvailabilityModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisTapAvailability",
    responsibility: "TAP family audit、gating、failure taxonomy 与 availability report。",
    tsModules: [
      "src/agent_core/tap-availability",
    ],
  )
}
