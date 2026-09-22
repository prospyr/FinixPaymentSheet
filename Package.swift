// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FinixPaymentSheet",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FinixPaymentSheet",
            targets: ["FinixPaymentSheet"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "FinixPaymentSheet",
            path: "FinixPaymentSheet.xcframework"
        )
    ]
)
