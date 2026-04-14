import Testing
@testable import PraxisCheckpoint
@testable import PraxisCoreTypes
@testable import PraxisGoal
@testable import PraxisJournal
@testable import PraxisRun
@testable import PraxisSession
@testable import PraxisState
@testable import PraxisTransition

// TODO(reboot-plan):
// - Add Foundation dependency-direction guards so lower layers do not reverse-depend on Capability, TAP, CMP, or Host layers.
// - Add blueprint-content tests covering stable fields such as sourceKinds, responsibilities, and recovery boundaries.
// - This file can later be split into FoundationBoundaryTests.swift, FoundationDependencyTests.swift, and FoundationBlueprintTests.swift.

struct FoundationTopologyTests {
  @Test
  func foundationModuleNamesStayStable() {
    #expect(PraxisCoreTypesModule.boundary.name == "PraxisCoreTypes")
    #expect(PraxisGoalModule.boundary.name == "PraxisGoal")
    #expect(PraxisStateModule.boundary.name == "PraxisState")
    #expect(PraxisTransitionModule.boundary.name == "PraxisTransition")
    #expect(PraxisRunModule.boundary.name == "PraxisRun")
    #expect(PraxisSessionModule.boundary.name == "PraxisSession")
    #expect(PraxisJournalModule.boundary.name == "PraxisJournal")
    #expect(PraxisCheckpointModule.boundary.name == "PraxisCheckpoint")
  }
}
