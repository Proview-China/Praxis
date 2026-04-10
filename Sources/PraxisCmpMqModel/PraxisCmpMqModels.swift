import PraxisCmpDelivery

public struct PraxisTopicTopology: Sendable, Equatable, Codable {
  public let topicName: String
  public let neighborhoods: [String]

  public init(topicName: String, neighborhoods: [String]) {
    self.topicName = topicName
    self.neighborhoods = neighborhoods
  }
}

public struct PraxisRoutingPlan: Sendable, Equatable, Codable {
  public let deliveryPlan: PraxisDeliveryPlan
  public let destinationTopics: [String]

  public init(deliveryPlan: PraxisDeliveryPlan, destinationTopics: [String]) {
    self.deliveryPlan = deliveryPlan
    self.destinationTopics = destinationTopics
  }
}

public struct PraxisNeighborhoodGraph: Sendable, Equatable, Codable {
  public let nodes: [String]
  public let edges: [String]

  public init(nodes: [String], edges: [String]) {
    self.nodes = nodes
    self.edges = edges
  }
}

public struct PraxisEscalationPlan: Sendable, Equatable, Codable {
  public let summary: String

  public init(summary: String) {
    self.summary = summary
  }
}
