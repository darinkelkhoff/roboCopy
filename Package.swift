// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RoboCopy",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RoboCopyCore", targets: ["RoboCopyCore"]),
        .executable(name: "RoboCopy", targets: ["RoboCopy"]),
    ],
    targets: [
        .target(name: "RoboCopyCore"),
        .executableTarget(name: "RoboCopy", dependencies: ["RoboCopyCore"]),
        .testTarget(name: "RoboCopyCoreTests", dependencies: ["RoboCopyCore"]),
    ]
)
