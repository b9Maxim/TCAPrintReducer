// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "TCAPrintReducer",
  platforms: [.iOS(.v15), .macOS(.v15)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "TCAPrintReducer",
      targets: ["TCAPrintReducer"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.3"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.21.1"),
    .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", branch: "4.4.3")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.

    // Core types that can be used by both main module and macros
    .target(
      name: "TCAPrintReducerTypes",
      dependencies: []
    ),

    // Macro implementation that performs the source transformation of a macro.
    .macro(
      name: "TCAPrintReducerMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        "TCAPrintReducerTypes",
      ]
    ),

    // Library that exposes a macro as part of its API, which is used in client programs.
    .target(
      name: "TCAPrintReducer", dependencies: ["TCAPrintReducerMacros", "TCAPrintReducerTypes"]),

    // Example target to demonstrate macro usage
    .executableTarget(
      name: "MacroExamples",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "ObjectMapper", package: "ObjectMapper"),
        "TCAPrintReducer"
      ],
      path: "Examples"
    ),
  ]
)
