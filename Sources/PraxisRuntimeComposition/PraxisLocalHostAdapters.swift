import Foundation
import PraxisCapabilityResults
import PraxisCheckpoint
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisInfraContracts
import PraxisJournal
import PraxisProviderContracts
import PraxisToolingContracts
import PraxisUserIOContracts
import PraxisWorkspaceContracts

private struct PraxisLocalRuntimePaths: Sendable {
  let rootDirectory: URL
  let checkpointsFileURL: URL
  let journalFileURL: URL
  let projectionsFileURL: URL
  let deliveryTruthFileURL: URL
  let embeddingsFileURL: URL
  let semanticMemoryFileURL: URL

  init(rootDirectory: URL) {
    self.rootDirectory = rootDirectory
    checkpointsFileURL = rootDirectory.appendingPathComponent("checkpoints.json", isDirectory: false)
    journalFileURL = rootDirectory.appendingPathComponent("journal.json", isDirectory: false)
    projectionsFileURL = rootDirectory.appendingPathComponent("projections.json", isDirectory: false)
    deliveryTruthFileURL = rootDirectory.appendingPathComponent("delivery-truth.json", isDirectory: false)
    embeddingsFileURL = rootDirectory.appendingPathComponent("embeddings.json", isDirectory: false)
    semanticMemoryFileURL = rootDirectory.appendingPathComponent("semantic-memory.json", isDirectory: false)
  }

  static func resolveRootDirectory(_ explicitRootDirectory: URL?) -> URL {
    if let explicitRootDirectory {
      return explicitRootDirectory
    }

    if let configuredRoot = ProcessInfo.processInfo.environment["PRAXIS_LOCAL_RUNTIME_ROOT"],
       !configuredRoot.isEmpty {
      return URL(fileURLWithPath: configuredRoot, isDirectory: true)
    }

    return FileManager.default.temporaryDirectory
      .appendingPathComponent("praxis-local-runtime", isDirectory: true)
  }
}

private enum PraxisLocalJSONFileIO {
  static func load<Value: Decodable>(_ type: Value.Type, from fileURL: URL) throws -> Value? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return nil
    }
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(type, from: data)
  }

  static func save<Value: Encodable>(_ value: Value, to fileURL: URL) throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: fileURL, options: .atomic)
  }
}

private func localRuntimeNow() -> String {
  ISO8601DateFormatter().string(from: Date())
}

public actor PraxisLocalCheckpointStore: PraxisCheckpointStoreContract {
  private let fileURL: URL
  private var records: [PraxisCheckpointRecord] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ record: PraxisCheckpointRecord) async throws -> PraxisCheckpointSaveReceipt {
    try loadIfNeeded()
    records.removeAll { $0.pointer == record.pointer }
    records.append(record)
    try persist()
    return PraxisCheckpointSaveReceipt(
      pointer: record.pointer,
      tier: record.snapshot.tier,
      storedAt: localRuntimeNow()
    )
  }

  public func load(pointer: PraxisCheckpointPointer) async throws -> PraxisCheckpointRecord? {
    try loadIfNeeded()
    return records.last { $0.pointer == pointer }
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    records = try PraxisLocalJSONFileIO.load([PraxisCheckpointRecord].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(
      records.sorted {
        $0.pointer.checkpointID.rawValue < $1.pointer.checkpointID.rawValue
      },
      to: fileURL
    )
  }
}

public actor PraxisLocalJournalStore: PraxisJournalStoreContract {
  private let fileURL: URL
  private var events: [PraxisJournalEvent] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func append(_ batch: PraxisJournalRecordBatch) async throws -> PraxisJournalAppendReceipt {
    try loadIfNeeded()
    let startingSequence = (events.last?.sequence ?? 0) + 1
    let appendedEvents = batch.events.enumerated().map { offset, event in
      PraxisJournalEvent(
        sequence: startingSequence + offset,
        sessionID: event.sessionID,
        runReference: event.runReference,
        correlationID: event.correlationID,
        type: event.type,
        summary: event.summary,
        metadata: event.metadata
      )
    }
    events.append(contentsOf: appendedEvents)
    try persist()
    return PraxisJournalAppendReceipt(
      appendedCount: appendedEvents.count,
      lastCursor: appendedEvents.last.map { .init(sequence: $0.sequence) }
    )
  }

  public func read(_ request: PraxisJournalSliceRequest) async throws -> PraxisJournalSlice {
    try loadIfNeeded()
    let filteredEvents = events.filter { event in
      guard event.sessionID.rawValue == request.sessionID else {
        return false
      }
      if let runReference = request.runReference, event.runReference != runReference {
        return false
      }
      if let afterCursor = request.afterCursor, event.sequence <= afterCursor.sequence {
        return false
      }
      return true
    }
    let sliceEvents = Array(filteredEvents.prefix(request.limit))
    return PraxisJournalSlice(
      events: sliceEvents,
      nextCursor: sliceEvents.last.map { .init(sequence: $0.sequence) }
    )
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    events = try PraxisLocalJSONFileIO.load([PraxisJournalEvent].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(events, to: fileURL)
  }
}

public actor PraxisLocalProjectionStore: PraxisProjectionStoreContract {
  private let fileURL: URL
  private var descriptors: [PraxisProjectionRecordDescriptor] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ descriptor: PraxisProjectionRecordDescriptor) async throws -> PraxisProjectionStoreWriteReceipt {
    try loadIfNeeded()
    descriptors.removeAll { $0.projectID == descriptor.projectID && $0.projectionID == descriptor.projectionID }
    descriptors.append(descriptor)
    try persist()
    return PraxisProjectionStoreWriteReceipt(
      projectionID: descriptor.projectionID,
      storageKey: descriptor.storageKey,
      storedAt: descriptor.updatedAt ?? localRuntimeNow()
    )
  }

  public func describe(projectId: String) async throws -> PraxisProjectionRecordDescriptor {
    try loadIfNeeded()
    guard let descriptor = descriptors
      .filter({ $0.projectID == projectId })
      .sorted(by: { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") })
      .first else {
      throw PraxisCmpValidationError.invalid("Projection descriptor for project \(projectId) is missing.")
    }
    return descriptor
  }

  public func describe(_ query: PraxisProjectionDescriptorQuery) async throws -> [PraxisProjectionRecordDescriptor] {
    try loadIfNeeded()
    return descriptors
      .filter { descriptor in
        guard descriptor.projectID == query.projectID else {
          return false
        }
        if let projectionID = query.projectionID, descriptor.projectionID != projectionID {
          return false
        }
        if let lineageID = query.lineageID, descriptor.lineageID != lineageID {
          return false
        }
        if let agentID = query.agentID, descriptor.agentID != agentID {
          return false
        }
        return true
      }
      .sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    descriptors = try PraxisLocalJSONFileIO.load([PraxisProjectionRecordDescriptor].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(descriptors, to: fileURL)
  }
}

public actor PraxisLocalMessageBus: PraxisMessageBusContract {
  private var publishedMessages: [PraxisPublishedMessage] = []
  private var subscriptions: [PraxisMessageSubscription] = []

  public init() {}

  public func publish(_ message: PraxisPublishedMessage) async throws -> PraxisMessagePublicationReceipt {
    publishedMessages.append(message)
    return PraxisMessagePublicationReceipt(
      messageID: message.messageID,
      topic: message.topic,
      acceptedAt: message.publishedAt ?? localRuntimeNow()
    )
  }

  public func subscribe(topic: String, consumerID: String) async throws -> PraxisMessageSubscription {
    let subscription = PraxisMessageSubscription(
      topic: topic,
      consumerID: consumerID,
      startedAt: localRuntimeNow()
    )
    subscriptions.append(subscription)
    return subscription
  }
}

public actor PraxisLocalDeliveryTruthStore: PraxisDeliveryTruthStoreContract {
  private let fileURL: URL
  private var records: [PraxisDeliveryTruthRecord] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ record: PraxisDeliveryTruthRecord) async throws -> PraxisDeliveryTruthUpsertReceipt {
    try loadIfNeeded()
    records.removeAll { $0.id == record.id }
    records.append(record)
    try persist()
    return PraxisDeliveryTruthUpsertReceipt(
      deliveryID: record.id,
      status: record.status,
      updatedAt: record.updatedAt
    )
  }

  public func lookup(deliveryID: String) async throws -> PraxisDeliveryTruthRecord? {
    try loadIfNeeded()
    return records.last { $0.id == deliveryID }
  }

  public func lookup(_ query: PraxisDeliveryTruthQuery) async throws -> [PraxisDeliveryTruthRecord] {
    try loadIfNeeded()
    return records.filter { record in
      if let deliveryID = query.deliveryID, record.id != deliveryID {
        return false
      }
      if let packageID = query.packageID, record.packageID != packageID {
        return false
      }
      if let topic = query.topic, record.topic != topic {
        return false
      }
      if let targetAgentID = query.targetAgentID, record.targetAgentID != targetAgentID {
        return false
      }
      return true
    }
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    records = try PraxisLocalJSONFileIO.load([PraxisDeliveryTruthRecord].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(records, to: fileURL)
  }
}

public actor PraxisLocalEmbeddingStore: PraxisEmbeddingStoreContract {
  private let fileURL: URL
  private var records: [PraxisEmbeddingRecord] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ record: PraxisEmbeddingRecord) async throws -> PraxisEmbeddingStoreWriteReceipt {
    try loadIfNeeded()
    records.removeAll { $0.id == record.id }
    records.append(record)
    try persist()
    return PraxisEmbeddingStoreWriteReceipt(embeddingID: record.id, storageKey: record.storageKey)
  }

  public func load(embeddingID: String) async throws -> PraxisEmbeddingRecord? {
    try loadIfNeeded()
    return records.last { $0.id == embeddingID }
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    records = try PraxisLocalJSONFileIO.load([PraxisEmbeddingRecord].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(records, to: fileURL)
  }
}

public actor PraxisLocalSemanticMemoryStore: PraxisSemanticMemoryStoreContract {
  private let fileURL: URL
  private var records: [PraxisSemanticMemoryRecord] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ record: PraxisSemanticMemoryRecord) async throws -> PraxisSemanticMemoryWriteReceipt {
    try loadIfNeeded()
    records.removeAll { $0.id == record.id }
    records.append(record)
    try persist()
    return PraxisSemanticMemoryWriteReceipt(memoryID: record.id, storageKey: record.storageKey)
  }

  public func load(memoryID: String) async throws -> PraxisSemanticMemoryRecord? {
    try loadIfNeeded()
    return records.last { $0.id == memoryID }
  }

  public func search(_ request: PraxisSemanticMemorySearchRequest) async throws -> [PraxisSemanticMemoryRecord] {
    try loadIfNeeded()
    return records
      .filter { record in
        guard record.projectID == request.projectID else {
          return false
        }
        guard request.scopeLevels.contains(record.scopeLevel) else {
          return false
        }
        if let agentID = request.agentID, record.agentID != agentID {
          return false
        }
        if request.query.isEmpty {
          return true
        }
        return record.summary.localizedCaseInsensitiveContains(request.query)
      }
      .sorted { $0.id < $1.id }
      .prefix(request.limit)
      .map { $0 }
  }

  public func bundle(_ request: PraxisSemanticMemoryBundleRequest) async throws -> PraxisSemanticMemoryBundle {
    try loadIfNeeded()
    let filteredRecords = records.filter { record in
      guard record.projectID == request.projectID else {
        return false
      }
      guard request.scopeLevels.contains(record.scopeLevel) else {
        return false
      }
      if let agentID = request.agentID, record.agentID != agentID {
        return false
      }
      if request.query.isEmpty {
        return true
      }
      return record.summary.localizedCaseInsensitiveContains(request.query)
    }

    let primaryRecords = filteredRecords
      .filter { request.includeSuperseded || $0.freshnessStatus != .superseded }
      .prefix(request.limit)
    let supportingRecords = filteredRecords
      .dropFirst(primaryRecords.count)
      .prefix(max(request.limit - primaryRecords.count, 0))
    let omittedSuperseded = request.includeSuperseded
      ? []
      : filteredRecords
        .filter { $0.freshnessStatus == .superseded }
        .map(\.id)

    return PraxisSemanticMemoryBundle(
      primaryMemoryIDs: primaryRecords.map(\.id),
      supportingMemoryIDs: supportingRecords.map(\.id),
      omittedSupersededMemoryIDs: omittedSuperseded
    )
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    records = try PraxisLocalJSONFileIO.load([PraxisSemanticMemoryRecord].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(records, to: fileURL)
  }
}

public struct PraxisLocalSemanticSearchIndex: PraxisSemanticSearchIndexContract, Sendable {
  private let semanticMemoryFileURL: URL

  public init(semanticMemoryFileURL: URL) {
    self.semanticMemoryFileURL = semanticMemoryFileURL
  }

  public func search(_ request: PraxisSemanticSearchRequest) async throws -> [PraxisSemanticSearchMatch] {
    let memoryRecords = try PraxisLocalJSONFileIO.load(
      [PraxisSemanticMemoryRecord].self,
      from: semanticMemoryFileURL
    ) ?? []
    let normalizedQuery = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalizedQuery.isEmpty else {
      return []
    }

    return memoryRecords
      .filter { record in
        if let candidateStorageKeys = request.candidateStorageKeys,
           !candidateStorageKeys.contains(record.storageKey) {
          return false
        }
        return record.summary.localizedCaseInsensitiveContains(normalizedQuery)
      }
      .map { record in
        PraxisSemanticSearchMatch(
          id: record.id,
          score: 1,
          contentSummary: record.summary,
          storageKey: record.storageKey
        )
      }
      .prefix(request.limit)
      .map { $0 }
  }
}

private final class PraxisProcessResumeGate: @unchecked Sendable {
  private let lock = NSLock()
  private var hasResumed = false

  func resume(
    continuation: CheckedContinuation<PraxisShellResult, Error>,
    with result: Result<PraxisShellResult, Error>
  ) {
    lock.lock()
    defer { lock.unlock() }
    guard !hasResumed else {
      return
    }
    hasResumed = true
    continuation.resume(with: result)
  }
}

private enum PraxisLocalProcessRunner {
  static func run(
    executableURL: URL,
    arguments: [String],
    currentDirectoryURL: URL? = nil,
    environment: [String: String] = [:],
    timeoutSeconds: Double? = nil
  ) async throws -> PraxisShellResult {
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    let startTime = Date()
    process.executableURL = executableURL
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectoryURL
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, newValue in newValue }
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    return try await withCheckedThrowingContinuation { continuation in
      let resumeGate = PraxisProcessResumeGate()
      let resume: @Sendable (Result<PraxisShellResult, Error>) -> Void = { result in
        resumeGate.resume(continuation: continuation, with: result)
      }

      process.terminationHandler = { process in
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(decoding: stdoutData, as: UTF8.self)
        let stderr = String(decoding: stderrData, as: UTF8.self)
        let duration = Int(Date().timeIntervalSince(startTime) * 1000)
        let terminationReason: PraxisShellTerminationReason = switch process.terminationReason {
        case .exit:
          .exited
        case .uncaughtSignal:
          .cancelled
        @unknown default:
          .failedToLaunch
        }
        resume(
          .success(
            PraxisShellResult(
              stdout: stdout,
              stderr: stderr,
              exitCode: process.terminationStatus,
              durationMilliseconds: duration,
              terminationReason: terminationReason
            )
          )
        )
      }

      do {
        try process.run()
      } catch {
        resume(.failure(error))
        return
      }

      guard let timeoutSeconds, timeoutSeconds > 0 else {
        return
      }

      Task.detached {
        let nanoseconds = UInt64(timeoutSeconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        guard process.isRunning else {
          return
        }
        process.terminate()
        resume(
          .success(
            PraxisShellResult(
              stdout: "",
              stderr: "Command timed out after \(timeoutSeconds) seconds.",
              exitCode: process.terminationStatus,
              durationMilliseconds: Int(Date().timeIntervalSince(startTime) * 1000),
              terminationReason: .timedOut
            )
          )
        )
      }
    }
  }
}

public struct PraxisSystemShellExecutor: PraxisShellExecutor, Sendable {
  public init() {}

  public func run(_ command: PraxisShellCommand) async throws -> PraxisShellResult {
    try await PraxisLocalProcessRunner.run(
      executableURL: URL(fileURLWithPath: "/bin/zsh", isDirectory: false),
      arguments: ["-lc", command.command],
      currentDirectoryURL: command.workingDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) },
      environment: command.environment,
      timeoutSeconds: command.timeoutSeconds
    )
  }
}

public struct PraxisSystemGitAvailabilityProbe: PraxisGitAvailabilityProbe, Sendable {
  public init() {}

  public func probeGitReadiness() async -> PraxisGitAvailabilityReport {
    let fileManager = FileManager.default
    let candidatePaths = [
      "/usr/bin/git",
      "/opt/homebrew/bin/git",
      "/usr/local/bin/git",
    ]

    guard let executablePath = candidatePaths.first(where: { fileManager.isExecutableFile(atPath: $0) }) else {
      return PraxisGitAvailabilityReport(
        status: .unavailable,
        executablePath: nil,
        versionString: nil,
        supportsWorktree: false,
        remediationHint: "Install Xcode Command Line Tools or Git before using local runtime git features.",
        notes: "System git executable was not found in standard locations."
      )
    }

    do {
      let result = try await PraxisLocalProcessRunner.run(
        executableURL: URL(fileURLWithPath: executablePath, isDirectory: false),
        arguments: ["--version"],
        timeoutSeconds: 5
      )
      let combinedOutput = [result.stdout, result.stderr]
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

      if result.exitCode == 0 {
        return PraxisGitAvailabilityReport(
          status: .ready,
          executablePath: executablePath,
          versionString: combinedOutput.isEmpty ? nil : combinedOutput,
          supportsWorktree: supportsGitWorktree(versionString: combinedOutput),
          remediationHint: nil,
          notes: "System git responded successfully to --version."
        )
      }

      if looksLikeCommandLineToolsPrompt(combinedOutput) {
        return PraxisGitAvailabilityReport(
          status: .installPromptExpected,
          executablePath: executablePath,
          versionString: combinedOutput.isEmpty ? nil : combinedOutput,
          supportsWorktree: false,
          remediationHint: "Launch `git --version` once in Terminal or install Xcode Command Line Tools to finish enabling system git.",
          notes: "System git exists but appears to still require Command Line Tools activation."
        )
      }

      return PraxisGitAvailabilityReport(
        status: .unavailable,
        executablePath: executablePath,
        versionString: combinedOutput.isEmpty ? nil : combinedOutput,
        supportsWorktree: false,
        remediationHint: "Check the system git installation and PATH configuration.",
        notes: "System git exited unsuccessfully during readiness probing."
      )
    } catch {
      return PraxisGitAvailabilityReport(
        status: .unavailable,
        executablePath: executablePath,
        versionString: nil,
        supportsWorktree: false,
        remediationHint: "System git probing failed: \(error).",
        notes: "The runtime could not execute system git."
      )
    }
  }

  private func supportsGitWorktree(versionString: String) -> Bool {
    let numericParts = versionString
      .split(whereSeparator: { !$0.isNumber })
      .compactMap { Int($0) }
    guard numericParts.count >= 2 else {
      return false
    }
    let major = numericParts[0]
    let minor = numericParts[1]
    return major > 2 || (major == 2 && minor >= 5)
  }

  private func looksLikeCommandLineToolsPrompt(_ output: String) -> Bool {
    let normalized = output.lowercased()
    return normalized.contains("xcode-select")
      || normalized.contains("command line tools")
      || normalized.contains("developer tools")
  }
}

public extension PraxisHostAdapterRegistry {
  static func localDefaults(rootDirectory: URL? = nil) -> PraxisHostAdapterRegistry {
    let scaffold = scaffoldDefaults()
    let paths = PraxisLocalRuntimePaths(
      rootDirectory: PraxisLocalRuntimePaths.resolveRootDirectory(rootDirectory)
    )

    return PraxisHostAdapterRegistry(
      capabilityExecutor: scaffold.capabilityExecutor,
      providerInferenceExecutor: scaffold.providerInferenceExecutor,
      providerEmbeddingExecutor: scaffold.providerEmbeddingExecutor,
      providerFileStore: scaffold.providerFileStore,
      providerBatchExecutor: scaffold.providerBatchExecutor,
      providerSkillRegistry: scaffold.providerSkillRegistry,
      providerSkillActivator: scaffold.providerSkillActivator,
      providerMCPExecutor: scaffold.providerMCPExecutor,
      workspaceReader: scaffold.workspaceReader,
      workspaceSearcher: scaffold.workspaceSearcher,
      workspaceWriter: scaffold.workspaceWriter,
      shellExecutor: PraxisSystemShellExecutor(),
      browserExecutor: scaffold.browserExecutor,
      browserGroundingCollector: scaffold.browserGroundingCollector,
      gitAvailabilityProbe: PraxisSystemGitAvailabilityProbe(),
      gitExecutor: scaffold.gitExecutor,
      processSupervisor: scaffold.processSupervisor,
      checkpointStore: PraxisLocalCheckpointStore(fileURL: paths.checkpointsFileURL),
      journalStore: PraxisLocalJournalStore(fileURL: paths.journalFileURL),
      projectionStore: PraxisLocalProjectionStore(fileURL: paths.projectionsFileURL),
      messageBus: PraxisLocalMessageBus(),
      deliveryTruthStore: PraxisLocalDeliveryTruthStore(fileURL: paths.deliveryTruthFileURL),
      embeddingStore: PraxisLocalEmbeddingStore(fileURL: paths.embeddingsFileURL),
      semanticSearchIndex: PraxisLocalSemanticSearchIndex(semanticMemoryFileURL: paths.semanticMemoryFileURL),
      semanticMemoryStore: PraxisLocalSemanticMemoryStore(fileURL: paths.semanticMemoryFileURL),
      lineageStore: scaffold.lineageStore,
      userInputDriver: scaffold.userInputDriver,
      permissionDriver: scaffold.permissionDriver,
      terminalPresenter: scaffold.terminalPresenter,
      conversationPresenter: scaffold.conversationPresenter,
      audioTranscriptionDriver: scaffold.audioTranscriptionDriver,
      speechSynthesisDriver: scaffold.speechSynthesisDriver,
      imageGenerationDriver: scaffold.imageGenerationDriver
    )
  }
}
