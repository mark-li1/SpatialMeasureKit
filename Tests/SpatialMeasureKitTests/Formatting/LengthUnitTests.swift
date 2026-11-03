import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("LengthUnit")
struct LengthUnitTests {
    @Test("Exposes lowercase SI symbols, leaving casing to the caller")
    func siSymbols() {
        #expect(LengthUnit.meters.symbol == "m")
        #expect(LengthUnit.centimeters.symbol == "cm")
    }

    @Test("Feet-and-inches has no separate symbol because the value carries its own")
    func selfDescribingUnitHasNoSymbol() {
        #expect(LengthUnit.feetAndInches.symbol.isEmpty)
    }
}
