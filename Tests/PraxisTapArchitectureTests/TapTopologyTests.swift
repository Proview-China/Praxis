import XCTest
@testable import PraxisTapAvailability
@testable import PraxisTapGovernance
@testable import PraxisTapProvision
@testable import PraxisTapReview
@testable import PraxisTapRuntime
@testable import PraxisTapTypes

// TODO(reboot-plan):
// - 增加 TAP 六分结构的依赖方向测试，确认 governance/review/provision/runtime/availability 不越界。
// - 增加治理、审查、供应、availability blueprint 守卫。
// - 后续可继续拆分：TapBoundaryTests.swift、TapDependencyTests.swift、TapBlueprintTests.swift。

final class TapTopologyTests: XCTestCase {
  func testTapDomainSplitIntoSixSubmodules() {
    XCTAssertEqual(PraxisTapTypesModule.boundary.name, "PraxisTapTypes")
    XCTAssertEqual(PraxisTapGovernanceModule.boundary.name, "PraxisTapGovernance")
    XCTAssertEqual(PraxisTapReviewModule.boundary.name, "PraxisTapReview")
    XCTAssertEqual(PraxisTapProvisionModule.boundary.name, "PraxisTapProvision")
    XCTAssertEqual(PraxisTapRuntimeModule.boundary.name, "PraxisTapRuntime")
    XCTAssertEqual(PraxisTapAvailabilityModule.boundary.name, "PraxisTapAvailability")
  }
}
