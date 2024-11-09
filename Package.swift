// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let packageName = "SwiftyAds"

let package = Package(
    name: packageName,
    platforms: [.iOS(.v14)],
    products: [.library(name: packageName, targets: [packageName])],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.3.0")
    ],
    targets: [
        .target(
            name: packageName,
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Sources"
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
