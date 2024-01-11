// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Changeable",
  platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Changeable",
      targets: ["Changeable"]
    ),
    .executable(
      name: "ChangeableClient",
      targets: ["ChangeableClient"]
    )
  ],
  dependencies: [
    .package(url: "git@github.com:num42/swift-macrotester.git", from: "1.0.0"),
    // Depend on the Swift 5.9 release of SwiftSyntax
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(
      url: "https://github.com/realm/SwiftLint",
      from: "0.53.0"
    )
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    // Macro implementation that performs the source transformation of a macro.
    .macro(
      name: "ChangeableMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ],
      plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
    ),

    // Library that exposes a macro as part of its API, which is used in client programs.
    .target(
      name: "Changeable",
      dependencies: ["ChangeableMacros"],
      plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
    ),

    // A client of the library, which is able to use the macro in its own code.
    .executableTarget(
      name: "ChangeableClient",
      dependencies: ["Changeable"],
      plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
    ),
    // A test target used to develop the macro implementation.
    .testTarget(
      name: "ChangeableTests",
      dependencies: ["ChangeableMacros",
        .product(name: "swift-macrotester", package: "swift-macrotester"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
      ],
      plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
    )
  ]
)
