// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rephraser",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Rephraser", targets: ["Rephraser"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "2.21.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "Rephraser",
            dependencies: [
                "HotKey",
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Rephraser",
            exclude: ["Info.plist", "Rephraser.entitlements", "Assets.xcassets"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
