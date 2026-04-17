import Foundation
import PraxisRuntimeKit

private func makeRuntimeRoot(named name: String) throws -> URL {
  let rootDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("praxis-examples", isDirectory: true)
    .appendingPathComponent(name, isDirectory: true)
  try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
  return rootDirectory
}

private func printSectionSummaries<Section>(
  from sections: [Section],
  prefix: String,
  sectionID: (Section) -> String,
  summary: (Section) -> String
) {
  let reviewerContextSectionIDs = [
    "provider-skills",
    "provider-mcp-tools",
    "provider-activity",
  ]

  for reviewerContextSectionID in reviewerContextSectionIDs {
    guard let section = sections.first(where: { sectionID($0) == reviewerContextSectionID }) else {
      continue
    }
    print("\(prefix).\(reviewerContextSectionID).summary: \(summary(section))")
  }
}

@main
struct PraxisRuntimeKitCmpTapExample {
  static func main() async throws {
    let rootDirectory = try makeRuntimeRoot(named: "runtime-kit-cmp-tap")
    let client = try PraxisRuntimeClient.makeDefault(rootDirectory: rootDirectory)

    let projectID: PraxisRuntimeProjectRef = "cmp.local-runtime"
    let cmpProject = client.cmp.project(projectID)
    let tapProject = client.tap.project(projectID)

    let session = try await cmpProject.openSession(session: "cmp.runtime-kit")
    _ = try await cmpProject.approvals.request(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        requestedTier: .b1,
        summary: "Escalate git access to checker"
      )
    )
    let decided = try await cmpProject.approvals.decide(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git",
        decision: .approve,
        reviewerAgentID: "reviewer.local",
        decisionSummary: "Approved git access for checker"
      )
    )
    let approval = try await cmpProject.approvals.readback(
      .init(
        agentID: "runtime.local",
        targetAgentID: "checker.local",
        capabilityID: "tool.git"
      )
    )
    _ = try await client.capabilities.activateSkill(
      .init(
        skillKey: "runtime.inspect",
        reason: "Reviewer context example coverage"
      )
    )
    _ = try await client.capabilities.callTool(
      .init(
        toolName: "web.search",
        summary: "Reviewer context example provider MCP tool coverage",
        serverName: "local-example"
      )
    )
    let tapInspection = try await client.tap.inspect()
    let cmpOverview = try await cmpProject.overview(.init(agentID: "checker.local"))
    let tapOverview = try await tapProject.overview(.init(agentID: "checker.local", limit: 10))
    let reviewWorkbench = try await tapProject.reviewWorkbench(.init(agentID: "checker.local", limit: 10))

    print("Praxis RuntimeKit CMP + TAP Example")
    print("rootDirectory: \(rootDirectory.path)")
    print("session.id: \(session.sessionID)")
    print("approval.outcome: \(decided.outcome.rawValue)")
    print("approval.readbackFound: \(approval.found)")
    print("cmp.status.projectID: \(cmpOverview.status.projectID)")
    print("cmp.summary: \(cmpOverview.readback.summary)")
    print("tap.availableCapabilities: \(tapOverview.status.availableCapabilityIDs.map(\.rawValue).joined(separator: ", "))")
    print("tap.historyCount: \(tapOverview.history.totalCount)")
    print("tap.inspect.requestedAction: \(tapInspection.requestedAction)")
    print("tap.inspect.sections: \(tapInspection.sections.map(\.sectionID).joined(separator: ", "))")
    printSectionSummaries(
      from: tapInspection.sections,
      prefix: "tap.inspect",
      sectionID: { $0.sectionID },
      summary: { $0.summary }
    )
    print("tap.workbench.summary: \(reviewWorkbench.summary)")
    print("tap.workbench.pendingCount: \(reviewWorkbench.pendingItems.count)")
    printSectionSummaries(
      from: reviewWorkbench.inspection.sections,
      prefix: "tap.workbench",
      sectionID: { $0.sectionID },
      summary: { $0.summary }
    )
    if let latestDecision = tapOverview.status.latestDecisionSummary {
      print("tap.latestDecision: \(latestDecision)")
    }
    if let latestInspectionDecision = tapInspection.latestDecisionSummary {
      print("tap.inspect.latestDecision: \(latestInspectionDecision)")
    }
  }
}
