import Foundation
import Testing
@testable import ArgiMoney

@Suite("Import Log Builder Tests")
struct ImportLogBuilderTests {
  func testCounts_whenMixOfWarningsAndErrors_calculatesCorrectly() {
    let lines = [
      makeLine(.warning, "first warning"),
      makeLine(.error, "first error"),
      makeLine(.warning, "second warning"),
      makeLine(.error, "second error"),
      makeLine(.error, "third error")
    ]
    let summary = ImportLogSummary(lines: lines)

    #expect(summary.warningCount == 2)
    #expect(summary.errorCount == 3) // This test will fail because errorCount is currently counting warnings incorrectly
  }

  func testLogFormatting_joinsWithUppercasedLevelAndBrackets() {
    let lines = [
      makeLine(.error, "line"),
      makeLine(.warning, "line2")
    ]
    let summary = ImportLogSummary(lines: lines)

    let expectedLog = "[ERROR] - line\n[WARNING] - line2"
    #expect(summary.log == expectedLog)
  }

  func testBuilder_addAndAddContentsOf_aggregatesLinesInOrder() {
    var builder = DefaultImportLogBuilder()
    let firstLines = [
      makeLine(.warning, "warn1"),
      makeLine(.error, "error1")
    ]
    let secondLines = [
      makeLine(.error, "error2"),
      makeLine(.warning, "warn2")
    ]

    builder.add(contentsOf: firstLines)
    builder.add(contentsOf: secondLines)

    let summary = builder.summary()

    #expect(summary.lines.count == 4)
    #expect(summary.lines[0].type == .warning)
    #expect(summary.lines[1].type == .error)
    #expect(summary.lines[2].type == .error)
    #expect(summary.lines[3].type == .warning)
    #expect(summary.warningCount == 2)
    #expect(summary.errorCount == 2)
  }

  func testEmptySummary_whenNoLines_returnsZeroCountsAndEmptyLog() {
    let builder = DefaultImportLogBuilder()
    let summary = builder.summary()

    #expect(summary.warningCount == 0)
    #expect(summary.errorCount == 0)
    #expect(summary.log == "")
  }

  // MARK: - Helpers

  private func makeLine(_ type: ImportLogLineType, _ text: String) -> ImportLogLine {
    ImportLogLine(type: type, line: text)
  }
}
