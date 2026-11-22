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
        .library(
            name: "OversizeArchitectureTesting",
            targets: ["OversizeArchitectureTesting"]
        ),
        .library(
            name: "OversizeArchitectureDebug",
            targets: ["OversizeArchitectureDebug"]
        ),
        .executable(
            name: "oversize-debug",
            targets: ["OversizeArchitectureDebugCLI"]
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
        .target(name: "OversizeArchitectureTesting", dependencies: ["OversizeArchitecture"]),
        .target(name: "OversizeArchitectureDebug", dependencies: ["OversizeArchitecture"]),
        .target(name: "OversizeArchitectureDebugClient", dependencies: ["OversizeArchitecture", "OversizeArchitectureDebug"]),
        .executableTarget(
            name: "OversizeArchitectureDebugCLI",
            dependencies: ["OversizeArchitecture", "OversizeArchitectureDebug", "OversizeArchitectureDebugClient"]
        ),
        .testTarget(
            name: "OversizeArchitectureTests",
            dependencies: [
                "OversizeArchitecture",
                "OversizeArchitectureTesting",
                "OversizeArchitectureDebug",
                "OversizeArchitectureDebugClient",
                "OversizeArchitectureMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
