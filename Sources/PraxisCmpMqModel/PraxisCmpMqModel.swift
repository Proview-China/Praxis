import PraxisCmpDelivery
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement models such as TopicTopology, RoutingPlan, NeighborhoodGraph, and EscalationPlan.
// - Implement pure rules for MQ topics, routing, neighborhood relationships, and escalation strategies.
// - Keep this target as a message-queue planner/model layer without binding directly to Redis, NATS, or Kafka.
// - This file can later be split into TopicTopology.swift, RoutingPlan.swift, NeighborhoodGraph.swift, and EscalationPlan.swift.

public enum PraxisCmpMqModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpMqModel",
    responsibility: "CMP MQ topic topology、routing、neighborhood relation 与 escalation planning。",
    tsModules: [
      "src/agent_core/cmp-mq",
    ],
  )
}
