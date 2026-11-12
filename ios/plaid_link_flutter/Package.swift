// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "plaid_link_flutter",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "plaid-link-flutter", targets: ["plaid_link_flutter"])
  ],
  dependencies: [
    // Required by Flutter 3.41+ when the plugin is integrated through Swift Package
    // Manager; the sibling path is created by the Flutter tooling. pubspec.yaml keeps
    // its `flutter: '>=3.29.3'` floor on purpose: this manifest is only read when
    // SwiftPM integration is active, and older consumers continue to use CocoaPods.
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    // LinkKit is vendored rather than fetched so the CocoaPods and Swift Package
    // Manager paths ship the byte-identical framework that tool/validate_linkkit.sh
    // pins. When CocoaPods support is dropped this becomes a package dependency on
    // https://github.com/plaid/plaid-link-ios-spm; see CONTRIBUTING.md.
    //
    // The path must stay inside this package directory. Flutter symlinks the package
    // into the app's ephemeral Packages directory, and SwiftPM resolves binary target
    // paths relative to that symlink, so a path reaching outside the package (such as
    // ../Frameworks) is not found during an app build.
    .binaryTarget(name: "LinkKit", path: "LinkKit.xcframework"),
    .target(
      name: "plaid_link_flutter",
      dependencies: [
        "LinkKit",
        .product(name: "FlutterFramework", package: "FlutterFramework"),
      ],
      resources: [
        .process("Resources")
      ]
    )
  ]
)
