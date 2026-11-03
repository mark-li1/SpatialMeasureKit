import Testing
import Foundation
import SpatialMeasureKit

@Suite("UnitSystem")
struct UnitSystemTests {
    @Test("Only the US measurement system is imperial; the UK and a user's own choice are respected", arguments: [
        ("en_US", UnitSystem.imperial),
        ("en_GB", .metric),
        ("de_DE", .metric),
        ("en_US@measure=metric", .metric),
        ("de_DE@measure=ussystem", .imperial),
    ])
    func unitSystemForLocale(identifier: String, expected: UnitSystem) {
        #expect(UnitSystem(locale: Locale(identifier: identifier)) == expected)
    }
}
