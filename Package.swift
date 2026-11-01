// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "OversizeArchitecture",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10)],
    products: [
        .library(
            name: "OversizeArchitecture",
            targets: ["OversizeArchitecture"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0" ..< "605.0.0")
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
