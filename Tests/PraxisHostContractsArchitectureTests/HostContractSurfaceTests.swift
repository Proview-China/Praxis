import XCTest
@testable import PraxisProviderContracts

final class HostContractSurfaceTests: XCTestCase {
  func testProviderContractsNowCoverWebSearchSurface() {
    let request = PraxisProviderWebSearchRequest(query: "Swift Package Manager", locale: "zh-CN")
    let response = PraxisProviderWebSearchResponse(
      query: request.query,
      results: [
        .init(title: "SwiftPM", snippet: "Apple package manager", url: "https://example.com/swiftpm")
      ]
    )

    XCTAssertEqual(request.locale, "zh-CN")
    XCTAssertEqual(response.results.count, 1)
    XCTAssertEqual(response.results.first?.title, "SwiftPM")
  }
}
