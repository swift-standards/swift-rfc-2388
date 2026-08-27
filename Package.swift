// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-2388",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 2388",
            targets: ["RFC 2388"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-compositions/swift-html-form-coder.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-standards/swift-html-standard.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 2388",
            dependencies: [
                .product(name: "HTML Form Coder", package: "swift-html-form-coder"),
                .product(name: "HTML Form Coder Nested", package: "swift-html-form-coder"),
                .product(name: "HTML Standard", package: "swift-html-standard"),
            ]
        ),
        .testTarget(
            name: "RFC 2388 Tests",
            dependencies: [
                "RFC 2388"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
