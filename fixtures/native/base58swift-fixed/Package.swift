// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "base58swift-fixed",
    dependencies: [
        .package(url: "https://github.com/keefertaylor/Base58Swift.git", revision: "06f76ebb80c155a56b1f495a9ae2063b5e983862")
    ],
    targets: [
        .executableTarget(
            name: "base58swift-fixed",
            dependencies: ["Base58Swift"]
        )
    ]
)
