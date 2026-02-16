// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift_frontend",
    platforms: [
        // This is a server-side Swift build that generates static frontend assets.
        // It is NOT an iOS app target in this environment.
        .macOS(.v13)
    ],
    products: [
        .executable(name: "swift_frontend", targets: ["swift_frontend"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "swift_frontend",
            dependencies: []
        )
    ]
)
