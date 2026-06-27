// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "base58swift-vuln",
    dependencies: [
        .package(url: "https://github.com/keefertaylor/Base58Swift.git", from: "2.1.7")
    ],
    targets: [
        .executableTarget(
            name: "base58swift-vuln",
            dependencies: ["Base58Swift"]
        )
    ]
)
