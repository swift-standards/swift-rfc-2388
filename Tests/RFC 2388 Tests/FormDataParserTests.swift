//
//  FormDataParserTests.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//

import Testing

@testable import RFC_2388

@Suite
struct `FormData Parser Tests` {

    @Test
    func `Parse simple key-value pairs`() {
        let result = FormData.parse("name=John&age=30")

        guard case .dictionary(let dict) = result else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["name"]?.stringValue == "John")
        #expect(dict["age"]?.stringValue == "30")
    }

    @Test
    func `Parse arrays with brackets strategy`() {
        let result = FormData.parse("tags[]=swift&tags[]=vapor", strategy: .brackets)

        guard case .dictionary(let dict) = result,
            case .array(let tags) = dict["tags"]
        else {
            Issue.record("Expected dictionary with array")
            return
        }

        #expect(tags.count == 2)
        #expect(tags[0].stringValue == "swift")
        #expect(tags[1].stringValue == "vapor")
    }

    @Test
    func `Parse arrays with indices`() {
        let result = FormData.parse(
            "items[0]=first&items[1]=second",
            strategy: .bracketsWithIndices
        )

        guard case .dictionary(let dict) = result,
            case .array(let items) = dict["items"]
        else {
            Issue.record("Expected dictionary with array")
            return
        }

        #expect(items.count == 2)
        #expect(items[0].stringValue == "first")
        #expect(items[1].stringValue == "second")
    }

    @Test
    func `Parse with accumulate values strategy`() {
        let result = FormData.parse("color=red&color=blue", strategy: .accumulateValues)

        guard case .dictionary(let dict) = result,
            case .array(let colors) = dict["color"]
        else {
            Issue.record("Expected dictionary with array")
            return
        }

        #expect(colors.count == 2)
        #expect(colors[0].stringValue == "red")
        #expect(colors[1].stringValue == "blue")
    }

    @Test
    func `Parse nested objects`() {
        let result = FormData.parse("user[name]=John&user[email]=john@example.com")

        guard case .dictionary(let dict) = result,
            case .dictionary(let user) = dict["user"]
        else {
            Issue.record("Expected nested dictionary")
            return
        }

        #expect(user["name"]?.stringValue == "John")
        #expect(user["email"]?.stringValue == "john@example.com")
    }

    @Test
    func `Extract pairs from query string`() {
        let pairs = FormData.extractPairs(from: "name=John&age=30")

        #expect(pairs.count == 2)
        #expect(pairs[0].0 == "name")
        #expect(pairs[0].1 == "John")
        #expect(pairs[1].0 == "age")
        #expect(pairs[1].1 == "30")
    }

    @Test
    func `Handle percent-encoded values`() {
        let result = FormData.parse("name=John+Doe&message=Hello%20World")

        guard case .dictionary(let dict) = result else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["name"]?.stringValue == "John Doe")
        #expect(dict["message"]?.stringValue == "Hello World")
    }
}
