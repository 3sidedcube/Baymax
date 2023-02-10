// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Baymax",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Baymax",
            targets: ["Baymax"]
        )
    ],
    targets: [
        .target(
            name: "Baymax",
            path: "Baymax",
            exclude: [
                "Baymax.h",
                "Info.plist"
            ],
            resources: [
                .copy("Table View Cells/InformationTableViewCell.xib"),
                .copy("Table View Cells/SwitchTableViewCell.xib"),
                .copy("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "BaymaxTests",
            dependencies: ["Baymax"],
            path: "BaymaxTests",
            exclude: [
                "Info.plist"
            ]
        )
    ]
)
