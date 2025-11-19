//
//  FormData.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//


/// A container representing parsed form data according to RFC 2388.
///
/// This structure represents the hierarchical structure of form data,
/// supporting simple values, arrays, and nested objects.
///
/// ## RFC 2388 Compliance
///
/// RFC 2388 defines how HTML forms encode data for submission to HTTP servers.
/// This implementation supports various encoding conventions including:
/// - Simple key-value pairs: `name=value`
/// - Arrays with brackets: `tags[]=value1&tags[]=value2`
/// - Arrays with indices: `items[0]=value1&items[1]=value2`
/// - Nested objects: `user[name]=John&user[email]=john@example.com`
///
/// ## Example
///
/// ```swift
/// // Simple value
/// let simple = FormData.value("John")
///
/// // Array
/// let array = FormData.array(["tag1", "tag2"].map { .value($0) })
///
/// // Dictionary
/// let dict = FormData.dictionary([
///     "name": .value("John"),
///     "email": .value("john@example.com")
/// ])
/// ```
public indirect enum FormData: Sendable, Equatable {
    /// A simple string value
    case value(String)

    /// An array of form data values
    case array([FormData])

    /// A dictionary of form data values (nested object)
    case dictionary([String: FormData])
}

extension FormData {
    /// Returns the string value if this is a `.value` case
    public var stringValue: String? {
        if case .value(let str) = self {
            return str
        }
        return nil
    }

    /// Returns the array if this is an `.array` case
    public var arrayValue: [FormData]? {
        if case .array(let arr) = self {
            return arr
        }
        return nil
    }

    /// Returns the dictionary if this is a `.dictionary` case
    public var dictionaryValue: [String: FormData]? {
        if case .dictionary(let dict) = self {
            return dict
        }
        return nil
    }
}
