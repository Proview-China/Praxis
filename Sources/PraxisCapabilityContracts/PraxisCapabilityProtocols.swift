public protocol PraxisCapabilityContract: Sendable {
  var manifest: PraxisCapabilityManifest { get }
  var executionPolicy: PraxisCapabilityExecutionPolicy { get }
}
