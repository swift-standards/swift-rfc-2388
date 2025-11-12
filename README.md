# Swift RFC 2388

[![CI](https://github.com/swift-standards/swift-rfc-2388/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-2388/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 2388: Returning Values from Forms - multipart/form-data encoding standard.

## Overview

RFC 2388 defines how HTML forms encode data for transmission, particularly when uploading files. This package provides a pure Swift implementation of the form data parsing and encoding specification, with support for multiple array notation conventions commonly used across different web frameworks.

The package converts between URL-encoded query strings and structured `FormData` representations, handling simple values, arrays, and nested objects with full percent-encoding support according to WHATWG URL encoding standards.

## Features

- **Multiple Array Notations**: Support for empty brackets (`tags[]=value`), indexed brackets (`items[0]=value`), and accumulate values (`color=red&color=blue`)
- **Nested Structure Support**: Parse and encode deeply nested objects like `user[address][city]=Amsterdam`
- **Percent Encoding**: Full support for WHATWG URL encoding with plus-as-space convention
- **Type-Safe API**: Indirect enum design prevents infinite recursion and provides compile-time safety
- **Round-Trip Conversion**: Parse query strings to structured data and encode back with configurable strategies
- **Zero Dependencies**: Pure Swift implementation (except WHATWG URL encoding utilities)

## Installation

Add swift-rfc-2388 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-2388.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 2388", package: "swift-rfc-2388")
    ]
)
```

## Quick Start

### Parsing Form Data

```swift
import RFC_2388

// Parse simple key-value pairs
let data = FormData.parse("name=John&age=30")
// Result: .dictionary(["name": .value("John"), "age": .value("30")])

// Parse arrays with bracket notation
let tags = FormData.parse("tags[]=swift&tags[]=vapor", strategy: .brackets)
// Result: .dictionary(["tags": .array([.value("swift"), .value("vapor")])])

// Parse nested objects
let user = FormData.parse("user[name]=John&user[email]=john@example.com")
// Result: .dictionary([
//     "user": .dictionary([
//         "name": .value("John"),
//         "email": .value("john@example.com")
//     ])
// ])
```

### Encoding Form Data

```swift
let data = FormData.dictionary([
    "name": .value("John"),
    "tags": .array([.value("swift"), .value("vapor")])
])

// Encode with brackets strategy
let query = data.encode(strategy: .brackets, percentEncode: false)
// Result: "name=John&tags[]=swift&tags[]=vapor"

// Encode with indexed brackets
let indexed = data.encode(strategy: .bracketsWithIndices, percentEncode: false)
// Result: "name=John&tags[0]=swift&tags[1]=vapor"

// Encode with accumulate values
let accumulated = data.encode(strategy: .accumulateValues, percentEncode: false)
// Result: "name=John&tags=swift&tags=vapor"
```

### Array Notation Strategies

**Brackets Strategy** (default):
```swift
// tags[]=swift&tags[]=vapor
FormData.parse("tags[]=value1&tags[]=value2", strategy: .brackets)
```

**Brackets with Indices**:
```swift
// items[0]=first&items[1]=second
FormData.parse("items[0]=first&items[1]=second", strategy: .bracketsWithIndices)
```

**Accumulate Values**:
```swift
// color=red&color=blue
FormData.parse("color=red&color=blue", strategy: .accumulateValues)
```

## Usage

### FormData Type

The core `FormData` type is an indirect enum with three cases:

```swift
public enum FormData: Sendable, Equatable, Hashable {
    case value(String)
    case array([FormData])
    indirect case dictionary([String: FormData])
}
```

### Parsing Methods

```swift
// Parse with default brackets strategy
static func parse(_ query: String, strategy: ParsingStrategy = .brackets, sort: Bool = false) -> FormData

// Extract key-value pairs
static func extractPairs(from query: String, sort: Bool = false) -> [(String, String?)]
```

### Encoding Method

```swift
// Encode to query string
func encode(strategy: EncodingStrategy = .brackets, percentEncode: Bool = true) -> String
```

### Property Accessors

```swift
var stringValue: String?         // Extract if .value case
var arrayValue: [FormData]?     // Extract if .array case
var dictionaryValue: [String: FormData]?  // Extract if .dictionary case
```

## Related Packages

### Dependencies
- [swift-whatwg-url-encoding](https://github.com/swift-standards/swift-whatwg-url-encoding) - WHATWG URL encoding utilities for percent-encoding with plus-as-space convention

### Used By
- [swift-url-form-coding](https://github.com/coenttb/swift-url-form-coding) - Codable-based form encoding/decoding using RFC 2388

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
