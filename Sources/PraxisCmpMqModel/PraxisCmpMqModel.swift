import PraxisCmpDelivery
import PraxisCmpTypes
import PraxisCoreTypes

// TODO(reboot-plan):
// - 实现 TopicTopology、RoutingPlan、NeighborhoodGraph、EscalationPlan 等模型。
// - 实现 MQ 投递主题、路由、邻接关系和升级策略的纯规则。
// - 保持这里是消息队列 planner/model，不直接绑定 Redis/NATS/Kafka。
// - 文件可继续拆分：TopicTopology.swift、RoutingPlan.swift、NeighborhoodGraph.swift、EscalationPlan.swift。

public enum PraxisCmpMqModelModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisCmpMqModel",
    responsibility: "CMP MQ topic topology、routing、neighborhood relation 与 escalation planning。",
    tsModules: [
      "src/agent_core/cmp-mq",
    ],
  )
}
