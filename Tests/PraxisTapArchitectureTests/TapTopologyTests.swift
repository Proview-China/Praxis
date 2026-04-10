import Testing
@testable import PraxisTapAvailability
@testable import PraxisTapGovernance
@testable import PraxisTapProvision
@testable import PraxisTapReview
@testable import PraxisTapRuntime
@testable import PraxisTapTypes

// TODO(reboot-plan):
// - Add dependency-direction tests for the six-part TAP split so governance, review, provision, runtime, and availability stay within their boundaries.
// - Add blueprint guards for governance, review, provision, and availability responsibilities.
// - This file can later be split into TapBoundaryTests.swift, TapDependencyTests.swift, and TapBlueprintTests.swift.

struct TapTopologyTests {
  @Test
  func tapDomainSplitIntoSixSubmodules() {
    #expect(PraxisTapTypesModule.boundary.name == "PraxisTapTypes")
    #expect(PraxisTapGovernanceModule.boundary.name == "PraxisTapGovernance")
    #expect(PraxisTapReviewModule.boundary.name == "PraxisTapReview")
    #expect(PraxisTapProvisionModule.boundary.name == "PraxisTapProvision")
    #expect(PraxisTapRuntimeModule.boundary.name == "PraxisTapRuntime")
    #expect(PraxisTapAvailabilityModule.boundary.name == "PraxisTapAvailability")
  }
}
