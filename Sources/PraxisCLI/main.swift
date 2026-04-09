import PraxisRuntimePresentationBridge

// TODO(reboot-plan):
// - 把当前打印脚手架替换成真正的 CLI app bootstrap、command router 和 terminal session。
// - 通过 PraxisRuntimePresentationBridge 接入运行时，而不是直接拼内部模块状态。
// - 规划交互式会话、非交互命令、日志回放和权限提示的 CLI 路径。
// - 文件可继续拆分：CLIApp.swift、CommandRouter.swift、TerminalRenderer.swift、InteractiveSession.swift。

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
