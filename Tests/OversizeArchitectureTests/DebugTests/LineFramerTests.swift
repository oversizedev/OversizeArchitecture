//
// Copyright © 2026 Alexander Romanov
// LineFramerTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitectureDebug
import Testing

struct LineFramerTests {
    @Test("Splits several messages in one chunk")
    func splitsSeveralMessages() throws {
        var framer = LineFramer()

        let lines = try framer.append(Data("{\"a\":1}\n{\"b\":2}\n".utf8))

        #expect(lines.map { String(decoding: $0, as: UTF8.self) } == [#"{"a":1}"#, #"{"b":2}"#])
        #expect(!framer.hasIncompleteLine)
    }

    @Test("Joins a message split across chunks")
    func joinsSplitMessage() throws {
        var framer = LineFramer()

        let first = try framer.append(Data("{\"a\":".utf8))
        let second = try framer.append(Data("1}\r\n{\"b\"".utf8))

        #expect(first.isEmpty)
        #expect(second.map { String(decoding: $0, as: UTF8.self) } == [#"{"a":1}"#])
        #expect(framer.hasIncompleteLine)
    }

    @Test("Skips empty lines")
    func skipsEmptyLines() throws {
        var framer = LineFramer()

        let lines = try framer.append(Data("\n\r\n{}\n".utf8))

        #expect(lines == [Data("{}".utf8)])
    }

    @Test("Rejects messages over the limit")
    func rejectsLongMessages() {
        var framer = LineFramer(maximumLineLength: 4)

        #expect(throws: LineFramer.FramingError.lineTooLong(limit: 4)) {
            _ = try framer.append(Data("12345".utf8))
        }
    }
}
