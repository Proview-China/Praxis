import PraxisCheckpoint
import PraxisCmpDelivery
import PraxisCmpTypes
import PraxisCoreTypes
import PraxisJournal

// TODO(reboot-plan):
// - Implement contract boundaries for checkpoint, journal, projection, message bus, delivery truth, and embedding stores.
// - Add SQLite persistence keys, versioning, read/write consistency, and batch-processing semantics.
// - Add collaboration boundaries for the local semantic search index, MP semantic memory store, and Accelerate similarity computation.
// - Keep infra focused on infrastructure capabilities instead of CMP or TAP business rules.
// - This file can later be split into CheckpointStore.swift, JournalStore.swift, ProjectionStore.swift, MessageBus.swift, DeliveryTruthStore.swift, EmbeddingStore.swift, SemanticSearchIndex.swift, SemanticMemoryStore.swift, and LineageStore.swift.

public enum PraxisInfraContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisInfraContracts",
    responsibility: "checkpoint / projection store / message bus / local persistence / semantic search infra 协议族。",
    tsModules: [
      "src/agent_core/checkpoint",
      "src/agent_core/cmp-db",
      "src/agent_core/cmp-mq",
      "src/agent_core/mp-lancedb",
      "src/agent_core/mp-runtime",
    ],
  )
}
