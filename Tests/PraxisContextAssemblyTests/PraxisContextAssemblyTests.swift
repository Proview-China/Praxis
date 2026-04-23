import Testing
import PraxisContextAssembly
import PraxisMpTypes

struct PraxisContextAssemblyTests {
  @Test
  func preparedContextPreservesRequiredInstructionsAndOmitsLowPrioritySectionsOverBudget() async throws {
    let service = PraxisContextAssemblyService()
    let prepared = try await service.prepare(
      .init(
        projectID: "project.context",
        task: "Fix the failing checkout flow",
        systemPrompt: "Follow repository conventions.",
        developerInstructions: "Prefer small, reviewed edits.",
        memoryCandidates: [
          .init(
            memoryID: "memory.superseded",
            summary: "Outdated checkout behavior that should not be used.",
            storageKey: "memory/superseded",
            memoryKind: .semantic,
            freshnessStatus: .superseded,
            alignmentStatus: .aligned,
            scopeLevel: .project,
            semanticScore: 0.99,
            finalScore: 99,
            rankExplanation: "superseded"
          ),
          .init(
            memoryID: "memory.directive",
            summary: "Checkout changes require explicit user approval before shell execution.",
            storageKey: "memory/directive",
            memoryKind: .directive,
            freshnessStatus: .fresh,
            alignmentStatus: .aligned,
            scopeLevel: .global,
            semanticScore: 0.6,
            finalScore: 60,
            rankExplanation: "aligned directive"
          ),
          .init(
            memoryID: "memory.low",
            summary: String(repeating: "Low priority background detail. ", count: 20),
            storageKey: "memory/low",
            memoryKind: .episodic,
            freshnessStatus: .aging,
            alignmentStatus: .unreviewed,
            scopeLevel: .agentIsolated,
            semanticScore: 0.1,
            finalScore: 10,
            rankExplanation: "low relevance"
          ),
        ],
        reviewEvidence: [
          "No pending approval is currently waiting."
        ],
        capabilitySummaries: [
          "shell.run is bounded and approval-backed."
        ],
        policy: .init(maxCharacterBudget: 260)
      )
    )

    #expect(prepared.includedSections.contains { $0.kind == .systemInstruction })
    #expect(prepared.includedSections.contains { $0.kind == .developerInstruction })
    #expect(prepared.includedSections.contains { $0.kind == .userInput })
    #expect(prepared.includedSections.contains { $0.id == "memory.directive" })
    #expect(prepared.omittedSections.contains { $0.id == "memory.superseded" && $0.omittedReason?.contains("superseded") == true })
    #expect(prepared.omittedSections.contains { $0.id == "memory.low" && $0.omittedReason?.contains("budget") == true })
    #expect(prepared.manifestSummary.contains("memory.directive"))
    #expect(prepared.providerMessages.contains { $0.role == .developer && $0.textParts.joined().contains("Context manifest") })
    #expect(prepared.providerMessages.last?.role == .user)
  }

  @Test
  func providerCompactionPreferredReportsUnavailableWhenNoDriverIsWired() async throws {
    let service = PraxisContextAssemblyService()
    let prepared = try await service.prepare(
      .init(
        projectID: "project.context",
        task: String(repeating: "Large task. ", count: 40),
        memoryCandidates: [
          .init(
            memoryID: "memory.current",
            summary: String(repeating: "Current memory. ", count: 40),
            storageKey: "memory/current",
            memoryKind: .semantic,
            freshnessStatus: .fresh,
            alignmentStatus: .aligned,
            scopeLevel: .project,
            semanticScore: 0.8,
            finalScore: 80,
            rankExplanation: "fresh aligned"
          )
        ],
        policy: .init(
          maxCharacterBudget: 80,
          compactionMode: .providerCompactionPreferred
        )
      )
    )

    #expect(prepared.compaction.status == .unavailable)
    #expect(prepared.issues.contains { $0.contains("Context compaction driver is unavailable") })
  }
}
