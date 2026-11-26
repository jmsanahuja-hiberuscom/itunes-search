// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SearchFeature",
    defaultLocalization: "es",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        // Domain: solo Foundation, sin dependencias.
        .target(name: "Domain"),
        // Data: implementa los protocolos de Domain.
        .target(name: "Data", dependencies: ["Domain"]),
        // Presentation: depende solo de Domain (nunca de Data).
        .target(
            name: "Presentation",
            dependencies: ["Domain"],
            resources: [.process("Resources")]
        ),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data", "Domain"],
            resources: [.process("Fixtures")]
        ),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"]),
    ],
    swiftLanguageModes: [.v6]
)
