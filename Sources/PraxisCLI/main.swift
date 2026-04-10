import PraxisRuntimePresentationBridge

// TODO(reboot-plan):
// - Replace the current print scaffold with a real CLI app bootstrap, command router, and terminal session.
// - Enter the runtime through PraxisRuntimePresentationBridge instead of assembling internal module state directly.
// - Plan the CLI path for interactive sessions, non-interactive commands, log replay, and permission prompts.
// - This file can later be split into CLIApp.swift, CommandRouter.swift, TerminalRenderer.swift, and InteractiveSession.swift.

let app = try PraxisCLIApp(configuration: .init(interactive: false))
let state = app.bootstrapState()
let blueprint = PraxisRuntimePresentationBridgeModule.bootstrap

print("Praxis Swift scaffold ready.")
print("\(state.title): \(state.summary)")
print("Entrypoints: \(blueprint.entrypoints.joined(separator: ", "))")
