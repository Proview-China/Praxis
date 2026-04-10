import PraxisCmpProjection
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement models such as ProjectionPersistencePlan, PackagePersistencePlan, and StorageTopology.
// - Implement planner-only and schema semantics for DB reads and writes.
// - Keep this target as a DB model layer without binding directly to PostgreSQL or SQLite clients.
// - This file can later be split into StorageTopology.swift, ProjectionPersistencePlan.swift, PackagePersistencePlan.swift, and DeliveryPersistencePlan.swift.

public enum PraxisCmpDbModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpDbModel",
    responsibility: "CMP DB topology、projection/package/delivery persistence model 与 write plans。",
    tsModules: [
      "src/agent_core/cmp-db",
    ],
  )
}
