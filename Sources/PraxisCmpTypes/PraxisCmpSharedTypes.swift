public enum PraxisCmpPriority: String, Sendable, Codable {
  case low
  case normal
  case high
  case urgent
}

public enum PraxisCmpScope: String, Sendable, Codable {
  case local
  case shared
  case global
}
