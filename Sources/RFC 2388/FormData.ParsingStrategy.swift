//
//  FormData.ParsingStrategy.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//

import Foundation

extension FormData {
    /// Strategies for parsing array notation in form data keys.
    ///
    /// RFC 2388 defines the basic structure of form data but does not specify
    /// conventions for representing arrays. This enum captures common conventions
    /// used in practice for encoding arrays in form data.
    ///
    /// ## Array Notation Conventions
    ///
    /// Different web frameworks use different conventions for representing arrays:
    ///
    /// ### Brackets
    /// Uses empty bracket notation to indicate array values:
    /// ```
    /// tags[]=swift&tags[]=vapor
    /// ```
    /// Results in: `["tags": ["swift", "vapor"]]`
    ///
    /// ### Brackets with Indices
    /// Uses indexed bracket notation for explicit ordering:
    /// ```
    /// items[0]=first&items[1]=second
    /// ```
    /// Results in: `["items": ["first", "second"]]`
    ///
    /// ### Accumulate Values
    /// Repeats the same key for multiple values:
    /// ```
    /// color=red&color=blue
    /// ```
    /// Results in: `["color": ["red", "blue"]]`
    ///
    /// ## Nested Objects
    ///
    /// All strategies support nested object notation using brackets:
    /// ```
    /// user[name]=John&user[email]=john@example.com
    /// ```
    /// Results in: `["user": ["name": "John", "email": "john@example.com"]]`
    public enum ParsingStrategy: Sendable, Equatable {
        /// Parse arrays using empty bracket notation (`tags[]`)
        case brackets

        /// Parse arrays using indexed bracket notation (`items[0]`)
        case bracketsWithIndices

        /// Parse repeated keys as array values (`key=val1&key=val2`)
        case accumulateValues
    }
}
