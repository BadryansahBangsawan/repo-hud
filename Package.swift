// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RepoHUD",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "RepoHUD", targets: ["RepoHUD"])
    ],
    targets: [
        .executableTarget(name: "RepoHUD", path: "Sources")
    ]
)
