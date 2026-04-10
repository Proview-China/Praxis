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
  let lineageFileURL: URL

  init(rootDirectory: URL) {
    self.rootDirectory = rootDirectory
    checkpointsFileURL = rootDirectory.appendingPathComponent("checkpoints.json", isDirectory: false)
    journalFileURL = rootDirectory.appendingPathComponent("journal.json", isDirectory: false)
    projectionsFileURL = rootDirectory.appendingPathComponent("projections.json", isDirectory: false)
    deliveryTruthFileURL = rootDirectory.appendingPathComponent("delivery-truth.json", isDirectory: false)
    embeddingsFileURL = rootDirectory.appendingPathComponent("embeddings.json", isDirectory: false)
    semanticMemoryFileURL = rootDirectory.appendingPathComponent("semantic-memory.json", isDirectory: false)
    lineageFileURL = rootDirectory.appendingPathComponent("lineages.json", isDirectory: false)
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

private struct PraxisLocalWorkspaceContext: Sendable {
  let rootDirectory: URL

  init(rootDirectory: URL) {
    self.rootDirectory = rootDirectory.standardizedFileURL
  }

  static func resolveRootDirectory(_ explicitRootDirectory: URL?) -> URL {
    if let explicitRootDirectory {
      return explicitRootDirectory
    }

    if let configuredRoot = ProcessInfo.processInfo.environment["PRAXIS_WORKSPACE_ROOT"],
       !configuredRoot.isEmpty {
      return URL(fileURLWithPath: configuredRoot, isDirectory: true)
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
  }

  func resolvePath(_ path: String) throws -> URL {
    let candidate: URL
    if path.hasPrefix("/") {
      candidate = URL(fileURLWithPath: path, isDirectory: false)
    } else {
      candidate = rootDirectory.appendingPathComponent(path, isDirectory: false)
    }
    let standardized = candidate.standardizedFileURL
    let rootPath = rootDirectory.path
    let candidatePath = standardized.path
    guard candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/") else {
      throw PraxisError.invalidInput("Workspace path \(path) escapes the configured local workspace root.")
    }
    return standardized
  }
}

private func localWorkspaceNormalizedLines(from content: String) -> [String] {
  guard !content.isEmpty else {
    return []
  }

  var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
  if content.hasSuffix("\n"), lines.last == "" {
    lines.removeLast()
  }
  return lines
}

private func localWorkspaceSlice(content: String, range: PraxisWorkspaceLineRange?) -> String {
  guard let range else {
    return content
  }

  let lines = localWorkspaceNormalizedLines(from: content)
  guard !lines.isEmpty else {
    return ""
  }

  let startIndex = max(range.startLine - 1, 0)
  let endIndex = min(range.endLine - 1, lines.count - 1)
  guard startIndex <= endIndex, startIndex < lines.count else {
    return ""
  }

  return lines[startIndex...endIndex].joined(separator: "\n")
}

private func localWorkspaceRevisionToken(for fileURL: URL) -> String? {
  guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
    return nil
  }
  let modificationDate = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
  let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
  return "\(Int64(modificationDate * 1000))-\(fileSize)"
}

private func localWorkspaceMatchesFilePattern(_ path: String, filePattern: String?) -> Bool {
  guard let filePattern, !filePattern.isEmpty else {
    return true
  }

  let escaped = NSRegularExpression.escapedPattern(for: filePattern)
    .replacingOccurrences(of: "\\*", with: ".*")
    .replacingOccurrences(of: "\\?", with: ".")
  guard let regex = try? NSRegularExpression(pattern: "^\(escaped)$", options: [.caseInsensitive]) else {
    return path == filePattern
  }
  let range = NSRange(path.startIndex..<path.endIndex, in: path)
  return regex.firstMatch(in: path, options: [], range: range) != nil
}

private func localWorkspaceRoots(
  for requestRoots: [String],
  context: PraxisLocalWorkspaceContext
) -> [URL] {
  let roots = requestRoots.isEmpty ? [context.rootDirectory.path] : requestRoots
  var resolvedRoots: [URL] = []
  for root in roots {
    if let resolved = try? context.resolvePath(root), !resolvedRoots.contains(resolved) {
      resolvedRoots.append(resolved)
    }
  }
  return resolvedRoots.isEmpty ? [context.rootDirectory] : resolvedRoots
}

private func localWorkspaceCandidateFiles(
  for request: PraxisWorkspaceSearchRequest,
  context: PraxisLocalWorkspaceContext
) -> [URL] {
  let fileManager = FileManager.default
  let ignoredDirectories = Set([".git", ".build", "node_modules"])
  let roots = localWorkspaceRoots(for: request.roots, context: context)
  var fileURLs: [URL] = []

  for root in roots {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
      continue
    }

    if !isDirectory.boolValue {
      if localWorkspaceMatchesFilePattern(root.lastPathComponent, filePattern: request.filePattern) {
        fileURLs.append(root)
      }
      continue
    }

    guard let enumerator = fileManager.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
      options: [.skipsHiddenFiles]
    ) else {
      continue
    }

    for case let fileURL as URL in enumerator {
      if ignoredDirectories.contains(fileURL.lastPathComponent) {
        enumerator.skipDescendants()
        continue
      }
      let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
      guard values?.isRegularFile == true else {
        continue
      }
      if let fileSize = values?.fileSize, fileSize > 1_000_000 {
        continue
      }
      if localWorkspaceMatchesFilePattern(fileURL.lastPathComponent, filePattern: request.filePattern) {
        fileURLs.append(fileURL)
      }
    }
  }

  return fileURLs
}

private func localWorkspaceReadText(at fileURL: URL) -> String? {
  guard let data = try? Data(contentsOf: fileURL) else {
    return nil
  }
  return String(data: data, encoding: .utf8)
}

private func localWorkspaceRelativePath(for fileURL: URL, workspaceRoot: URL) -> String {
  let rootComponents = workspaceRoot.standardizedFileURL.pathComponents
  let fileComponents = fileURL.standardizedFileURL.pathComponents
  guard fileComponents.starts(with: rootComponents) else {
    return fileURL.path
  }

  let relativeComponents = Array(fileComponents.dropFirst(rootComponents.count))
  guard !relativeComponents.isEmpty else {
    return fileURL.lastPathComponent
  }
  return NSString.path(withComponents: relativeComponents)
}

private func localWorkspaceSearchMatch(
  for fileURL: URL,
  content: String,
  query: String,
  workspaceRoot: URL
) -> PraxisWorkspaceSearchMatch? {
  let lines = localWorkspaceNormalizedLines(from: content)
  guard let lineIndex = lines.firstIndex(where: { $0.localizedCaseInsensitiveContains(query) }) else {
    return nil
  }

  let line = lines[lineIndex]
  let lowercasedLine = line.lowercased()
  let lowercasedQuery = query.lowercased()
  let column = lowercasedLine.range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: lowercasedLine).advanced(by: 1)
  let relativePath = localWorkspaceRelativePath(for: fileURL, workspaceRoot: workspaceRoot)
  return PraxisWorkspaceSearchMatch(
    path: relativePath,
    line: lineIndex + 1,
    column: column,
    summary: "Matched \(query) in \(fileURL.lastPathComponent).",
    snippet: line
  )
}

public struct PraxisLocalWorkspaceReader: PraxisWorkspaceReader, Sendable {
  private let context: PraxisLocalWorkspaceContext

  public init(rootDirectory: URL) {
    self.context = PraxisLocalWorkspaceContext(rootDirectory: rootDirectory)
  }

  public func read(_ request: PraxisWorkspaceReadRequest) async throws -> PraxisWorkspaceReadResult {
    let fileURL = try context.resolvePath(request.path)
    guard let content = localWorkspaceReadText(at: fileURL) else {
      return PraxisWorkspaceReadResult(path: request.path, content: "", lineCount: 0)
    }
    let slicedContent = localWorkspaceSlice(content: content, range: request.range)
    return PraxisWorkspaceReadResult(
      path: request.path,
      content: slicedContent,
      revisionToken: request.includeRevisionToken ? localWorkspaceRevisionToken(for: fileURL) : nil,
      lineCount: localWorkspaceNormalizedLines(from: slicedContent).count
    )
  }
}

public struct PraxisLocalWorkspaceSearcher: PraxisWorkspaceSearcher, Sendable {
  private let context: PraxisLocalWorkspaceContext

  public init(rootDirectory: URL) {
    self.context = PraxisLocalWorkspaceContext(rootDirectory: rootDirectory)
  }

  public func search(_ request: PraxisWorkspaceSearchRequest) async throws -> [PraxisWorkspaceSearchMatch] {
    guard !request.query.isEmpty else {
      return []
    }

    let files = localWorkspaceCandidateFiles(for: request, context: context)
    var matches: [PraxisWorkspaceSearchMatch] = []

    for fileURL in files {
      guard matches.count < request.maxResults else {
        break
      }

      let relativePath = localWorkspaceRelativePath(for: fileURL, workspaceRoot: context.rootDirectory)

      switch request.kind {
      case .fileName:
        guard fileURL.lastPathComponent.localizedCaseInsensitiveContains(request.query) else {
          continue
        }
        matches.append(
          PraxisWorkspaceSearchMatch(
            path: relativePath,
            summary: "Matched file name \(fileURL.lastPathComponent)."
          )
        )
      case .fullText, .symbol:
        guard let content = localWorkspaceReadText(at: fileURL),
              let match = localWorkspaceSearchMatch(
                for: fileURL,
                content: content,
                query: request.query,
                workspaceRoot: context.rootDirectory
              ) else {
          continue
        }
        matches.append(match)
      }
    }

    return matches
  }
}

public actor PraxisLocalWorkspaceWriter: PraxisWorkspaceWriter {
  private let context: PraxisLocalWorkspaceContext

  public init(rootDirectory: URL) {
    self.context = PraxisLocalWorkspaceContext(rootDirectory: rootDirectory)
  }

  public func apply(_ request: PraxisWorkspaceChangeRequest) async throws -> PraxisWorkspaceChangeReceipt {
    var changedPaths: [String] = []

    for change in request.changes {
      let fileURL = try context.resolvePath(change.path)
      try validateRevisionToken(change.expectedRevisionToken, for: fileURL)

      switch change.kind {
      case .createFile, .updateFile:
        guard let content = change.content else {
          throw PraxisError.invalidInput("Workspace change \(change.kind.rawValue) requires content.")
        }
        try FileManager.default.createDirectory(
          at: fileURL.deletingLastPathComponent(),
          withIntermediateDirectories: true
        )
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
      case .deleteFile:
        if FileManager.default.fileExists(atPath: fileURL.path) {
          try FileManager.default.removeItem(at: fileURL)
        }
      case .applyPatch:
        throw PraxisError.unsupportedOperation("Local workspace patch application is not implemented yet.")
      }

      changedPaths.append(change.path)
    }

    return PraxisWorkspaceChangeReceipt(
      changedPaths: changedPaths,
      appliedChangeCount: changedPaths.count,
      summary: request.changeSummary
    )
  }

  private func validateRevisionToken(_ expectedRevisionToken: String?, for fileURL: URL) throws {
    guard let expectedRevisionToken else {
      return
    }
    let currentRevisionToken = localWorkspaceRevisionToken(for: fileURL)
    guard currentRevisionToken == expectedRevisionToken else {
      throw PraxisError.invariantViolation("Workspace revision token mismatch for \(fileURL.path).")
    }
  }
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

public actor PraxisLocalLineageStore: PraxisLineageStoreContract {
  private let fileURL: URL
  private var descriptors: [PraxisLineageDescriptor] = []
  private var didLoad = false

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func save(_ descriptor: PraxisLineageDescriptor) async throws {
    try loadIfNeeded()
    descriptors.removeAll { $0.lineageID == descriptor.lineageID }
    descriptors.append(descriptor)
    try persist()
  }

  public func describe(lineageID: PraxisCmpLineageID) async throws -> String {
    try loadIfNeeded()
    return descriptors.first { $0.lineageID == lineageID }?.summary ?? "Unknown lineage \(lineageID.rawValue)"
  }

  public func describe(_ request: PraxisLineageLookupRequest) async throws -> PraxisLineageDescriptor? {
    try loadIfNeeded()
    return descriptors.first { $0.lineageID == request.lineageID }
  }

  private func loadIfNeeded() throws {
    guard !didLoad else {
      return
    }
    descriptors = try PraxisLocalJSONFileIO.load([PraxisLineageDescriptor].self, from: fileURL) ?? []
    didLoad = true
  }

  private func persist() throws {
    try PraxisLocalJSONFileIO.save(
      descriptors.sorted { $0.lineageID.rawValue < $1.lineageID.rawValue },
      to: fileURL
    )
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

private enum PraxisSystemGitExecutableResolver {
  static func resolve() -> String? {
    let fileManager = FileManager.default
    let candidatePaths = [
      "/usr/bin/git",
      "/opt/homebrew/bin/git",
      "/usr/local/bin/git",
    ]
    return candidatePaths.first(where: { fileManager.isExecutableFile(atPath: $0) })
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

public struct PraxisSystemGitExecutor: PraxisGitExecutor, Sendable {
  public init() {}

  public func apply(_ plan: PraxisGitPlan) async throws -> PraxisGitExecutionReceipt {
    guard let executablePath = PraxisSystemGitExecutableResolver.resolve() else {
      return PraxisGitExecutionReceipt(
        operationID: plan.operationID,
        status: .rejected,
        outputSummary: "System git executable is unavailable.",
        completedAt: localRuntimeNow()
      )
    }

    var stepSummaries: [String] = []
    var completedStepCount = 0

    for step in plan.steps {
      let arguments = try gitArguments(for: step)
      let result = try await PraxisLocalProcessRunner.run(
        executableURL: URL(fileURLWithPath: executablePath, isDirectory: false),
        arguments: arguments,
        currentDirectoryURL: plan.repositoryRoot.map { URL(fileURLWithPath: $0, isDirectory: true) },
        timeoutSeconds: 15
      )
      let output = [result.stdout, result.stderr]
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

      if result.exitCode == 0 {
        completedStepCount += 1
        stepSummaries.append("\(step.kind.rawValue): \(output.isEmpty ? "ok" : output)")
        continue
      }

      let failureSummary = output.isEmpty ? "git exited with \(result.exitCode)." : output
      stepSummaries.append("\(step.kind.rawValue): \(failureSummary)")
      return PraxisGitExecutionReceipt(
        operationID: plan.operationID,
        status: completedStepCount == 0 ? .rejected : .partial,
        outputSummary: stepSummaries.joined(separator: " | "),
        completedAt: localRuntimeNow()
      )
    }

    let summary = stepSummaries.isEmpty ? plan.summary : stepSummaries.joined(separator: " | ")
    return PraxisGitExecutionReceipt(
      operationID: plan.operationID,
      status: .applied,
      outputSummary: summary,
      completedAt: localRuntimeNow()
    )
  }

  private func gitArguments(for step: PraxisGitPlanStep) throws -> [String] {
    switch step.kind {
    case .verifyRepository:
      return ["rev-parse", "--show-toplevel"]
    case .fetch:
      return ["fetch"] + optionalGitArgument(step.arguments["remote"])
    case .checkout:
      if let target = step.arguments["target"] ?? step.arguments["branch"] {
        if step.arguments["createBranch"] == "true" {
          return ["checkout", "-b", target]
        }
        return ["checkout", target]
      }
      throw PraxisError.invalidInput("Git checkout step requires a target or branch argument.")
    case .commit:
      guard let message = step.arguments["message"], !message.isEmpty else {
        throw PraxisError.invalidInput("Git commit step requires a message argument.")
      }
      return ["commit", "-m", message]
    case .push:
      var arguments = ["push"]
      if let remote = step.arguments["remote"] {
        arguments.append(remote)
      }
      if let branch = step.arguments["branch"] {
        arguments.append(branch)
      }
      return arguments
    case .merge:
      guard let target = step.arguments["target"] ?? step.arguments["branch"] else {
        throw PraxisError.invalidInput("Git merge step requires a target or branch argument.")
      }
      return ["merge", target]
    case .inspectRef:
      guard let ref = step.arguments["ref"] else {
        throw PraxisError.invalidInput("Git inspectRef step requires a ref argument.")
      }
      return ["rev-parse", "--verify", ref]
    case .updateRef:
      guard let ref = step.arguments["ref"],
            let target = step.arguments["target"] else {
        throw PraxisError.invalidInput("Git updateRef step requires ref and target arguments.")
      }
      return ["update-ref", ref, target]
    }
  }

  private func optionalGitArgument(_ value: String?) -> [String] {
    guard let value, !value.isEmpty else {
      return []
    }
    return [value]
  }
}

public struct PraxisSystemGitAvailabilityProbe: PraxisGitAvailabilityProbe, Sendable {
  public init() {}

  public func probeGitReadiness() async -> PraxisGitAvailabilityReport {
    guard let executablePath = PraxisSystemGitExecutableResolver.resolve() else {
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
    let resolvedRootDirectory = PraxisLocalRuntimePaths.resolveRootDirectory(rootDirectory)
    let paths = PraxisLocalRuntimePaths(rootDirectory: resolvedRootDirectory)
    let workspaceRootDirectory = PraxisLocalWorkspaceContext.resolveRootDirectory(rootDirectory)

    return PraxisHostAdapterRegistry(
      runtimeRootDirectory: resolvedRootDirectory,
      workspaceRootDirectory: workspaceRootDirectory,
      capabilityExecutor: scaffold.capabilityExecutor,
      providerInferenceExecutor: scaffold.providerInferenceExecutor,
      providerEmbeddingExecutor: scaffold.providerEmbeddingExecutor,
      providerFileStore: scaffold.providerFileStore,
      providerBatchExecutor: scaffold.providerBatchExecutor,
      providerSkillRegistry: scaffold.providerSkillRegistry,
      providerSkillActivator: scaffold.providerSkillActivator,
      providerMCPExecutor: scaffold.providerMCPExecutor,
      workspaceReader: PraxisLocalWorkspaceReader(rootDirectory: workspaceRootDirectory),
      workspaceSearcher: PraxisLocalWorkspaceSearcher(rootDirectory: workspaceRootDirectory),
      workspaceWriter: PraxisLocalWorkspaceWriter(rootDirectory: workspaceRootDirectory),
      shellExecutor: PraxisSystemShellExecutor(),
      browserExecutor: scaffold.browserExecutor,
      browserGroundingCollector: scaffold.browserGroundingCollector,
      gitAvailabilityProbe: PraxisSystemGitAvailabilityProbe(),
      gitExecutor: PraxisSystemGitExecutor(),
      processSupervisor: scaffold.processSupervisor,
      checkpointStore: PraxisLocalCheckpointStore(fileURL: paths.checkpointsFileURL),
      journalStore: PraxisLocalJournalStore(fileURL: paths.journalFileURL),
      projectionStore: PraxisLocalProjectionStore(fileURL: paths.projectionsFileURL),
      messageBus: PraxisLocalMessageBus(),
      deliveryTruthStore: PraxisLocalDeliveryTruthStore(fileURL: paths.deliveryTruthFileURL),
      embeddingStore: PraxisLocalEmbeddingStore(fileURL: paths.embeddingsFileURL),
      semanticSearchIndex: PraxisLocalSemanticSearchIndex(semanticMemoryFileURL: paths.semanticMemoryFileURL),
      semanticMemoryStore: PraxisLocalSemanticMemoryStore(fileURL: paths.semanticMemoryFileURL),
      lineageStore: PraxisLocalLineageStore(fileURL: paths.lineageFileURL),
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
