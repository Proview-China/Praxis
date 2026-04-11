import Foundation
import Testing
import PraxisCmpTypes
import PraxisRuntimeComposition
import PraxisRuntimeFacades
import PraxisRuntimeGateway
import PraxisRuntimeUseCases
import PraxisTapTypes

struct PraxisRuntimeFacadesTests {
  @Test
  func runtimeFacadeKeepsCmpCompatibilityWrapperBoundToSplitSurfaces() throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-runtime-facades-identity-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let facade = try PraxisRuntimeGatewayFactory.makeRuntimeFacade(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory),
      blueprint: PraxisRuntimeGatewayModule.bootstrap
    )

    #expect(facade.cmpFacade.sessionFacade === facade.cmpSessionFacade)
    #expect(facade.cmpFacade.projectFacade === facade.cmpProjectFacade)
    #expect(facade.cmpFacade.flowFacade === facade.cmpFlowFacade)
    #expect(facade.cmpFacade.rolesFacade === facade.cmpRolesFacade)
    #expect(facade.cmpFacade.controlFacade === facade.cmpControlFacade)
    #expect(facade.cmpFacade.readbackFacade === facade.cmpReadbackFacade)
  }

  @Test
  func splitCmpSubfacadesDriveNeutralHostWorkflow() async throws {
    let rootDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-runtime-facades-workflow-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootDirectory) }

    let facade = try PraxisRuntimeGatewayFactory.makeRuntimeFacade(
      hostAdapters: PraxisHostAdapterRegistry.localDefaults(rootDirectory: rootDirectory),
      blueprint: PraxisRuntimeGatewayModule.bootstrap
    )

    let session = try await facade.cmpSessionFacade.openSession(
      PraxisOpenCmpSessionCommand(projectID: "cmp.local-runtime", sessionID: "cmp.session.split")
    )
    let bootstrap = try await facade.cmpProjectFacade.bootstrapProject(
      PraxisBootstrapCmpProjectCommand(
        projectID: "cmp.local-runtime",
        agentIDs: ["runtime.local", "checker.local"],
        defaultAgentID: "runtime.local"
      )
    )
    let projectReadback = try await facade.cmpProjectFacade.readbackProject(
      PraxisReadbackCmpProjectCommand(projectID: "cmp.local-runtime")
    )
    let ingest = try await facade.cmpFlowFacade.ingestFlow(
      PraxisIngestCmpFlowCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        sessionID: "cmp.flow.split",
        taskSummary: "Capture one split-facade material",
        materials: [
          PraxisCmpRuntimeContextMaterial(kind: .userInput, ref: "payload:user:split")
        ],
        requiresActiveSync: true
      )
    )
    let commit = try await facade.cmpFlowFacade.commitFlow(
      PraxisCommitCmpFlowCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        sessionID: "cmp.flow.split",
        eventIDs: ["evt.split.1"],
        changeSummary: "Commit one split-facade event",
        syncIntent: .toParent
      )
    )
    let controlUpdate = try await facade.cmpControlFacade.updateControl(
      PraxisUpdateCmpControlCommand(
        projectID: "cmp.local-runtime",
        executionStyle: "guided",
        automation: ["autoDispatch": false]
      )
    )
    let controlReadback = try await facade.cmpControlFacade.readbackControl(
      PraxisReadbackCmpControlCommand(projectID: "cmp.local-runtime", agentID: "runtime.local")
    )
    let rolesReadback = try await facade.cmpRolesFacade.readbackRoles(
      PraxisReadbackCmpRolesCommand(projectID: "cmp.local-runtime", agentID: "runtime.local")
    )
    let requestedApproval = try await facade.cmpRolesFacade.requestPeerApproval(
      PraxisRequestCmpPeerApprovalCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityKey: "tool.shell.exec",
        requestedTier: .b2,
        summary: "Need shell execution for split facade test"
      )
    )
    let approvalReadback = try await facade.cmpReadbackFacade.readbackPeerApproval(
      PraxisReadbackCmpPeerApprovalCommand(
        projectID: "cmp.local-runtime",
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityKey: "tool.shell.exec"
      )
    )
    let statusReadback = try await facade.cmpReadbackFacade.readbackStatus(
      PraxisReadbackCmpStatusCommand(projectID: "cmp.local-runtime", agentID: "runtime.local")
    )

    #expect(session.projectID == "cmp.local-runtime")
    #expect(session.sessionID == "cmp.session.split")
    #expect(bootstrap.projectSummary.projectID == "cmp.local-runtime")
    #expect(projectReadback.projectSummary.projectID == "cmp.local-runtime")
    #expect(projectReadback.persistenceSummary.isEmpty == false)
    #expect(ingest.projectID == "cmp.local-runtime")
    #expect(ingest.acceptedEventCount == 1)
    #expect(commit.projectID == "cmp.local-runtime")
    #expect(!commit.deltaID.isEmpty)
    #expect(controlUpdate.executionStyle == "guided")
    #expect(controlReadback.executionStyle == "guided")
    #expect(controlReadback.automation["autoDispatch"] == false)
    #expect(rolesReadback.projectID == "cmp.local-runtime")
    #expect(requestedApproval.capabilityKey == "tool.shell.exec")
    #expect(approvalReadback.found)
    #expect(approvalReadback.capabilityKey == "tool.shell.exec")
    #expect(statusReadback.projectID == "cmp.local-runtime")
    #expect(statusReadback.executionStyle == "guided")
    #expect(statusReadback.roleCounts.isEmpty == false)
  }
}
