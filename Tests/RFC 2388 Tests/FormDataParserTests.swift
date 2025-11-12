//
//  FormDataParserTests.swift
//  swift-rfc-2388
//
//  RFC 2388: Returning Values from Forms: multipart/form-data
//

import Testing

@testable import RFC_2388

@Suite("FormData Parser Tests")
struct FormDataParserTests {

    @Test("Parse simple key-value pairs")
    func testSimpleValues() {
        let result = FormData.parse("name=John&age=30")

        guard case .dictionary(let dict) = result else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["name"]?.stringValue == "John")
        #expect(dict["age"]?.stringValue == "30")
    }

    @Test("Parse arrays with brackets strategy")
    func testBracketsStrategy() {
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

    @Test("Parse arrays with indices")
    func testBracketsWithIndicesStrategy() {
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

    @Test("Parse with accumulate values strategy")
    func testAccumulateValuesStrategy() {
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

    @Test("Parse nested objects")
    func testNestedObjects() {
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

    @Test("Extract pairs from query string")
    func testExtractPairs() {
        let pairs = FormData.extractPairs(from: "name=John&age=30")

        #expect(pairs.count == 2)
        #expect(pairs[0].0 == "name")
        #expect(pairs[0].1 == "John")
        #expect(pairs[1].0 == "age")
        #expect(pairs[1].1 == "30")
    }

    @Test("Handle percent-encoded values")
    func testPercentEncoding() {
        let result = FormData.parse("name=John+Doe&message=Hello%20World")

        guard case .dictionary(let dict) = result else {
            Issue.record("Expected dictionary")
            return
        }

        #expect(dict["name"]?.stringValue == "John Doe")
        #expect(dict["message"]?.stringValue == "Hello World")
    }
}
