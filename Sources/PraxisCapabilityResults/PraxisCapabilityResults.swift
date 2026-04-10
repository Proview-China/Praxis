import PraxisCapabilityContracts
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement result models such as CapabilityResultEnvelope, NormalizedOutput, and CapabilityFailure.
// - Implement the mapping rules from raw provider payloads to normalized Core results.
// - Define the result-event bridge and error taxonomy so upper layers only see normalized semantics.
// - This file can later be split into ResultEnvelope.swift, ResultNormalization.swift, ResultEvents.swift, and ResultFailures.swift.

public enum PraxisCapabilityResultsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCapabilityResults",
    responsibility: "capability result envelope、normalized output 与 result-event bridge。",
    tsModules: [
      "src/agent_core/capability-result",
    ],
  )
}
