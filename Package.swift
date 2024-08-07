// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let cSettings: [PackageDescription.CSetting] = []

let package = Package(
    name: "KnowledgeBase",
    platforms: [
        .macOS("12.0"), .iOS("15.0"), .tvOS("15.0"), .watchOS("8.0")
    ],
    products: [
        .library(
            name: "KnowledgeBase",
            targets: ["KnowledgeBase"]
        )
    ],
    dependencies: [
//            .package(name: "RDFStorage", path: "../RDFStorage")
    ],
    targets: [
        .target(
            name: "KnowledgeBase",
            dependencies: [
//                    "RDFStorage"
            ],
            exclude: [
                "Storage",
                "APIs",
                "Serialization",
                // TODO: Re-enable SPARQL endpoint
                "SPARQL",
                "APIs_Swift_5_5/SPARQLAPI.swift",
                // TODO: Still need to be ported
                "Rules",
                "Models/Event",
                "Syncing"
            ],
            cSettings: cSettings
        ),
        .executableTarget(
            name: "KnowledgeBaseXPCService",
            dependencies: [
                "KnowledgeBase"
            ],
            cSettings: cSettings
        ),
        .testTarget(
            name: "KnowledgeBaseTestsAsyncAwait",
            dependencies: ["KnowledgeBase"],
            exclude: [
                // TODO: Re-enable SPARQL endpoint
                "SPARQLTestCase.swift"
            ],
            cSettings: cSettings
        )
    ]
)
