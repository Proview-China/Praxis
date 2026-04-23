import PraxisCheckpoint
import PraxisCmpTypes
import PraxisJournal

/// Persists and reloads checkpoint snapshots for recovery.
public protocol PraxisCheckpointStoreContract: Sendable {
  /// Stores a checkpoint snapshot.
  ///
  /// - Parameter record: Checkpoint snapshot to persist.
  /// - Returns: A receipt describing the persisted pointer and tier.
  func save(_ record: PraxisCheckpointRecord) async throws -> PraxisCheckpointSaveReceipt

  /// Loads a checkpoint snapshot by pointer.
  ///
  /// - Parameter pointer: Pointer identifying the checkpoint.
  /// - Returns: The persisted record when present; otherwise `nil`.
  func load(pointer: PraxisCheckpointPointer) async throws -> PraxisCheckpointRecord?
}

/// Appends and slices the persistent journal stream.
public protocol PraxisJournalStoreContract: Sendable {
  /// Appends a batch of journal events.
  ///
  /// - Parameter batch: Events to append.
  /// - Returns: A receipt describing the append window.
  func append(_ batch: PraxisJournalRecordBatch) async throws -> PraxisJournalAppendReceipt

  /// Reads a deterministic journal slice from the persistent stream.
  ///
  /// - Parameter request: Slice request describing the session, cursor, and limit.
  /// - Returns: A journal slice ready for replay.
  func read(_ request: PraxisJournalSliceRequest) async throws -> PraxisJournalSlice
}

/// Stores provider conversation turns for session-scoped context replay.
public protocol PraxisConversationStateStoreContract: Sendable {
  func save(_ record: PraxisConversationTurnRecord) async throws -> PraxisConversationStateWriteReceipt
  func history(_ query: PraxisConversationHistoryQuery) async throws -> PraxisConversationHistoryRecord
  func latest(projectID: String, sessionID: String) async throws -> PraxisConversationTurnRecord?
}

/// Stores projection descriptors that HostRuntime can inspect or recover.
public protocol PraxisProjectionStoreContract: Sendable {
  /// Persists a projection descriptor.
  ///
  /// - Parameter descriptor: Projection descriptor to persist.
  /// - Returns: A receipt describing the write target.
  func save(_ descriptor: PraxisProjectionRecordDescriptor) async throws -> PraxisProjectionStoreWriteReceipt

  /// Returns the latest projection descriptor for a project.
  ///
  /// - Parameter projectId: Project identifier that scopes the lookup.
  /// - Returns: The latest descriptor known for the project.
  func describe(projectId: String) async throws -> PraxisProjectionRecordDescriptor

  /// Returns projection descriptors that match the supplied query.
  ///
  /// - Parameter query: Structured projection lookup query.
  /// - Returns: Matching descriptors ordered by recency.
  func describe(_ query: PraxisProjectionDescriptorQuery) async throws -> [PraxisProjectionRecordDescriptor]
}

/// Persists host-backed CMP context package descriptors for readback and recovery.
public protocol PraxisCmpContextPackageStoreContract: Sendable {
  /// Saves or updates a context package descriptor.
  ///
  /// - Parameter descriptor: Package descriptor to persist.
  /// - Returns: A receipt describing the stored package status.
  func save(_ descriptor: PraxisCmpContextPackageDescriptor) async throws -> PraxisCmpContextPackageStoreWriteReceipt

  /// Returns package descriptors that match the supplied query.
  ///
  /// - Parameter query: Structured package lookup query.
  /// - Returns: Matching package descriptors ordered by recency.
  func describe(_ query: PraxisCmpContextPackageQuery) async throws -> [PraxisCmpContextPackageDescriptor]
}

/// Persists host-backed CMP control descriptors for neutral control readback and mutation.
public protocol PraxisCmpControlStoreContract: Sendable {
  /// Saves or updates a CMP control descriptor.
  ///
  /// - Parameter descriptor: Control descriptor to persist.
  /// - Returns: A receipt describing the stored control scope.
  func save(_ descriptor: PraxisCmpControlDescriptor) async throws -> PraxisCmpControlStoreWriteReceipt

  /// Returns the latest control descriptor that matches the supplied query.
  ///
  /// - Parameter query: Structured control lookup query.
  /// - Returns: The matching control descriptor when present; otherwise `nil`.
  func describe(_ query: PraxisCmpControlQuery) async throws -> PraxisCmpControlDescriptor?
}

/// Persists host-backed CMP peer-approval descriptors for TAP bridge request/readback flows.
public protocol PraxisCmpPeerApprovalStoreContract: Sendable {
  /// Saves or updates a CMP peer-approval descriptor.
  ///
  /// - Parameter descriptor: Peer-approval descriptor to persist.
  /// - Returns: A receipt describing the stored approval scope.
  func save(_ descriptor: PraxisCmpPeerApprovalDescriptor) async throws -> PraxisCmpPeerApprovalStoreWriteReceipt

  /// Returns the latest peer-approval descriptor that matches the supplied query.
  ///
  /// - Parameter query: Structured approval lookup query.
  /// - Returns: The matching approval descriptor when present; otherwise `nil`.
  func describe(_ query: PraxisCmpPeerApprovalQuery) async throws -> PraxisCmpPeerApprovalDescriptor?

  /// Returns all peer-approval descriptors that match the supplied query.
  ///
  /// - Parameter query: Structured approval lookup query.
  /// - Returns: Matching approval descriptors ordered by latest update first.
  func describeAll(_ query: PraxisCmpPeerApprovalQuery) async throws -> [PraxisCmpPeerApprovalDescriptor]
}

/// Persists append-only TAP runtime audit events for readback and export flows.
public protocol PraxisTapRuntimeEventStoreContract: Sendable {
  /// Appends one immutable TAP runtime event.
  ///
  /// - Parameter record: Runtime event to append.
  /// - Returns: A receipt describing the appended event.
  func append(_ record: PraxisTapRuntimeEventRecord) async throws -> PraxisTapRuntimeEventStoreWriteReceipt

  /// Reads TAP runtime events that match the supplied query.
  ///
  /// - Parameter query: Structured event lookup query.
  /// - Returns: Matching TAP runtime events ordered by newest first.
  func read(_ query: PraxisTapRuntimeEventQuery) async throws -> [PraxisTapRuntimeEventRecord]
}

/// Publishes messages onto the host message bus.
public protocol PraxisMessageBusContract: Sendable {
  /// Publishes a message.
  ///
  /// - Parameter message: Message to publish.
  /// - Returns: A publication receipt acknowledging that the host accepted the message.
  func publish(_ message: PraxisPublishedMessage) async throws -> PraxisMessagePublicationReceipt

  /// Registers a lightweight subscription with the host bus.
  ///
  /// - Parameters:
  ///   - topic: Topic to subscribe to.
  ///   - consumerID: Stable consumer identifier.
  /// - Returns: A subscription descriptor.
  func subscribe(topic: String, consumerID: String) async throws -> PraxisMessageSubscription
}

/// Persists delivery truth updates emitted by the transport layer.
public protocol PraxisDeliveryTruthStoreContract: Sendable {
  /// Saves or updates a delivery truth record.
  ///
  /// - Parameter record: Delivery truth state to upsert.
  /// - Returns: A receipt describing the resulting stored state.
  func save(_ record: PraxisDeliveryTruthRecord) async throws -> PraxisDeliveryTruthUpsertReceipt

  /// Looks up a single truth record by delivery identifier.
  ///
  /// - Parameter deliveryID: Delivery identifier to look up.
  /// - Returns: The matching truth record when present; otherwise `nil`.
  func lookup(deliveryID: String) async throws -> PraxisDeliveryTruthRecord?

  /// Searches truth records using a structured query.
  ///
  /// - Parameter query: Structured delivery truth query.
  /// - Returns: Matching truth records.
  func lookup(_ query: PraxisDeliveryTruthQuery) async throws -> [PraxisDeliveryTruthRecord]
}

/// Persists embedding metadata and storage references.
public protocol PraxisEmbeddingStoreContract: Sendable {
  /// Saves embedding metadata.
  ///
  /// - Parameter record: Embedding record to persist.
  /// - Returns: A receipt describing the stored embedding.
  func save(_ record: PraxisEmbeddingRecord) async throws -> PraxisEmbeddingStoreWriteReceipt

  /// Loads embedding metadata by identifier.
  ///
  /// - Parameter embeddingID: Embedding identifier to load.
  /// - Returns: The embedding record when present; otherwise `nil`.
  func load(embeddingID: String) async throws -> PraxisEmbeddingRecord?
}

/// Queries the local semantic search index.
public protocol PraxisSemanticSearchIndexContract: Sendable {
  /// Executes a semantic search request.
  ///
  /// - Parameter request: Structured semantic search query.
  /// - Returns: Ranked semantic matches.
  func search(_ request: PraxisSemanticSearchRequest) async throws -> [PraxisSemanticSearchMatch]
}

/// Persists semantic memory records and builds memory bundles for runtime recall.
public protocol PraxisSemanticMemoryStoreContract: Sendable {
  /// Saves a semantic memory record.
  ///
  /// - Parameter record: Semantic memory record to persist.
  /// - Returns: A receipt describing the stored record.
  func save(_ record: PraxisSemanticMemoryRecord) async throws -> PraxisSemanticMemoryWriteReceipt

  /// Loads a semantic memory record by identifier.
  ///
  /// - Parameter memoryID: Memory identifier to load.
  /// - Returns: The semantic memory record when present; otherwise `nil`.
  func load(memoryID: String) async throws -> PraxisSemanticMemoryRecord?

  /// Searches semantic memory records.
  ///
  /// - Parameter request: Structured memory search request.
  /// - Returns: Matching semantic memory records.
  func search(_ request: PraxisSemanticMemorySearchRequest) async throws -> [PraxisSemanticMemoryRecord]

  /// Builds a compact runtime memory bundle.
  ///
  /// - Parameter request: Bundle request describing scope and supersession policy.
  /// - Returns: A memory bundle suitable for runtime recall.
  func bundle(_ request: PraxisSemanticMemoryBundleRequest) async throws -> PraxisSemanticMemoryBundle
}

/// Resolves lineage descriptors from host persistence.
public protocol PraxisLineageStoreContract: Sendable {
  /// Saves a lineage descriptor for later projection and recovery lookups.
  ///
  /// - Parameter descriptor: Lineage descriptor to persist.
  /// - Returns: None.
  func save(_ descriptor: PraxisLineageDescriptor) async throws

  /// Returns a human-readable lineage summary.
  ///
  /// - Parameter lineageID: Lineage identifier to describe.
  /// - Returns: A short summary string.
  func describe(lineageID: PraxisCmpLineageID) async throws -> String

  /// Returns a structured lineage descriptor.
  ///
  /// - Parameter request: Structured lineage lookup request.
  /// - Returns: The lineage descriptor when present; otherwise `nil`.
  func describe(_ request: PraxisLineageLookupRequest) async throws -> PraxisLineageDescriptor?
}
