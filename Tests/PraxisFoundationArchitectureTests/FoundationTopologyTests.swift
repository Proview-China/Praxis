import XCTest
@testable import PraxisCheckpoint
@testable import PraxisCoreTypes
@testable import PraxisGoal
@testable import PraxisJournal
@testable import PraxisRun
@testable import PraxisSession
@testable import PraxisState
@testable import PraxisTransition

// TODO(reboot-plan):
// - 增加 Foundation 依赖方向守卫，确认低层不反向依赖 Capability/TAP/CMP/Host。
// - 增加 blueprint 内容测试，覆盖 sourceKinds、responsibilities、恢复边界等稳定字段。
// - 后续可继续拆分：FoundationBoundaryTests.swift、FoundationDependencyTests.swift、FoundationBlueprintTests.swift。

final class FoundationTopologyTests: XCTestCase {
  func testFoundationModuleNamesStayStable() {
    XCTAssertEqual(PraxisCoreTypesModule.boundary.name, "PraxisCoreTypes")
    XCTAssertEqual(PraxisGoalModule.boundary.name, "PraxisGoal")
    XCTAssertEqual(PraxisStateModule.boundary.name, "PraxisState")
    XCTAssertEqual(PraxisTransitionModule.boundary.name, "PraxisTransition")
    XCTAssertEqual(PraxisRunModule.boundary.name, "PraxisRun")
    XCTAssertEqual(PraxisSessionModule.boundary.name, "PraxisSession")
    XCTAssertEqual(PraxisJournalModule.boundary.name, "PraxisJournal")
    XCTAssertEqual(PraxisCheckpointModule.boundary.name, "PraxisCheckpoint")
  }
}
