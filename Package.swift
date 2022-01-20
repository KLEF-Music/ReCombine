// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReCombine",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "ReCombine", targets: ["ReCombine"]),
        .library(name: "ReCombineTest", targets: ["ReCombineTest"]),
    ],
    dependencies: [
        // Here we define our package's external dependencies
        // and from where they can be fetched:
        .package(
            url: "https://github.com/pointfreeco/swift-case-paths",
            from: "0.7.0"
        )
    ],
    targets: [
        .target(name: "ReCombine", dependencies: ["CasePaths"]),
        .testTarget(name: "ReCombineTests", dependencies: ["ReCombine"]),
        .target(name: "ReCombineTest", dependencies: ["ReCombine"]),
        .testTarget(name: "ReCombineTestTests", dependencies: ["ReCombine", "ReCombineTest"]),
    ]
)
