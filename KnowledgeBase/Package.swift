// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KnowledgeBase",
    platforms: [
        .macOS(.v10_12), .iOS(.v11), .tvOS(.v10), .watchOS(.v3)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KnowledgeBase",
            targets: ["KnowledgeBase"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "CRDFStorage", path: "../CRDFStorage")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "KnowledgeBase",
            dependencies: ["CRDFStorage"]
        ),
        .testTarget(
            name: "KnowledgeBaseTests",
            dependencies: ["KnowledgeBase"]),
    ]
)
