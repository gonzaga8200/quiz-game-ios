// swift-tools-version: 6.2
// The game rules of Contrarreloj, ported 1:1 from the web's `core/` (TypeScript).
// No UI, no Firebase, no platform APIs: it builds and tests on macOS with `swift test`.
import PackageDescription

let package = Package(
    name: "ContrarrelojCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ContrarrelojCore", targets: ["ContrarrelojCore"]),
    ],
    targets: [
        .target(
            name: "ContrarrelojCore",
            swiftSettings: [.treatAllWarnings(as: .error)]
        ),
        .testTarget(
            name: "ContrarrelojCoreTests",
            dependencies: ["ContrarrelojCore"],
            resources: [.copy("Fixtures")],
            swiftSettings: [.treatAllWarnings(as: .error)]
        ),
    ]
)
