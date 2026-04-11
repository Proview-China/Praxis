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
  func cliSourcesDoNotBypassGatewayAndRuntimeInterface() throws {
    let violations = try HostRuntimeBoundaryGuardSupport.unexpectedImports(
      in: "Sources/PraxisCLI",
      forbiddenModules: PraxisHostNeutralRuntimeBoundary.cliForbiddenDirectImports
    )

    if !violations.isEmpty {
      Issue.record(
        """
        CLI sources must enter through RuntimeGateway -> RuntimeInterface only.
        Unexpected imports:
        \(violations.joined(separator: "\n"))
        """
      )
    }
  }

  @Test
  func appleUISourcesDependOnlyOnPresentationBridgeForRuntimeAccess() throws {
    let forbiddenViolations = try HostRuntimeBoundaryGuardSupport.unexpectedImports(
      in: "Sources/PraxisAppleUI",
      forbiddenModules: PraxisHostNeutralRuntimeBoundary.appleUIForbiddenDirectImports
    )
    let allowlistViolations = try HostRuntimeBoundaryGuardSupport.nonAllowlistedImports(
      in: "Sources/PraxisAppleUI",
      allowedModules: PraxisHostNeutralRuntimeBoundary.appleUIAllowedRuntimeImports
    )
    let violations = forbiddenViolations + allowlistViolations

    if !violations.isEmpty {
      Issue.record(
        """
        AppleUI sources must stay behind RuntimePresentationBridge and avoid direct runtime/domain imports.
        Unexpected imports:
        \(violations.joined(separator: "\n"))
        """
      )
    }
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
}
