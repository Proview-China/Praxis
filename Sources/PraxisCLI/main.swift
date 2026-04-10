#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

// TODO(reboot-plan):
// - Replace the current print scaffold with a real CLI app bootstrap, command router, and terminal session.
// - Enter the runtime through PraxisRuntimeGateway -> PraxisRuntimeInterface instead of assembling internal module state directly.
// - Plan the CLI path for interactive sessions, non-interactive commands, log replay, and permission prompts.
// - This file can later be split into CLIApp.swift, CommandRouter.swift, TerminalRenderer.swift, and InteractiveSession.swift.

do {
  let app = try PraxisCLIApp(configuration: .init(interactive: false))
  let output = try await app.run(arguments: Array(CommandLine.arguments.dropFirst()))
  print(output)
} catch {
  let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
  if let data = "\(message)\n".data(using: .utf8) {
    FileHandle.standardError.write(data)
  }
  exit(1)
}
