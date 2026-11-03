import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("AreaUnit")
struct AreaUnitTests {
    @Test("Exposes lowercase symbols, leaving casing to the caller")
    func symbols() {
        #expect(AreaUnit.squareMeters.symbol == "m²")
        #expect(AreaUnit.squareFeet.symbol == "ft²")
    }
}
