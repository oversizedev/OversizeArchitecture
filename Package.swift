// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "OversizeArchitecture",
    platforms: [.macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v10)],
    products: [
        .library(
            name: "OversizeArchitecture",
            targets: ["OversizeArchitecture"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: "601.0.0")),
    ],
    targets: [
        .macro(
            name: "OversizeArchitectureMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "OversizeArchitecture", dependencies: ["OversizeArchitectureMacros"]),
        .testTarget(
            name: "OversizeArchitectureTests",
            dependencies: [
                "OversizeArchitecture",
                "OversizeArchitectureMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
