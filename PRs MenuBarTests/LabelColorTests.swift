import SwiftUI
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct LabelColorTests {

    // MARK: - Helpers
    private func components(_ color: Color) -> (red: Double, green: Double, blue: Double) {
        let resolved = color.resolve(in: EnvironmentValues())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
    }

    private func expectComponents(
        _ color: Color,
        equal expected: (red: Double, green: Double, blue: Double),
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let actual = components(color)
        #expect(abs(actual.red - expected.red) < 0.01, sourceLocation: sourceLocation)
        #expect(abs(actual.green - expected.green) < 0.01, sourceLocation: sourceLocation)
        #expect(abs(actual.blue - expected.blue) < 0.01, sourceLocation: sourceLocation)
    }

    // MARK: - labelPair

    @Test func labelPairParsesEachByteIntoTheFill() throws {
        let pair = try #require(Color.labelPair(hex: "d73a4a"))
        expectComponents(pair.fill, equal: (215 / 255, 58 / 255, 74 / 255))
    }

    @Test func labelPairToleratesAHashUppercaseAndSurroundingWhitespace() throws {
        for variant in ["#a2eeef", "A2EEEF", "  #A2EEEF\n"] {
            let pair = try #require(Color.labelPair(hex: variant), "\(variant) should parse")
            expectComponents(pair.fill, equal: (162 / 255, 238 / 255, 239 / 255))
        }
    }

    @Test func labelPairPicksTheTextColorByLuminance() throws {
        let white = try #require(Color.labelPair(hex: "ffffff"))
        let lightCyan = try #require(Color.labelPair(hex: "a2eeef"))
        let black = try #require(Color.labelPair(hex: "000000"))
        let red = try #require(Color.labelPair(hex: "d73a4a"))

        #expect(white.text == .black)
        #expect(lightCyan.text == .black)
        #expect(black.text == .white)
        #expect(red.text == .white)
    }

    @Test func labelPairRejectsAnythingThatIsNotSixHexDigits() {
        #expect(Color.labelPair(hex: "") == nil)
        #expect(Color.labelPair(hex: "#") == nil)
        #expect(Color.labelPair(hex: "fff") == nil)
        #expect(Color.labelPair(hex: "d73a4aff") == nil)
        #expect(Color.labelPair(hex: "zzzzzz") == nil)
        #expect(Color.labelPair(hex: "+d73a4") == nil)
        #expect(Color.labelPair(hex: "-d73a4") == nil)
    }

    // MARK: - labelColorMap

    @Test func labelColorMapDropsLabelsWithoutAUsableColor() {
        let map = labelColorMap([
            (name: "bug", color: "d73a4a"),
            (name: "wontfix", color: nil),
            (name: "blank", color: "")
        ])

        #expect(map == ["bug": "d73a4a"])
    }

    @Test func labelColorMapKeepsTheFirstColorSeenForADuplicateName() {
        let map = labelColorMap([
            (name: "bug", color: "d73a4a"),
            (name: "bug", color: "000000")
        ])

        #expect(map == ["bug": "d73a4a"])
    }

    @Test func labelColorMapStripsGitLabsLeadingHash() {
        let map = labelColorMap([
            (name: "bug", color: "#d73a4a"),
            (name: "ui", color: "c5def5"),
            (name: "hash-only", color: "#")
        ])
        #expect(map == ["bug": "d73a4a", "ui": "c5def5"])
    }

    @Test func labelColorMapOfNoPairsIsEmpty() {
        #expect(labelColorMap([]).isEmpty)
    }
}
