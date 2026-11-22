//
// Copyright © 2026 Alexander Romanov
// LineFramer.swift, created on 22.11.2026
//

import Foundation

package struct LineFramer: Sendable {
    package enum FramingError: Error, Equatable {
        case lineTooLong(limit: Int)
    }

    package static let defaultMaximumLineLength = 1 << 20

    package let maximumLineLength: Int
    private var buffer = Data()

    package init(maximumLineLength: Int = defaultMaximumLineLength) {
        self.maximumLineLength = maximumLineLength
    }

    package var hasIncompleteLine: Bool {
        !buffer.isEmpty
    }

    package mutating func append(_ chunk: Data) throws -> [Data] {
        buffer.append(chunk)
        var lines: [Data] = []

        while let newline = buffer.firstIndex(of: 0x0A) {
            var line = Data(buffer[buffer.startIndex ..< newline])
            buffer = Data(buffer[buffer.index(after: newline)...])
            if line.last == 0x0D {
                line.removeLast()
            }
            guard line.count <= maximumLineLength else {
                throw FramingError.lineTooLong(limit: maximumLineLength)
            }
            if !line.isEmpty {
                lines.append(line)
            }
        }

        guard buffer.count <= maximumLineLength else {
            throw FramingError.lineTooLong(limit: maximumLineLength)
        }
        return lines
    }
}
