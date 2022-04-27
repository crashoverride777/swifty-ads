// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let packageName = "SwiftyAds"

let package = Package(
    name: packageName,
    platforms: [.iOS(.v12)],
    products: [.library(name: packageName, targets: [packageName])],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "9.4.0")
    ],
    targets: [
        .target(
            name: packageName,
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: packageName + "Tests",
            dependencies: ["SwiftyAds"],
            path: "Tests",
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageVersions: [.v5]
)

