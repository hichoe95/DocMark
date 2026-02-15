// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DocMark",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DocMark", targets: ["DocMark"])
    ],
    dependencies: [
        .package(url: "https://github.com/LiYanan2004/MarkdownView", from: "2.4.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.29.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "DocMark",
            dependencies: [
                .product(name: "MarkdownView", package: "MarkdownView"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/DocMark",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "DocMarkTests",
            dependencies: ["DocMark"],
            path: "Tests/DocMarkTests"
        ),
    ]
)
