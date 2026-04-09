import XCTest
@testable import PraxisCmpDbModel
@testable import PraxisCmpDelivery
@testable import PraxisCmpFiveAgent
@testable import PraxisCmpGitModel
@testable import PraxisCmpMqModel
@testable import PraxisCmpProjection
@testable import PraxisCmpSections
@testable import PraxisCmpTypes

// TODO(reboot-plan):
// - 增加 CMP 八分结构的单向依赖守卫，确认 model/planner 不回流宿主实现。
// - 增加 sections/projection/delivery/git/db/mq/five-agent 的 blueprint 测试。
// - 后续可继续拆分：CmpBoundaryTests.swift、CmpDependencyTests.swift、CmpBlueprintTests.swift。

final class CmpTopologyTests: XCTestCase {
  func testCmpDomainSplitIntoEightSubmodules() {
    XCTAssertEqual(PraxisCmpTypesModule.boundary.name, "PraxisCmpTypes")
    XCTAssertEqual(PraxisCmpSectionsModule.boundary.name, "PraxisCmpSections")
    XCTAssertEqual(PraxisCmpProjectionModule.boundary.name, "PraxisCmpProjection")
    XCTAssertEqual(PraxisCmpDeliveryModule.boundary.name, "PraxisCmpDelivery")
    XCTAssertEqual(PraxisCmpGitModelModule.boundary.name, "PraxisCmpGitModel")
    XCTAssertEqual(PraxisCmpDbModelModule.boundary.name, "PraxisCmpDbModel")
    XCTAssertEqual(PraxisCmpMqModelModule.boundary.name, "PraxisCmpMqModel")
    XCTAssertEqual(PraxisCmpFiveAgentModule.boundary.name, "PraxisCmpFiveAgent")
  }
}
