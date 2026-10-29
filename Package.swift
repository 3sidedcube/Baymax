// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Baymax",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .library(
            name: "Baymax",
            type: .dynamic,
            targets: ["Baymax"]
        )
    ],
    targets: [
        .target(
            name: "Baymax",
            path: "Sources/Baymax",
            resources: [
                .process("Table View Cells/InformationTableViewCell.xib"),
                .process("Table View Cells/SwitchTableViewCell.xib"),
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "BaymaxTests",
            dependencies: ["Baymax"],
            path: "Tests/BaymaxTests"
        )
    ]
)
