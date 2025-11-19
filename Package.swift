// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-2388",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 2388",
            targets: ["RFC 2388"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-whatwg-url-encoding.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RFC 2388",
            dependencies: [
                .product(name: "WHATWG URL Encoding", package: "swift-whatwg-url-encoding")
            ]
        ),
        .testTarget(
            name: "RFC 2388 Tests",
            dependencies: ["RFC 2388"]
        ),
    ]
)
