import PraxisRuntimePresentationBridge

// TODO(reboot-plan):
// - Replace the current print scaffold with a real CLI app bootstrap, command router, and terminal session.
// - Enter the runtime through PraxisRuntimePresentationBridge instead of assembling internal module state directly.
// - Plan the CLI path for interactive sessions, non-interactive commands, log replay, and permission prompts.
// - This file can later be split into CLIApp.swift, CommandRouter.swift, TerminalRenderer.swift, and InteractiveSession.swift.

let blueprint = PraxisRuntimePresentationBridgeModule.bootstrap

print("Praxis Swift scaffold ready.")
print("Foundation modules:")
for module in blueprint.foundationModules {
  print("- \(module.name): \(module.responsibility)")
}

print("Functional domain modules:")
for module in blueprint.functionalDomainModules {
  print("- \(module.name): \(module.responsibility)")
}

print("Host contract modules:")
for module in blueprint.hostContractModules {
  print("- \(module.name): \(module.responsibility)")
}

print("Runtime modules:")
for module in blueprint.runtimeModules {
  print("- \(module.name): \(module.responsibility)")
}

print("Entrypoints: \(blueprint.entrypoints.joined(separator: ", "))")
print("Rules:")
for rule in blueprint.rules {
  print("- \(rule)")
}
