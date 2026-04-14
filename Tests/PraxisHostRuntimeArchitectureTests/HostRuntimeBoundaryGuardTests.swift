import Foundation
import Testing
@testable import PraxisRuntimeFacades

private enum HostRuntimeBoundaryGuardSupport {
  static let repositoryRoot: URL = {
    var candidate = URL(fileURLWithPath: #filePath, isDirectory: false).deletingLastPathComponent()
    let fileManager = FileManager.default

    while true {
      let manifestURL = candidate.appendingPathComponent("Package.swift", isDirectory: false)
      if fileManager.fileExists(atPath: manifestURL.path) {
        return candidate
      }

      let parent = candidate.deletingLastPathComponent()
      precondition(parent.path != candidate.path, "Failed to locate Package.swift from \(#filePath)")
      candidate = parent
    }
  }()

  static func swiftSourceFiles(in relativeDirectory: String) throws -> [URL] {
    let directoryURL = repositoryRoot.appendingPathComponent(relativeDirectory, isDirectory: true)
    let enumerator = FileManager.default.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )

    var files: [URL] = []
    while let next = enumerator?.nextObject() as? URL {
      guard next.pathExtension == "swift" else {
        continue
      }
      files.append(next)
    }

    return files.sorted { $0.path < $1.path }
  }

  static func importedModules(in sourceFile: URL) throws -> [String] {
    let contents = try String(contentsOf: sourceFile, encoding: .utf8)
    return contents
      .split(whereSeparator: \.isNewline)
      .compactMap { rawLine in
        moduleName(fromImportLine: String(rawLine))
      }
  }

  static func moduleName(fromImportLine rawLine: String) -> String? {
    let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !line.isEmpty else {
      return nil
    }

    if line.hasPrefix("//") || line.hasPrefix("/*") || line.hasPrefix("*") || line.hasPrefix("*/") {
      return nil
    }

    let tokens = line.split(whereSeparator: \.isWhitespace)
    guard let importIndex = tokens.firstIndex(of: "import") else {
      return nil
    }

    let importKinds: Set<Substring> = [
      "typealias",
      "struct",
      "class",
      "enum",
      "protocol",
      "let",
      "var",
      "func",
    ]

    let moduleTokenIndex = importIndex + 1
    guard moduleTokenIndex < tokens.endIndex else {
      return nil
    }

    let rawModuleToken: Substring
    if importKinds.contains(tokens[moduleTokenIndex]) {
      let scopedTokenIndex = moduleTokenIndex + 1
      guard scopedTokenIndex < tokens.endIndex else {
        return nil
      }
      rawModuleToken = tokens[scopedTokenIndex]
    } else {
      rawModuleToken = tokens[moduleTokenIndex]
    }

    let sanitizedModuleToken = rawModuleToken
      .split(separator: "/").first?
      .split(separator: ".").first
    return sanitizedModuleToken.map(String.init)
  }

  static func unexpectedImports(
    in relativeDirectory: String,
    forbiddenModules: [String]
  ) throws -> [String] {
    let forbidden = Set(forbiddenModules)
    var violations: [String] = []
    for sourceFile in try swiftSourceFiles(in: relativeDirectory) {
      let imported = try importedModules(in: sourceFile)
      let blocked = imported.filter { forbidden.contains($0) }
      guard !blocked.isEmpty else {
        continue
      }
      violations.append("\(sourceFile.path): \(blocked.joined(separator: ", "))")
    }
    return violations
  }

  static func fileContents(in relativeDirectory: String) throws -> [(URL, String)] {
    try swiftSourceFiles(in: relativeDirectory).map { sourceFile in
      (sourceFile, try String(contentsOf: sourceFile, encoding: .utf8))
    }
  }

  static func nonAllowlistedImports(
    in relativeDirectory: String,
    allowedModules: [String]
  ) throws -> [String] {
    let allowed = Set(allowedModules)
    var violations: [String] = []
    for sourceFile in try swiftSourceFiles(in: relativeDirectory) {
      let imported = try importedModules(in: sourceFile)
      let blocked = imported.filter { !allowed.contains($0) }
      guard !blocked.isEmpty else {
        continue
      }
      violations.append("\(sourceFile.path): \(blocked.joined(separator: ", "))")
    }
    return violations
  }
}

struct HostRuntimeBoundaryGuardTests {
  @Test(arguments: [
    ("import Foo", "Foo"),
    ("@testable import Foo", "Foo"),
    ("@_implementationOnly import Foo", "Foo"),
    ("@_spi(Internal) import Foo", "Foo"),
    ("import struct Foo.Bar", "Foo"),
    ("import class Foo.Bar", "Foo"),
    ("import enum Foo.Bar", "Foo"),
    ("import protocol Foo.Bar", "Foo"),
    ("import let Foo.Bar", "Foo"),
    ("import var Foo.Bar", "Foo"),
    ("import func Foo.Bar", "Foo"),
    ("@_spi(Internal) import struct Foo.Bar", "Foo"),
    ("// import Foo", nil),
    ("/* import Foo */", nil),
    ("* import Foo", nil),
  ])
  func importParserNormalizesSupportedSwiftImportForms(
    line: String,
    expectedModule: String?
  ) {
    #expect(HostRuntimeBoundaryGuardSupport.moduleName(fromImportLine: line) == expectedModule)
  }

  @Test
  func hostNeutralMiddleLayerAvoidsPresentationFrameworkImports() throws {
    let sourceDirectories = [
      "Sources/PraxisRuntimeInterface",
      "Sources/PraxisRuntimeGateway",
      "Sources/PraxisRuntimeFacades",
      "Sources/PraxisRuntimeUseCases",
    ]
    let violations = try sourceDirectories.flatMap { directory in
      try HostRuntimeBoundaryGuardSupport.unexpectedImports(
        in: directory,
        forbiddenModules: PraxisHostNeutralRuntimeBoundary.middleLayerForbiddenPresentationImports
      )
    }

    if !violations.isEmpty {
      Issue.record(
        """
        Host-neutral middle-layer modules must remain presentation-free.
        Unexpected imports:
        \(violations.joined(separator: "\n"))
        """
      )
    }
  }

  @Test
  func runtimeKitAvoidsTransportAndCompositionImports() throws {
    let violations = try HostRuntimeBoundaryGuardSupport.unexpectedImports(
      in: "Sources/PraxisRuntimeKit",
      forbiddenModules: [
        "PraxisRuntimeComposition",
        "PraxisRuntimeInterface",
        "PraxisFFI",
      ]
    )

    if !violations.isEmpty {
      Issue.record(
        """
        PraxisRuntimeKit must stay above composition and transport layers.
        Unexpected imports:
        \(violations.joined(separator: "\n"))
        """
      )
    }
  }

  @Test
  func runtimeKitPublicSurfaceAvoidsTransportAndBootstrapTypes() throws {
    let forbiddenPublicSnippets = [
      "public struct PraxisRuntimeClientConfiguration",
      "public let configuration",
      "public let runtimeFacade",
      "public static func makeClient(",
      "public func makeGoalSource(",
      "public func normalizeGoal(",
      "public func compileGoal(",
      "public func inspectTap(",
      "public func inspectCmp(",
      "public func inspectMp(",
      "public func readbackTapStatus(",
      "public func readbackTapHistory(",
      "public func status(\n    projectID:",
      "public func history(\n    projectID:",
      "public func tapStatus(",
      "PraxisHostAdapterRegistry",
      "PraxisRuntimeBlueprint",
      "PraxisRuntimeInterface",
      "PraxisFFI",
    ]

    let violations = try HostRuntimeBoundaryGuardSupport.fileContents(in: "Sources/PraxisRuntimeKit")
      .flatMap { sourceFile, contents in
        forbiddenPublicSnippets.compactMap { snippet in
          contents.contains(snippet) ? "\(sourceFile.path): \(snippet)" : nil
        }
      }

    if !violations.isEmpty {
      Issue.record(
        """
        PraxisRuntimeKit public surface must not expose transport, export, or composition-specific details.
        Violations:
        \(violations.joined(separator: "\n"))
        """
      )
    }

    let runtimeClientSource = HostRuntimeBoundaryGuardSupport.repositoryRoot
      .appendingPathComponent("Sources/PraxisRuntimeKit/PraxisRuntimeClient.swift")
    let runtimeClientContents = try String(contentsOf: runtimeClientSource, encoding: .utf8)
    let forbiddenRuntimeClientSnippets = [
      "public func runGoal(",
      "public func resumeRun(",
    ]
    let runtimeClientViolations = forbiddenRuntimeClientSnippets.compactMap { snippet in
      runtimeClientContents.contains(snippet) ? "\(runtimeClientSource.path): \(snippet)" : nil
    }

    if !runtimeClientViolations.isEmpty {
      Issue.record(
        """
        PraxisRuntimeClient should stay as a thin shell over narrower scoped clients.
        Violations:
        \(runtimeClientViolations.joined(separator: "\n"))
        """
      )
    }

    let scopedSurfaceChecks: [(String, [String])] = [
      (
        "Sources/PraxisRuntimeKit/PraxisRuntimeRunClient.swift",
        [
          "public func runGoal(",
          "public func resumeRun(_ runID: String)",
        ]
      ),
      (
        "Sources/PraxisRuntimeKit/PraxisRuntimeTapClient.swift",
        [
          "public func project(_ projectID: String)",
          "public func overview(\n    agentID: String? = nil,",
        ]
      ),
      (
        "Sources/PraxisRuntimeKit/PraxisRuntimeCmpClient.swift",
        [
          "public func project(_ projectID: String)",
          "public func bootstrap(\n    agentIDs: [String] = [],",
          "public func overview(agentID: String? = nil)",
          "public func approvalOverview(\n    agentID: String? = nil,",
          "public func request(\n    agentID: String,",
          "public func decide(\n    agentID: String,",
          "public func readback(\n    agentID: String? = nil,",
          "public func openSession(sessionID: String? = nil)",
        ]
      ),
      (
        "Sources/PraxisRuntimeKit/PraxisRuntimeMpClient.swift",
        [
          "public func project(_ projectID: String)",
          "public func search(\n    _ query: String,",
          "public func overview(\n    query: String = \"\",",
          "public func resolve(\n    _ query: String,",
          "public func history(\n    for query: String,",
          "public func align(\n    alignedAt: String? = nil,",
          "public func promote(\n    to targetPromotionState:",
          "public func archive(\n    archivedAt: String? = nil,",
          "public func memory(_ memoryID: String)",
        ]
      ),
      (
        "Sources/PraxisRuntimeKit/PraxisRuntimeKitInputs.swift",
        [
          "public let sessionID: String?",
          "public let agentID: String?",
          "public let agentIDs: [String]",
          "public let defaultAgentID: String?",
          "public let targetAgentID: String",
          "public let capabilityID: String",
          "public let reviewerAgentID: String?",
          "public let requesterAgentID: String",
          "public let requesterSessionID: String?",
          "public let targetSessionID: String?",
        ]
      ),
    ]

    let scopedViolations = try scopedSurfaceChecks.flatMap { relativePath, snippets in
      let fileURL = HostRuntimeBoundaryGuardSupport.repositoryRoot.appendingPathComponent(relativePath)
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      return snippets.compactMap { snippet in
        contents.contains(snippet) ? "\(fileURL.path): \(snippet)" : nil
      }
    }

    if !scopedViolations.isEmpty {
      Issue.record(
        """
        Scoped RuntimeKit clients should expose grouped overview/resource entrypoints instead of flat duplicate commands.
        Violations:
        \(scopedViolations.joined(separator: "\n"))
        """
      )
    }
  }
}
