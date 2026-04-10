import Testing
@testable import PraxisCmpDbModel
@testable import PraxisCmpDelivery
@testable import PraxisCmpFiveAgent
@testable import PraxisCmpGitModel
@testable import PraxisCmpMqModel
@testable import PraxisCmpProjection
@testable import PraxisCmpSections
@testable import PraxisCmpTypes

// TODO(reboot-plan):
// - Add one-way dependency guards for the eight-part CMP split so model and planner layers do not flow back into host implementations.
// - Add blueprint tests for sections, projection, delivery, git, db, mq, and five-agent targets.
// - This file can later be split into CmpBoundaryTests.swift, CmpDependencyTests.swift, and CmpBlueprintTests.swift.

struct CmpTopologyTests {
  @Test
  func cmpDomainSplitIntoEightSubmodules() {
    #expect(PraxisCmpTypesModule.boundary.name == "PraxisCmpTypes")
    #expect(PraxisCmpSectionsModule.boundary.name == "PraxisCmpSections")
    #expect(PraxisCmpProjectionModule.boundary.name == "PraxisCmpProjection")
    #expect(PraxisCmpDeliveryModule.boundary.name == "PraxisCmpDelivery")
    #expect(PraxisCmpGitModelModule.boundary.name == "PraxisCmpGitModel")
    #expect(PraxisCmpDbModelModule.boundary.name == "PraxisCmpDbModel")
    #expect(PraxisCmpMqModelModule.boundary.name == "PraxisCmpMqModel")
    #expect(PraxisCmpFiveAgentModule.boundary.name == "PraxisCmpFiveAgent")
  }
}
