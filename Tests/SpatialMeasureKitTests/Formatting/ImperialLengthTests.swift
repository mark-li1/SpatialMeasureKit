import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("ImperialLength")
struct ImperialLengthTests {
    @Test("Splits a length into feet, whole inches, and eighths")
    func decomposes() throws {
        let sut = try #require(ImperialLength(meters: 3.45))

        #expect(sut.feet == 11)
        #expect(sut.inches == 3)
        #expect(sut.eighths == 7)
    }

    @Test("A whole foot leaves no inch or eighth remainder")
    func exactFootHasNoRemainder() throws {
        let sut = try #require(ImperialLength(meters: 0.3048))

        #expect(sut == ImperialLength(meters: 0.3048))
        #expect(sut.feet == 1)
        #expect(sut.inches == 0)
        #expect(sut.eighths == 0)
    }

    @Test("Twelve inches never survives as an inch component")
    func twelveInchesBecomesAFoot() throws {
        let sut = try #require(ImperialLength(meters: 3.65759))

        #expect(sut.feet == 12)
        #expect(sut.inches == 0)
    }

    @Test("Reduces each eighth to its lowest-terms glyph")
    func fractionGlyphs() throws {
        let expected = ["", "⅛", "¼", "⅜", "½", "⅝", "¾", "⅞"]

        for eighth in 0..<8 {
            // One whole inch plus `eighth` eighths, so the whole-inch part is never empty.
            let meters = Double(8 + eighth) * 0.0254 / 8
            let sut = try #require(ImperialLength(meters: meters))

            #expect(sut.inches == 1)
            #expect(sut.eighths == eighth)
            #expect(sut.fractionGlyph == expected[eighth])
        }
    }

    @Test("Returns nil for a negative length")
    func rejectsNegative() {
        #expect(ImperialLength(meters: -1) == nil)
    }

    @Test("Returns nil for input too large to count in eighths of an inch")
    func rejectsUncountable() {
        #expect(ImperialLength(meters: 1e30) == nil)
    }

    @Test("Returns nil for non-finite input")
    func rejectsNonFinite() {
        #expect(ImperialLength(meters: .nan) == nil)
        #expect(ImperialLength(meters: .infinity) == nil)
    }
}
