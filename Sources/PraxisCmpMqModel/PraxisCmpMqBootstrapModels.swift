public struct PraxisCmpRedisNamespace: Sendable, Equatable, Codable {
  public let namespaceRoot: String
  public let keyPrefix: String
  public let queuePrefix: String
  public let streamPrefix: String

  public init(namespaceRoot: String, keyPrefix: String, queuePrefix: String, streamPrefix: String) {
    self.namespaceRoot = namespaceRoot
    self.keyPrefix = keyPrefix
    self.queuePrefix = queuePrefix
    self.streamPrefix = streamPrefix
  }
}

public struct PraxisCmpRedisTopicBinding: Sendable, Equatable, Codable {
  public let topicName: String
  public let channel: String
  public let redisKey: String

  public init(topicName: String, channel: String, redisKey: String) {
    self.topicName = topicName
    self.channel = channel
    self.redisKey = redisKey
  }
}

public struct PraxisCmpMqBootstrapReceipt: Sendable, Equatable, Codable {
  public let projectID: String
  public let agentID: String
  public let namespace: PraxisCmpRedisNamespace
  public let bindings: [PraxisCmpRedisTopicBinding]

  public init(
    projectID: String,
    agentID: String,
    namespace: PraxisCmpRedisNamespace,
    bindings: [PraxisCmpRedisTopicBinding]
  ) {
    self.projectID = projectID
    self.agentID = agentID
    self.namespace = namespace
    self.bindings = bindings
  }
}
