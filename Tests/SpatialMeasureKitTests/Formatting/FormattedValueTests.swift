import Testing
import Foundation
import SpatialMeasureKit

@Suite("FormattedValue")
struct FormattedValueTests {
    private let formatter = ValueFormatter(locale: Locale(identifier: "en_US"))

    @Test("Metric values and their unit are joined with a space")
    func metricTextHasSpace() throws {
        let meters = try #require(formatter.formatLength(meters: 3.5, system: .metric))
        let centimeters = try #require(formatter.formatLength(meters: 0.45, system: .metric))
        let area = try #require(formatter.formatArea(squareMeters: 3.45, system: .metric))

        #expect(meters.text == "3.50 m")
        #expect(centimeters.text == "45 cm")
        #expect(area.text == "3.45 m²")
    }

    @Test("Feet and inches carry their own marks, with no trailing space")
    func feetAndInchesTextHasNoTrailingSpace() throws {
        let feetAndInches = try #require(formatter.formatLength(meters: 3.45, system: .imperial))
        let feetOnly = try #require(formatter.formatLength(meters: 3.048, system: .imperial))

        #expect(feetAndInches.text == "11' 3⅞\"")
        #expect(feetOnly.text == "10'")
    }

    @Test("Square feet are joined with a space, degrees with none")
    func squareFeetAndDegreesText() throws {
        let squareFeet = try #require(formatter.formatArea(squareMeters: 1, system: .imperial))
        let degrees = try #require(formatter.formatAngle(degrees: 37))

        #expect(squareFeet.text == "10.76 ft²")
        #expect(degrees.text == "37°")
    }
}
