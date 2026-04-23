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

  @Test
  func budgetReportsFinalProviderMessageSizeAndRequiredOverBudgetIssue() async throws {
    let service = PraxisContextAssemblyService()
    let prepared = try await service.prepare(
      .init(
        projectID: "project.context",
        task: String(repeating: "Required user task. ", count: 8),
        systemPrompt: String(repeating: "Required system. ", count: 8),
        developerInstructions: String(repeating: "Required developer. ", count: 8),
        policy: .init(maxCharacterBudget: 60)
      )
    )

    let actualProviderCharacters = prepared.providerMessages
      .flatMap(\.textParts)
      .reduce(0) { $0 + $1.count }

    #expect(prepared.includedSections.map(\.id) == ["system", "developer", "user"])
    #expect(prepared.budget.usedCharacterCount > prepared.budget.maxCharacterBudget)
    #expect(prepared.budget.estimatedProviderCharacterCount == actualProviderCharacters)
    #expect(prepared.issues.contains { $0.contains("Required context exceeds the character budget") })
  }

  @Test
  func memoryOrderingPreservesMpFinalScoreBeforeAssemblyTieBreakers() async throws {
    let service = PraxisContextAssemblyService()
    let prepared = try await service.prepare(
      .init(
        projectID: "project.context",
        task: "Use the most relevant memory.",
        memoryCandidates: [
          .init(
            memoryID: "memory.low-score",
            summary: "Short.",
            storageKey: "memory/low-score",
            memoryKind: .semantic,
            freshnessStatus: .fresh,
            alignmentStatus: .aligned,
            scopeLevel: .project,
            semanticScore: 0.10,
            finalScore: 1,
            rankExplanation: "low score"
          ),
          .init(
            memoryID: "memory.high-score",
            summary: "Longer high scoring semantic memory selected by MP ranking.",
            storageKey: "memory/high-score",
            memoryKind: .semantic,
            freshnessStatus: .fresh,
            alignmentStatus: .aligned,
            scopeLevel: .project,
            semanticScore: 0.99,
            finalScore: 99,
            rankExplanation: "high score"
          ),
        ],
        policy: .init(maxCharacterBudget: 1_000)
      )
    )

    let memoryIDs = prepared.includedSections
      .filter { $0.kind == .memory }
      .map(\.id)
    #expect(memoryIDs == ["memory.high-score", "memory.low-score"])
  }

  @Test
  func providerCompactionPreferredUsesWiredDriverAndReportsFailure() async throws {
    let compactingService = PraxisContextAssemblyService(
      compactionDriver: StubCompactionDriver { request in
        PraxisContextCompactionResult(
          messages: [.developerText("Compacted \(request.messages.count) message(s)."), .userText("Current task preserved.")],
          summary: "Stub compaction succeeded."
        )
      }
    )
    let compacted = try await compactingService.prepare(
      .init(
        projectID: "project.context",
        task: String(repeating: "Large current task. ", count: 20),
        policy: .init(maxCharacterBudget: 80, compactionMode: .providerCompactionPreferred)
      )
    )

    #expect(compacted.compaction.status == .compacted)
    #expect(compacted.providerMessages.first?.textParts.joined().contains("Compacted") == true)

    let failingService = PraxisContextAssemblyService(
      compactionDriver: StubCompactionDriver { _ in
        throw StubCompactionError()
      }
    )
    let fallback = try await failingService.prepare(
      .init(
        projectID: "project.context",
        task: String(repeating: "Large current task. ", count: 20),
        policy: .init(maxCharacterBudget: 80, compactionMode: .providerCompactionPreferred)
      )
    )

    #expect(fallback.compaction.status == .failed)
    #expect(fallback.issues.contains { $0.contains("Context compaction failed") })
  }

  @Test
  func compactionRecomputesBudgetAndPreservesCurrentUserTask() async throws {
    let originalTask = "Current user task must survive provider compaction unchanged."
    let service = PraxisContextAssemblyService(
      compactionDriver: StubCompactionDriver { request in
        #expect(request.messages.allSatisfy { $0.role != .user })
        return PraxisContextCompactionResult(
          messages: [.developerText("Compacted historical context.")],
          summary: "Stub compaction shortened the context."
        )
      }
    )

    let prepared = try await service.prepare(
      .init(
        projectID: "project.context",
        task: originalTask,
        policy: .init(maxCharacterBudget: 120, compactionMode: .providerCompactionPreferred)
      )
    )
    let actualProviderCharacters = prepared.providerMessages
      .flatMap(\.textParts)
      .reduce(0) { $0 + $1.count }

    #expect(prepared.compaction.status == .compacted)
    #expect(prepared.providerMessages.last == .userText(originalTask))
    #expect(prepared.budget.estimatedProviderCharacterCount == actualProviderCharacters)
    #expect(prepared.budget.estimatedProviderCharacterCount <= prepared.budget.maxCharacterBudget)
  }
}

private struct StubCompactionError: Error {}

private struct StubCompactionDriver: PraxisContextCompactionDriver {
  let body: @Sendable (PraxisContextCompactionRequest) async throws -> PraxisContextCompactionResult

  func compact(_ request: PraxisContextCompactionRequest) async throws -> PraxisContextCompactionResult {
    try await body(request)
  }
}
