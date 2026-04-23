import Foundation
import PraxisMpTypes
import PraxisProviderContracts

public enum PraxisContextSectionKind: String, Sendable, Equatable, Codable {
  case systemInstruction = "system_instruction"
  case developerInstruction = "developer_instruction"
  case userInput = "user_input"
  case memory
  case reviewEvidence = "review_evidence"
  case capabilitySummary = "capability_summary"
}

public enum PraxisContextSectionSource: String, Sendable, Equatable, Codable {
  case explicitInput = "explicit_input"
  case mpMemory = "mp_memory"
  case cmpReview = "cmp_review"
  case capabilityCatalog = "capability_catalog"
}

public enum PraxisContextCompactionMode: String, Sendable, Equatable, Codable {
  case disabled
  case providerCompactionPreferred = "provider_compaction_preferred"
}

public enum PraxisContextCompactionStatus: String, Sendable, Equatable, Codable {
  case notRequested = "not_requested"
  case notNeeded = "not_needed"
  case unavailable
  case compacted
  case failed
}

public struct PraxisContextAssemblyPolicy: Sendable, Equatable, Codable {
  public let maxCharacterBudget: Int
  public let includeSupersededMemory: Bool
  public let compactionMode: PraxisContextCompactionMode

  public init(
    maxCharacterBudget: Int = 6_000,
    includeSupersededMemory: Bool = false,
    compactionMode: PraxisContextCompactionMode = .disabled
  ) {
    self.maxCharacterBudget = max(1, maxCharacterBudget)
    self.includeSupersededMemory = includeSupersededMemory
    self.compactionMode = compactionMode
  }
}

public struct PraxisContextMemoryCandidate: Sendable, Equatable, Codable {
  public let memoryID: String
  public let summary: String
  public let storageKey: String
  public let memoryKind: PraxisMpMemoryKind
  public let freshnessStatus: PraxisMpMemoryFreshnessStatus
  public let alignmentStatus: PraxisMpMemoryAlignmentStatus
  public let scopeLevel: PraxisMpScopeLevel
  public let semanticScore: Double?
  public let finalScore: Double
  public let rankExplanation: String
  public let sourceRefs: [String]

  public init(
    memoryID: String,
    summary: String,
    storageKey: String,
    memoryKind: PraxisMpMemoryKind,
    freshnessStatus: PraxisMpMemoryFreshnessStatus,
    alignmentStatus: PraxisMpMemoryAlignmentStatus,
    scopeLevel: PraxisMpScopeLevel,
    semanticScore: Double? = nil,
    finalScore: Double,
    rankExplanation: String,
    sourceRefs: [String] = []
  ) {
    self.memoryID = memoryID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
    self.storageKey = storageKey.trimmingCharacters(in: .whitespacesAndNewlines)
    self.memoryKind = memoryKind
    self.freshnessStatus = freshnessStatus
    self.alignmentStatus = alignmentStatus
    self.scopeLevel = scopeLevel
    self.semanticScore = semanticScore
    self.finalScore = finalScore
    self.rankExplanation = rankExplanation.trimmingCharacters(in: .whitespacesAndNewlines)
    self.sourceRefs = Self.normalize(sourceRefs)
  }

  private static func normalize(_ values: [String]) -> [String] {
    Array(
      Set(values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    ).sorted()
  }
}

public struct PraxisContextAssemblyRequest: Sendable, Equatable, Codable {
  public let projectID: String
  public let task: String
  public let systemPrompt: String?
  public let developerInstructions: String?
  public let memoryCandidates: [PraxisContextMemoryCandidate]
  public let reviewEvidence: [String]
  public let capabilitySummaries: [String]
  public let policy: PraxisContextAssemblyPolicy

  public init(
    projectID: String,
    task: String,
    systemPrompt: String? = nil,
    developerInstructions: String? = nil,
    memoryCandidates: [PraxisContextMemoryCandidate] = [],
    reviewEvidence: [String] = [],
    capabilitySummaries: [String] = [],
    policy: PraxisContextAssemblyPolicy = .init()
  ) {
    self.projectID = projectID.trimmingCharacters(in: .whitespacesAndNewlines)
    self.task = task.trimmingCharacters(in: .whitespacesAndNewlines)
    self.systemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    self.developerInstructions = developerInstructions?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    self.memoryCandidates = memoryCandidates
    self.reviewEvidence = reviewEvidence.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    self.capabilitySummaries = capabilitySummaries.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    self.policy = policy
  }
}

public struct PraxisContextSection: Sendable, Equatable, Codable, Identifiable {
  public let id: String
  public let kind: PraxisContextSectionKind
  public let source: PraxisContextSectionSource
  public let title: String
  public let content: String
  public let reason: String
  public let characterCount: Int
  public let sourceRefs: [String]
  public let priority: Int
  public let omittedReason: String?

  public init(
    id: String,
    kind: PraxisContextSectionKind,
    source: PraxisContextSectionSource,
    title: String,
    content: String,
    reason: String,
    sourceRefs: [String] = [],
    priority: Int,
    omittedReason: String? = nil
  ) {
    self.id = id
    self.kind = kind
    self.source = source
    self.title = title
    self.content = content
    self.reason = reason
    self.characterCount = content.count
    self.sourceRefs = sourceRefs
    self.priority = priority
    self.omittedReason = omittedReason
  }

  public func omitting(reason: String) -> Self {
    Self(
      id: id,
      kind: kind,
      source: source,
      title: title,
      content: content,
      reason: self.reason,
      sourceRefs: sourceRefs,
      priority: priority,
      omittedReason: reason
    )
  }
}

public struct PraxisContextBudgetSummary: Sendable, Equatable, Codable {
  public let maxCharacterBudget: Int
  public let usedCharacterCount: Int
  public let estimatedProviderCharacterCount: Int
  public let omittedCharacterCount: Int
  public let includedSectionCount: Int
  public let omittedSectionCount: Int

  public init(
    maxCharacterBudget: Int,
    usedCharacterCount: Int,
    estimatedProviderCharacterCount: Int,
    omittedCharacterCount: Int,
    includedSectionCount: Int,
    omittedSectionCount: Int
  ) {
    self.maxCharacterBudget = maxCharacterBudget
    self.usedCharacterCount = usedCharacterCount
    self.estimatedProviderCharacterCount = estimatedProviderCharacterCount
    self.omittedCharacterCount = omittedCharacterCount
    self.includedSectionCount = includedSectionCount
    self.omittedSectionCount = omittedSectionCount
  }
}

public struct PraxisContextCompactionDecision: Sendable, Equatable, Codable {
  public let mode: PraxisContextCompactionMode
  public let status: PraxisContextCompactionStatus
  public let summary: String

  public init(
    mode: PraxisContextCompactionMode,
    status: PraxisContextCompactionStatus,
    summary: String
  ) {
    self.mode = mode
    self.status = status
    self.summary = summary
  }
}

public struct PraxisPreparedModelContext: Sendable, Equatable, Codable {
  public let projectID: String
  public let includedSections: [PraxisContextSection]
  public let omittedSections: [PraxisContextSection]
  public let budget: PraxisContextBudgetSummary
  public let manifestSummary: String
  public let providerMessages: [PraxisProviderMessage]
  public let compaction: PraxisContextCompactionDecision
  public let issues: [String]

  public init(
    projectID: String,
    includedSections: [PraxisContextSection],
    omittedSections: [PraxisContextSection],
    budget: PraxisContextBudgetSummary,
    manifestSummary: String,
    providerMessages: [PraxisProviderMessage],
    compaction: PraxisContextCompactionDecision,
    issues: [String]
  ) {
    self.projectID = projectID
    self.includedSections = includedSections
    self.omittedSections = omittedSections
    self.budget = budget
    self.manifestSummary = manifestSummary
    self.providerMessages = providerMessages
    self.compaction = compaction
    self.issues = issues
  }
}

public struct PraxisContextCompactionRequest: Sendable, Equatable, Codable {
  public let projectID: String
  public let messages: [PraxisProviderMessage]
  public let maxCharacterBudget: Int

  public init(projectID: String, messages: [PraxisProviderMessage], maxCharacterBudget: Int) {
    self.projectID = projectID
    self.messages = messages
    self.maxCharacterBudget = maxCharacterBudget
  }
}

public struct PraxisContextCompactionResult: Sendable, Equatable, Codable {
  public let messages: [PraxisProviderMessage]
  public let summary: String

  public init(messages: [PraxisProviderMessage], summary: String) {
    self.messages = messages
    self.summary = summary
  }
}

public protocol PraxisContextCompactionDriver: Sendable {
  func compact(_ request: PraxisContextCompactionRequest) async throws -> PraxisContextCompactionResult
}

public struct PraxisContextAssemblyService: Sendable {
  private let compactionDriver: (any PraxisContextCompactionDriver)?

  public init(compactionDriver: (any PraxisContextCompactionDriver)? = nil) {
    self.compactionDriver = compactionDriver
  }

  public func prepare(_ request: PraxisContextAssemblyRequest) async throws -> PraxisPreparedModelContext {
    let requiredSections = makeRequiredSections(request)
    let optionalSections = makeOptionalSections(request)

    var included = requiredSections
    var omitted: [PraxisContextSection] = []
    var usedCharacters = requiredSections.reduce(0) { $0 + $1.characterCount }
    var issues: [String] = []
    if usedCharacters > request.policy.maxCharacterBudget {
      issues.append("Required context exceeds the character budget; required system/developer/user sections were preserved.")
    }

    for section in optionalSections {
      if let omittedReason = section.omittedReason {
        omitted.append(section.omitting(reason: omittedReason))
        continue
      }
      if usedCharacters + section.characterCount <= request.policy.maxCharacterBudget {
        included.append(section)
        usedCharacters += section.characterCount
      } else {
        omitted.append(section.omitting(reason: "Omitted because the context character budget was exhausted."))
      }
    }

    let manifest = makeManifestSummary(projectID: request.projectID, included: included, omitted: omitted)
    var messages = makeProviderMessages(request: request, included: included, manifest: manifest)
    let omittedCharacters = omitted.reduce(0) { $0 + $1.characterCount }
    var estimatedProviderCharacters = estimateProviderCharacterCount(messages)
    let compaction = try await compactIfNeeded(
      request: request,
      messages: &messages,
      estimatedProviderCharacters: estimatedProviderCharacters,
      issues: &issues
    )
    estimatedProviderCharacters = estimateProviderCharacterCount(messages)
    if estimatedProviderCharacters > request.policy.maxCharacterBudget {
      issues.append("Estimated provider message context exceeds the character budget after manifest formatting.")
    }

    return PraxisPreparedModelContext(
      projectID: request.projectID,
      includedSections: included,
      omittedSections: omitted,
      budget: .init(
        maxCharacterBudget: request.policy.maxCharacterBudget,
        usedCharacterCount: usedCharacters,
        estimatedProviderCharacterCount: estimatedProviderCharacters,
        omittedCharacterCount: omittedCharacters,
        includedSectionCount: included.count,
        omittedSectionCount: omitted.count
      ),
      manifestSummary: manifest,
      providerMessages: messages,
      compaction: compaction,
      issues: issues
    )
  }

  private func makeRequiredSections(_ request: PraxisContextAssemblyRequest) -> [PraxisContextSection] {
    var sections: [PraxisContextSection] = []
    if let systemPrompt = request.systemPrompt {
      sections.append(
        .init(
          id: "system",
          kind: .systemInstruction,
          source: .explicitInput,
          title: "System instructions",
          content: systemPrompt,
          reason: "Explicit system prompt supplied by the caller.",
          priority: 10_000
        )
      )
    }
    if let developerInstructions = request.developerInstructions {
      sections.append(
        .init(
          id: "developer",
          kind: .developerInstruction,
          source: .explicitInput,
          title: "Developer instructions",
          content: developerInstructions,
          reason: "Explicit developer instructions supplied by the caller.",
          priority: 9_900
        )
      )
    }
    sections.append(
      .init(
        id: "user",
        kind: .userInput,
        source: .explicitInput,
        title: "User task",
        content: request.task,
        reason: "Current user task is always preserved.",
        priority: 9_800
      )
    )
    return sections
  }

  private func makeOptionalSections(_ request: PraxisContextAssemblyRequest) -> [PraxisContextSection] {
    let memorySections = request.memoryCandidates.map { candidate -> PraxisContextSection in
      if candidate.freshnessStatus == .superseded && !request.policy.includeSupersededMemory {
        return makeMemorySection(candidate).omitting(reason: "Omitted because the memory is superseded.")
      }
      return makeMemorySection(candidate)
    }

    let reviewSections = request.reviewEvidence.enumerated().map { index, summary in
      PraxisContextSection(
        id: "review.\(index)",
        kind: .reviewEvidence,
        source: .cmpReview,
        title: "Review evidence",
        content: summary,
        reason: "CMP/TAP review evidence helps the IDE explain governance state.",
        priority: 300
      )
    }

    let capabilitySections = request.capabilitySummaries.enumerated().map { index, summary in
      PraxisContextSection(
        id: "capability.\(index)",
        kind: .capabilitySummary,
        source: .capabilityCatalog,
        title: "Capability summary",
        content: summary,
        reason: "Capability summary helps the model respect available runtime tools.",
        priority: 100
      )
    }

    let activeMemorySections = memorySections.filter { $0.omittedReason == nil }
    let preOmittedMemorySections = memorySections.filter { $0.omittedReason != nil }
    return activeMemorySections
      .sorted(by: shouldPlaceBefore)
      + reviewSections
      + capabilitySections
      + preOmittedMemorySections
  }

  private func makeMemorySection(_ candidate: PraxisContextMemoryCandidate) -> PraxisContextSection {
    PraxisContextSection(
      id: candidate.memoryID,
      kind: .memory,
      source: .mpMemory,
      title: "\(candidate.memoryKind.rawValue) memory",
      content: candidate.summary,
      reason: memoryReason(candidate),
      sourceRefs: candidate.sourceRefs.isEmpty ? [candidate.storageKey] : candidate.sourceRefs,
      priority: memoryPriority(candidate)
    )
  }

  private func memoryPriority(_ candidate: PraxisContextMemoryCandidate) -> Int {
    Int((candidate.finalScore * 1_000).rounded())
  }

  private func memoryReason(_ candidate: PraxisContextMemoryCandidate) -> String {
    [
      "memory=\(candidate.memoryKind.rawValue)",
      "freshness=\(candidate.freshnessStatus.rawValue)",
      "alignment=\(candidate.alignmentStatus.rawValue)",
      "scope=\(candidate.scopeLevel.rawValue)",
      "rank=\(candidate.rankExplanation)",
    ].joined(separator: ", ")
  }

  private func shouldPlaceBefore(_ left: PraxisContextSection, _ right: PraxisContextSection) -> Bool {
    if left.priority != right.priority {
      return left.priority > right.priority
    }
    return left.id < right.id
  }

  private func makeManifestSummary(
    projectID: String,
    included: [PraxisContextSection],
    omitted: [PraxisContextSection]
  ) -> String {
    let includedIDs = included.map(\.id).joined(separator: ", ")
    let omittedIDs = omitted.map(\.id).joined(separator: ", ")
    if omitted.isEmpty {
      return "Context manifest for \(projectID): included \(included.count) section(s): \(includedIDs)."
    }
    return "Context manifest for \(projectID): included \(included.count) section(s): \(includedIDs). Omitted \(omitted.count) section(s): \(omittedIDs)."
  }

  private func makeProviderMessages(
    request: PraxisContextAssemblyRequest,
    included: [PraxisContextSection],
    manifest: String
  ) -> [PraxisProviderMessage] {
    var messages: [PraxisProviderMessage] = []
    if let systemPrompt = request.systemPrompt {
      messages.append(.systemText(systemPrompt))
    }

    let contextBody = included
      .filter { $0.kind != .systemInstruction && $0.kind != .userInput }
      .map { section in
        "- [\(section.id)] \(section.title): \(section.content)"
      }
      .joined(separator: "\n")

    var developerParts: [String] = []
    if let developerInstructions = request.developerInstructions {
      developerParts.append(developerInstructions)
    }
    developerParts.append("Context manifest: \(manifest)")
    if !contextBody.isEmpty {
      developerParts.append("Selected context:\n\(contextBody)")
    }
    messages.append(.developerText(developerParts.joined(separator: "\n\n")))
    messages.append(.userText(request.task))
    return messages
  }

  private func compactIfNeeded(
    request: PraxisContextAssemblyRequest,
    messages: inout [PraxisProviderMessage],
    estimatedProviderCharacters: Int,
    issues: inout [String]
  ) async throws -> PraxisContextCompactionDecision {
    guard request.policy.compactionMode == .providerCompactionPreferred else {
      return .init(
        mode: request.policy.compactionMode,
        status: .notRequested,
        summary: "Provider compaction was not requested."
      )
    }
    guard estimatedProviderCharacters > request.policy.maxCharacterBudget else {
      return .init(
        mode: request.policy.compactionMode,
        status: .notNeeded,
        summary: "Deterministic context assembly stayed within budget."
      )
    }
    guard let compactionDriver else {
      issues.append("Context compaction driver is unavailable; deterministic context assembly was used.")
      return .init(
        mode: request.policy.compactionMode,
        status: .unavailable,
        summary: "Provider compaction was requested but no compaction driver is wired."
      )
    }

    do {
      let compactableMessages = messages.dropLastUserMessage()
      let result = try await compactionDriver.compact(
        .init(
          projectID: request.projectID,
          messages: compactableMessages,
          maxCharacterBudget: request.policy.maxCharacterBudget
        )
      )
      messages = makeProviderMessagesPreservingCurrentInputs(
        request: request,
        compactedMessages: result.messages
      )
      return .init(
        mode: request.policy.compactionMode,
        status: .compacted,
        summary: result.summary
      )
    } catch {
      issues.append("Context compaction failed: \(error.localizedDescription)")
      return .init(
        mode: request.policy.compactionMode,
        status: .failed,
        summary: "Provider compaction failed; deterministic context assembly was used."
      )
    }
  }

  private func estimateProviderCharacterCount(_ messages: [PraxisProviderMessage]) -> Int {
    messages
      .flatMap(\.textParts)
      .reduce(0) { $0 + $1.count }
  }

  private func makeProviderMessagesPreservingCurrentInputs(
    request: PraxisContextAssemblyRequest,
    compactedMessages: [PraxisProviderMessage]
  ) -> [PraxisProviderMessage] {
    var preserved: [PraxisProviderMessage] = []
    if let systemPrompt = request.systemPrompt {
      preserved.append(.systemText(systemPrompt))
    }

    var developerParts: [String] = []
    if let developerInstructions = request.developerInstructions {
      developerParts.append(developerInstructions)
    }
    let compactedText = compactedMessages
      .flatMap(\.textParts)
      .joined(separator: "\n")
    if !compactedText.isEmpty {
      developerParts.append("Compacted context:\n\(compactedText)")
    }
    if !developerParts.isEmpty {
      preserved.append(.developerText(developerParts.joined(separator: "\n\n")))
    }

    preserved.append(.userText(request.task))
    return preserved
  }
}

private extension [PraxisProviderMessage] {
  func dropLastUserMessage() -> [PraxisProviderMessage] {
    guard last?.role == .user else {
      return self
    }
    return Array(dropLast())
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
