// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FreeOCR",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "FreeOCR", targets: ["FreeOCR"])
    ],
    targets: [
        .executableTarget(
            name: "FreeOCR",
            path: "Sources/FreeOCR"
        )
    ]
)
