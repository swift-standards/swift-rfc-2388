//
//  FormData.Parser.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//

import WHATWG_Form_URL_Encoded

extension FormData {
    /// Parses a URL-encoded query string into structured form data.
    ///
    /// This function implements RFC 2388 form data parsing with support for
    /// various array notation conventions.
    ///
    /// - Parameters:
    ///   - query: The URL-encoded query string to parse
    ///   - strategy: The parsing strategy for array notation
    ///   - sort: Whether to sort the key-value pairs before parsing
    /// - Returns: A FormData structure representing the parsed data
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple values
    /// let data = FormData.parse("name=John&age=30")
    /// // Result: .dictionary(["name": .value("John"), "age": .value("30")])
    ///
    /// // Arrays with brackets
    /// let tags = FormData.parse("tags[]=swift&tags[]=vapor", strategy: .brackets)
    /// // Result: .dictionary(["tags": .array([.value("swift"), .value("vapor")])])
    ///
    /// // Nested objects
    /// let user = FormData.parse("user[name]=John&user[email]=john@example.com")
    /// // Result: .dictionary(["user": .dictionary(["name": .value("John"), "email": .value("john@example.com")])])
    /// ```
    public static func parse(
        _ query: String,
        strategy: ParsingStrategy = .brackets,
        sort: Bool = false
    ) -> FormData {
        switch strategy {
        case .brackets, .bracketsWithIndices:
            let isArray: (String) -> Bool = { segment in
                // Empty string means brackets notation: key[]
                // Non-empty string that's a number means indexed notation: key[0]
                segment.isEmpty || Int(segment) != nil
            }
            return parseBracketNotation(query, isArray: isArray, sort: sort)
        case .accumulateValues:
            return parseAccumulateValues(query, sort: sort)
        }
    }

    /// Parses form data using bracket notation (e.g., `key[]` or `key[0]`).
    ///
    /// Handles nested structures and both empty brackets and indexed brackets.
    ///
    /// - Parameters:
    ///   - query: The URL-encoded query string
    ///   - isArray: Function to determine if a path segment represents an array
    ///   - sort: Whether to sort key-value pairs before parsing
    /// - Returns: Parsed FormData structure
    private static func parseBracketNotation(
        _ query: String,
        isArray: @escaping (String) -> Bool,
        sort: Bool
    ) -> FormData {
        var result = FormData.dictionary([:])

        for (name, value) in extractPairs(from: query, sort: sort) {
            let path = extractPath(from: name)
            insert(value: value ?? "", at: path, into: &result, isArray: isArray)
        }

        return result
    }

    /// Parses form data by accumulating repeated keys into arrays.
    ///
    /// When the same key appears multiple times, all values are collected
    /// into an array.
    ///
    /// - Parameters:
    ///   - query: The URL-encoded query string
    ///   - sort: Whether to sort key-value pairs before parsing
    /// - Returns: Parsed FormData structure
    private static func parseAccumulateValues(_ query: String, sort: Bool) -> FormData {
        var params: [String: FormData] = [:]

        for (name, value) in extractPairs(from: query, sort: sort) {
            let valueStr = value ?? ""

            if let existing = params[name] {
                // Key already exists - accumulate into array
                if case .array(var values) = existing {
                    values.append(.value(valueStr))
                    params[name] = .array(values)
                } else {
                    // Convert single value to array
                    params[name] = .array([existing, .value(valueStr)])
                }
            } else {
                // First occurrence of this key
                params[name] = .value(valueStr)
            }
        }

        return .dictionary(params)
    }

    /// Extracts key-value pairs from a URL-encoded query string.
    ///
    /// Uses WHATWG URL encoding specification for decoding, which treats
    /// `+` as space and handles percent-encoding.
    ///
    /// - Parameters:
    ///   - query: The URL-encoded query string
    ///   - sort: Whether to sort pairs by key name
    /// - Returns: Array of decoded key-value pairs
    public static func extractPairs(
        from query: String,
        sort: Bool = false
    ) -> [(String, String?)] {
        let pairs =
            query
            .split(separator: "&")
            .map { (pairString: Substring) -> (name: String, value: String?) in
                let pairArray =
                    pairString
                    .split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                    .compactMap { substring in
                        try? WHATWG_Form_URL_Encoded.PercentEncoding.decode(
                            String(substring),
                            plusAsSpace: true
                        )
                    }
                return (pairArray[0], pairArray.count == 2 ? pairArray[1] : nil)
            }

        return sort ? pairs.sorted { $0.name < $1.name } : pairs
    }

    /// Extracts a path from a key name with bracket notation.
    ///
    /// Converts bracket notation like `user[address][city]` into path components
    /// `["user", "address", "city"]`.
    ///
    /// - Parameter name: The form field name with optional bracket notation
    /// - Returns: Array of path components
    private static func extractPath(from name: String) -> [String] {
        let result = name.reduce(into: (path: [] as [String], current: "")) { result, char in
            switch char {
            case "[":
                if result.path.isEmpty {
                    result.path.append(result.current)
                    result.current.removeAll()
                }
            case "]":
                result.path.append(result.current)
                result.current.removeAll()
            default:
                result.current.append(char)
            }
        }

        return result.current.isEmpty ? result.path : result.path + [result.current]
    }

    /// Inserts a value at a given path into a FormData structure.
    ///
    /// Handles nested dictionaries and arrays, creating intermediate structures
    /// as needed.
    ///
    /// - Parameters:
    ///   - value: The string value to insert
    ///   - path: Array of path components indicating where to insert
    ///   - formData: The FormData structure to modify (in/out parameter)
    ///   - isArray: Function to determine if a path segment represents an array
    private static func insert(
        value: String,
        at path: [String],
        into formData: inout FormData,
        isArray: @escaping (String) -> Bool
    ) {
        guard !path.isEmpty else {
            formData = .value(value)
            return
        }

        switch formData {
        case .dictionary(var params):
            let key = path[0]

            if path.count == 1 {
                // Leaf value
                params[key] = .value(value)
            } else if path.count == 2, isArray(path[1]) {
                // Direct array: key[]
                var values = params[key]?.arrayValue ?? []
                values.append(.value(value))
                params[key] = .array(values)
            } else if isArray(path[1]) {
                // Array handling
                if path[1].isEmpty {
                    // Empty brackets - accumulate values
                    var values = params[key]?.arrayValue ?? []

                    if path.count > 2 {
                        // Create nested structure
                        var newElement = FormData.dictionary([:])
                        insert(
                            value: value,
                            at: Array(path[2...]),
                            into: &newElement,
                            isArray: isArray
                        )
                        values.append(newElement)
                    } else {
                        values.append(.value(value))
                    }

                    params[key] = .array(values)
                } else {
                    // Indexed arrays: key[0]
                    let index = Int(path[1]) ?? 0
                    var values = params[key]?.arrayValue ?? []

                    // Expand array if needed
                    while values.count <= index {
                        values.append(.dictionary([:]))
                    }

                    // Recurse into the specific index
                    if path.count > 2 {
                        insert(
                            value: value,
                            at: Array(path[2...]),
                            into: &values[index],
                            isArray: isArray
                        )
                    } else {
                        values[index] = .value(value)
                    }

                    params[key] = .array(values)
                }
            } else {
                // Nested object
                var nested = params[key] ?? .dictionary([:])
                insert(value: value, at: Array(path[1...]), into: &nested, isArray: isArray)
                params[key] = nested
            }

            formData = .dictionary(params)

        case .array(var values):
            if path.count == 1 {
                values.append(.value(value))
            } else if isArray(path[1]) {
                let index = Int(path[1]) ?? 0

                // Expand array if needed
                while values.count <= index {
                    values.append(.dictionary([:]))
                }

                // Recursively insert
                insert(value: value, at: Array(path[2...]), into: &values[index], isArray: isArray)
            } else {
                var nested = FormData.dictionary([:])
                insert(value: value, at: Array(path[1...]), into: &nested, isArray: isArray)
                values.append(nested)
            }

            formData = .array(values)

        case .value:
            // Cannot insert into a value - this shouldn't happen in valid form data
            break
        }
    }
}
