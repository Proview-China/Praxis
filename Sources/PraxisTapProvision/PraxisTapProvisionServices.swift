import PraxisCapabilityContracts
import PraxisTapTypes

/// Core-side read model for provision assets.
/// This type owns asset definitions that can participate in planning, but it does not perform installation, activation, or external side effects.
public struct PraxisProvisionRegistry: Sendable {
  public private(set) var entries: [PraxisProvisionRegistryEntry]

  public init(entries: [PraxisProvisionRegistryEntry] = []) {
    self.entries = entries
  }

  /// Registers or replaces a provision asset definition.
  ///
  /// - Parameters:
  ///   - entry: The asset definition to write into the registry.
  /// - Returns: None.
  public mutating func register(_ entry: PraxisProvisionRegistryEntry) {
    entries.removeAll { $0.asset.name == entry.asset.name }
    entries.append(entry)
  }

  /// Filters registry assets that can participate in planning by capability and mode.
  ///
  /// - Parameters:
  ///   - capabilityID: The target capability for the current provisioning request. When `nil`, capability filtering is skipped.
  ///   - mode: The current TAP mode. When `nil`, mode filtering is skipped.
  /// - Returns: The list of provision assets that match the requested filters.
  public func assets(
    for capabilityID: PraxisCapabilityID?,
    mode: PraxisTapMode?
  ) -> [PraxisProvisionAsset] {
    let canonicalMode = mode?.canonicalMode

    return entries.compactMap { entry -> PraxisProvisionAsset? in
      if let capabilityID, entry.asset.capabilityID != capabilityID {
        return nil
      }

      if let canonicalMode {
        let effectiveSupportedModes = entry.supportedModes.isEmpty ? entry.asset.supportedModes : entry.supportedModes
        guard effectiveSupportedModes.isEmpty || effectiveSupportedModes.contains(where: { $0.canonicalMode == canonicalMode }) else {
          return nil
        }
      }

      return entry.asset
    }
  }
}

/// Default provisioning planner.
/// This type answers what should be provisioned, how it should be verified, and how it can be rolled back, but it does not trigger host execution directly.
public struct PraxisProvisionPlanner: Sendable {
  public let registry: PraxisProvisionRegistry

  public init(registry: PraxisProvisionRegistry = .init()) {
    self.registry = registry
  }

  /// Builds a Core-only plan for a provisioning request.
  ///
  /// - Parameters:
  ///   - request: The current provisioning request.
  /// - Returns: A provision plan containing candidate assets, verification steps, rollback guidance, and approval markers.
  public func plan(_ request: PraxisProvisionRequest) -> PraxisProvisionPlan {
    let selectedAssets = registry.assets(for: request.capabilityID, mode: request.mode)
      .filter { $0.status == .readyForReview || $0.status == .active }

    let verificationPlan: [String]
    if request.requiredVerification.isEmpty {
      let target = request.capabilityID?.rawValue ?? "requested capability"
      verificationPlan = ["Run smoke verification for \(target)."]
    } else {
      verificationPlan = request.requiredVerification.map { "Run \($0) verification." }
    }

    let rollbackPlan = [
      "Preserve or reference the previous binding before staging a replacement.",
      "Remove newly staged provision assets if verification fails.",
    ]

    let summary: String
    if let capabilityID = request.capabilityID {
      summary = "Plan provisioning work for \(capabilityID.rawValue) without executing the blocked task."
    } else {
      summary = "Plan provisioning work without executing the blocked task."
    }

    let hasUnapprovedAssets = selectedAssets.contains { $0.status != .active }
    let requiresApproval = request.replayPolicy == .manual || selectedAssets.isEmpty || hasUnapprovedAssets
    return PraxisProvisionPlan(
      request: request,
      selectedAssets: selectedAssets,
      summary: summary,
      requiresApproval: requiresApproval,
      verificationPlan: verificationPlan,
      rollbackPlan: rollbackPlan
    )
  }
}
