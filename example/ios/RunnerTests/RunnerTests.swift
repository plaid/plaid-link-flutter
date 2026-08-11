import Flutter
import UIKit
import XCTest

@testable import plaid_link_flutter

class RunnerTests: XCTestCase {

  // Guards the Flutter bridge version reported to LinkKit for wrapper analytics.
  // Kept in sync with pubspec/podspec/manifest by tool/check_versions.sh.
  func testBridgeVersionMatchesRelease() {
    XCTAssertEqual(PlaidFlutterPlugin.sdkVersion, "1.0.0")
  }

  func testGetSdkVersionReturnsNativeVersion() {
    let plugin = PlaidLinkFlutterPlugin()
    let call = FlutterMethodCall(methodName: "getSdkVersion", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let version = result as? String
      XCTAssertNotNil(version, "getSdkVersion should return the native SDK version string")
      XCTAssertFalse(version?.isEmpty ?? true)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testCreateLinkSessionWithoutTokenReturnsInvalidToken() {
    let plugin = PlaidLinkFlutterPlugin()
    let call = FlutterMethodCall(
      methodName: "createPlaidLinkSession",
      arguments: [String: Any]()
    )

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      guard let error = result as? FlutterError else {
        XCTFail("Expected a FlutterError, got \(String(describing: result))")
        resultExpectation.fulfill()
        return
      }
      XCTAssertEqual(error.code, "INVALID_TOKEN")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
