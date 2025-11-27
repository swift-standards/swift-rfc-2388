//
//  FormData.Encoder.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//

import WHATWG_Form_URL_Encoded

extension FormData {
    /// Strategies for encoding arrays in form data.
    ///
    /// Corresponds to the parsing strategies but used for serialization.
    public enum EncodingStrategy: Sendable, Equatable {
        /// Encode arrays using empty bracket notation (`tags[]=value`)
        case brackets

        /// Encode arrays using indexed bracket notation (`items[0]=value`)
        case bracketsWithIndices

        /// Encode arrays by repeating the key (`key=val1&key=val2`)
        case accumulateValues
    }

    /// Encodes FormData into a URL-encoded query string.
    ///
    /// This function serializes FormData structures back into URL-encoded
    /// form data strings according to RFC 2388 conventions.
    ///
    /// - Parameters:
    ///   - strategy: The encoding strategy for arrays
    ///   - percentEncode: Whether to percent-encode the output (default: true)
    /// - Returns: URL-encoded query string
    ///
    /// ## Example
    ///
    /// ```swift
    /// let data = FormData.dictionary([
    ///     "name": .value("John"),
    ///     "tags": .array([.value("swift"), .value("vapor")])
    /// ])
    ///
    /// // With brackets strategy
    /// let encoded = data.encode(strategy: .brackets)
    /// // Result: "name=John&tags[]=swift&tags[]=vapor"
    ///
    /// // With accumulate strategy
    /// let encoded2 = data.encode(strategy: .accumulateValues)
    /// // Result: "name=John&tags=swift&tags=vapor"
    /// ```
    public func encode(
        strategy: EncodingStrategy = .brackets,
        percentEncode: Bool = true
    ) -> String {
        let raw = encodeWithStrategy(prefix: "", strategy: strategy)

        if percentEncode {
            return WHATWG_Form_URL_Encoded.percentEncode(raw, spaceAsPlus: true)
        } else {
            return raw
        }
    }

    /// Recursively encodes FormData with a given prefix and strategy.
    ///
    /// - Parameters:
    ///   - prefix: The current path prefix (e.g., "user[address]")
    ///   - strategy: The encoding strategy for arrays
    /// - Returns: URL-encoded string segment
    private func encodeWithStrategy(
        prefix: String,
        strategy: EncodingStrategy
    ) -> String {
        switch self {
        case .value(let str):
            return prefix.isEmpty ? str : "\(prefix)=\(str)"

        case .dictionary(let dict):
            return
                dict
                .sorted(by: { $0.key < $1.key })
                .map { key, value in
                    let newPrefix = prefix.isEmpty ? key : "\(prefix)[\(key)]"
                    return value.encodeWithStrategy(prefix: newPrefix, strategy: strategy)
                }
                .joined(separator: "&")

        case .array(let array):
            switch strategy {
            case .accumulateValues:
                // Repeat the key for each value
                return
                    array
                    .map { value in
                        value.encodeWithStrategy(prefix: prefix, strategy: strategy)
                    }
                    .joined(separator: "&")

            case .brackets:
                // Use empty bracket notation
                return
                    array
                    .map { value in
                        let newPrefix = "\(prefix)[]"
                        return value.encodeWithStrategy(prefix: newPrefix, strategy: strategy)
                    }
                    .joined(separator: "&")

            case .bracketsWithIndices:
                // Use indexed notation
                return
                    array
                    .enumerated()
                    .map { idx, value in
                        let newPrefix = "\(prefix)[\(idx)]"
                        return value.encodeWithStrategy(prefix: newPrefix, strategy: strategy)
                    }
                    .joined(separator: "&")
            }
        }
    }
}
