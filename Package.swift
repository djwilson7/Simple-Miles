// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SimpleMilesBackEnd",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SimpleMilesBackEnd", targets: ["SimpleMilesBackEnd"]),
    ],
    targets: [
        .target(
            name: "SimpleMilesBackEnd",
            path: "BackEnd",
            exclude: [
                // Any files that strictly require iOS/UIKit and can't be mocked easily
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "SimpleMilesTests",
            dependencies: ["SimpleMilesBackEnd"],
            path: "Tests/SimpleMilesTests"
        ),
    ]
)
