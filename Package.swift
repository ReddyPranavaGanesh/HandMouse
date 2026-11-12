// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandMouse",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "HandMouse",
            path: "Sources"
        )
    ]
)
