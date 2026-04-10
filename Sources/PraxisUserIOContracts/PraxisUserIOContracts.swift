import PraxisCoreTypes

// TODO(reboot-plan):
// - Implement protocol families for user input, permission handling, and terminal/conversation presentation.
// - Add models for structured questioning, permission-decision callbacks, render events, presentation state, and multimodal user-I/O chips.
// - Keep user I/O focused on interaction boundaries rather than business orchestration.
// - This file can later be split into UserInputDriver.swift, PermissionDriver.swift, TerminalPresenter.swift, ConversationPresenter.swift, and UserIOMultimodalRequests.swift.

public enum PraxisUserIOContractsModule {
  public static let boundary = PraxisBoundaryDescriptor(
    name: "PraxisUserIOContracts",
    responsibility: "user input / permission / presenter 协议族。",
    tsModules: [
      "src/agent_core/live-agent-chat.ts",
      "src/agent_core/live-agent-chat/ui.ts",
      "src/agent_core/integrations/tap-vendor-user-io-adapter.ts",
    ],
  )
}
