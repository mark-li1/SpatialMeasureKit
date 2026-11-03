import Testing
import simd
import Foundation
@testable import SpatialMeasureKit

@Suite("ValueFormatter")
struct ValueFormatterTests {
    /// Pinned so the decimal separator and grouping don't shift with the host machine's region.
    private let sut = ValueFormatter(locale: Locale(identifier: "en_US"))

    @Test("Formats a whole number of meters with two fraction digits")
    func metricWholeMeters() {
        #expect(sut.formatLength(meters: 3, system: .metric) == FormattedValue(value: "3.00", unit: .meters))
    }

    @Test("Formats a fractional length in meters")
    func metricFractionalMeters() {
        #expect(sut.formatLength(meters: 3.45, system: .metric) == FormattedValue(value: "3.45", unit: .meters))
    }

    @Test("Switches to whole centimeters below one meter")
    func metricSwitchesToCentimeters() {
        #expect(sut.formatLength(meters: 0.45, system: .metric) == FormattedValue(value: "45", unit: .centimeters))
    }

    @Test("Rounds centimeters to whole numbers")
    func metricRoundsCentimeters() {
        #expect(sut.formatLength(meters: 0.994, system: .metric) == FormattedValue(value: "99", unit: .centimeters))
    }

    @Test("Exactly one meter stays in meters")
    func metricOneMeterBoundary() {
        #expect(sut.formatLength(meters: 1, system: .metric) == FormattedValue(value: "1.00", unit: .meters))
    }

    @Test("Centimeters rounding up to 100 carry into meters instead of showing '100 CM'")
    func metricCentimeterCarry() {
        #expect(sut.formatLength(meters: 0.999, system: .metric) == FormattedValue(value: "1.00", unit: .meters))
    }

    @Test("Formats zero as centimeters")
    func metricZero() {
        #expect(sut.formatLength(meters: 0, system: .metric) == FormattedValue(value: "0", unit: .centimeters))
    }

    @Test("Honors a custom fraction-digit count")
    func metricCustomFractionDigits() {
        let result = sut.formatLength(meters: 3.456, system: .metric, fractionDigits: 1)

        #expect(result == FormattedValue(value: "3.5", unit: .meters))
    }

    @Test("Uses the locale's decimal separator")
    func metricLocalizedSeparator() {
        let german = ValueFormatter(locale: Locale(identifier: "de_DE"))

        #expect(german.formatLength(meters: 3.45, system: .metric) == FormattedValue(value: "3,45", unit: .meters))
    }

    @Test("Returns nil for a negative length")
    func rejectsNegative() {
        #expect(sut.formatLength(meters: -1, system: .metric) == nil)
    }

    @Test("Returns nil for NaN")
    func rejectsNaN() {
        #expect(sut.formatLength(meters: .nan, system: .metric) == nil)
    }

    @Test("Returns nil for infinity")
    func rejectsInfinity() {
        #expect(sut.formatLength(meters: .infinity, system: .metric) == nil)
    }

    // MARK: - Imperial

    @Test("Formats feet with whole inches and a fraction")
    func imperialFeetInchesAndFraction() {
        #expect(sut.formatLength(meters: 3.45, system: .imperial)
                == FormattedValue(value: "11' 3⅞\"", unit: .feetAndInches))
    }

    @Test("Omits a zero inch component: 10 feet reads '10\\'', not \"10' 0\\\"\"")
    func imperialExactFeetOmitsInches() {
        #expect(sut.formatLength(meters: 3.048, system: .imperial)
                == FormattedValue(value: "10'", unit: .feetAndInches))
    }

    @Test("Omits a zero foot component: below a foot reads '8¼\"', not \"0' 8¼\\\"\"")
    func imperialSubFootOmitsFeet() {
        #expect(sut.formatLength(meters: 0.21, system: .imperial)
                == FormattedValue(value: "8¼\"", unit: .feetAndInches))
    }

    @Test("Inches rounding up to twelve carry into feet instead of showing \"11' 12\\\"\"")
    func imperialInchCarry() {
        #expect(sut.formatLength(meters: 3.65759, system: .imperial)
                == FormattedValue(value: "12'", unit: .feetAndInches))
    }

    @Test("Omits zero whole inches but keeps the fraction")
    func imperialFractionWithoutWholeInches() {
        #expect(sut.formatLength(meters: 0.307975, system: .imperial)
                == FormattedValue(value: "1' ⅛\"", unit: .feetAndInches))
    }

    @Test("Formats zero as inches")
    func imperialZero() {
        #expect(sut.formatLength(meters: 0, system: .imperial)
                == FormattedValue(value: "0\"", unit: .feetAndInches))
    }

    @Test("Rounds to the nearest eighth from both sides")
    func imperialRoundsToNearestEighth() {
        // Deliberately off the midpoint: exactly 1/16" is a tie, and which way a tie falls depends
        // on Float's representation of it rather than on the rounding rule under test.
        #expect(sut.formatLength(meters: 0.0254 * 0.1, system: .imperial)   // 0.8 eighths
                == FormattedValue(value: "⅛\"", unit: .feetAndInches))
        #expect(sut.formatLength(meters: 0.0254 * 0.05, system: .imperial)  // 0.4 eighths
                == FormattedValue(value: "0\"", unit: .feetAndInches))
    }

    @Test("Imperial lengths use the locale's digits for feet, inches and zero")
    func imperialLocalizedDigits() {
        let arabic = ValueFormatter(locale: Locale(identifier: "ar_SA"))

        #expect(arabic.formatLength(meters: 3.45, system: .imperial)
                == FormattedValue(value: "١١' ٣⅞\"", unit: .feetAndInches))
        #expect(arabic.formatLength(meters: 0, system: .imperial)
                == FormattedValue(value: "٠\"", unit: .feetAndInches))
    }

    @Test("fractionDigits does not affect imperial output")
    func imperialIgnoresFractionDigits() {
        let coarse = sut.formatLength(meters: 3.45, system: .imperial, fractionDigits: 0)
        let fine = sut.formatLength(meters: 3.45, system: .imperial, fractionDigits: 5)

        #expect(coarse == fine)
    }

    @Test("Returns nil rather than trapping for a length too large to count in eighths")
    func imperialRejectsUncountableLength() {
        #expect(sut.formatLength(meters: 1e30, system: .imperial) == nil)
    }

    // MARK: - Area

    @Test("Formats a metric area with two fraction digits")
    func areaMetric() {
        #expect(sut.formatArea(squareMeters: 3.45, system: .metric)
                == FormattedValue(value: "3.45", unit: .squareMeters))
    }

    @Test("Converts one square meter to square feet")
    func areaOneSquareMeterInSquareFeet() {
        #expect(sut.formatArea(squareMeters: 1, system: .imperial)
                == FormattedValue(value: "10.76", unit: .squareFeet))
    }

    @Test("Converts a worked example to square feet")
    func areaWorkedExample() {
        #expect(sut.formatArea(squareMeters: 12.3, system: .imperial)
                == FormattedValue(value: "132.40", unit: .squareFeet))
    }

    @Test("Formats zero area")
    func areaZero() {
        #expect(sut.formatArea(squareMeters: 0, system: .metric)
                == FormattedValue(value: "0.00", unit: .squareMeters))
    }

    @Test("Returns nil for a negative area")
    func areaRejectsNegative() {
        #expect(sut.formatArea(squareMeters: -1, system: .metric) == nil)
    }

    @Test("Returns nil for NaN area")
    func areaRejectsNaN() {
        #expect(sut.formatArea(squareMeters: .nan, system: .metric) == nil)
    }

    @Test("Returns nil for infinite area")
    func areaRejectsInfinity() {
        #expect(sut.formatArea(squareMeters: .infinity, system: .imperial) == nil)
    }

    @Test("Unlike imperial length, fractionDigits is honored for imperial area")
    func areaImperialHonorsFractionDigits() {
        let coarse = sut.formatArea(squareMeters: 12.3, system: .imperial, fractionDigits: 0)
        let fine = sut.formatArea(squareMeters: 12.3, system: .imperial, fractionDigits: 4)

        #expect(coarse == FormattedValue(value: "132", unit: .squareFeet))
        #expect(fine == FormattedValue(value: "132.3961", unit: .squareFeet))
    }

    @Test("Uses the locale's decimal separator for area")
    func areaLocalizedSeparator() {
        let german = ValueFormatter(locale: Locale(identifier: "de_DE"))

        #expect(german.formatArea(squareMeters: 3.45, system: .metric)
                == FormattedValue(value: "3,45", unit: .squareMeters))
    }

    @Test("Imperial area is always decimal — never a feet-and-inches-style combination")
    func areaImperialHasNoLengthPunctuation() throws {
        let result = try #require(sut.formatArea(squareMeters: 12.3, system: .imperial))

        #expect(!result.value.contains("'"))
        #expect(!result.value.contains("\""))
    }

    // MARK: - Angle

    @Test("Rounds degrees half away from zero", arguments: [
        (Float(36.5), "37"),
        (0.5, "1"),
        (-0.5, "-1"),
    ])
    func angleRoundsHalfAwayFromZero(degrees: Float, expected: String) {
        #expect(sut.formatAngle(degrees: degrees) == FormattedValue(value: expected, unit: .degrees))
    }

    @Test("A small negative angle reads 0°, never -0°")
    func angleNeverPrintsNegativeZero() {
        #expect(sut.formatAngle(degrees: -0.3) == FormattedValue(value: "0", unit: .degrees))
        #expect(sut.formatAngle(degrees: -0.004, fractionDigits: 2) == FormattedValue(value: "0.00", unit: .degrees))
    }

    @Test("Honors a custom fraction-digit count for angles")
    func angleCustomFractionDigits() {
        #expect(sut.formatAngle(degrees: 12.125, fractionDigits: 2) == FormattedValue(value: "12.13", unit: .degrees))
    }

    @Test("Returns nil for a NaN or infinite angle")
    func angleRejectsNonFinite() {
        #expect(sut.formatAngle(degrees: .nan) == nil)
        #expect(sut.formatAngle(degrees: .infinity) == nil)
    }

    // MARK: - Rounding and negative zero

    @Test("Rounds a tie away from zero: 1.125 m reads 1.13 m, not 1.12 m")
    func metricRoundsTieAwayFromZero() {
        #expect(sut.formatLength(meters: 1.125, system: .metric) == FormattedValue(value: "1.13", unit: .meters))
    }

    @Test("Rounds a tie away from zero with no fraction digits: 2.5 m reads 3 m, not 2 m")
    func metricRoundsTieAwayFromZeroWithoutFraction() {
        let result = sut.formatLength(meters: 2.5, system: .metric, fractionDigits: 0)

        #expect(result == FormattedValue(value: "3", unit: .meters))
    }

    @Test("Rounds an area tie away from zero: 0.125 m² reads 0.13 m², not 0.12 m²")
    func areaRoundsTieAwayFromZero() {
        #expect(sut.formatArea(squareMeters: 0.125, system: .metric)
                == FormattedValue(value: "0.13", unit: .squareMeters))
    }

    @Test("Lengths, areas and angles round the same tie the same way")
    func tiesRoundAlikeForEveryKind() throws {
        let length = try #require(sut.formatLength(meters: 1.125, system: .metric))
        let area = try #require(sut.formatArea(squareMeters: 1.125, system: .metric))
        let angle = try #require(sut.formatAngle(degrees: 1.125, fractionDigits: 2))

        #expect(length.value == "1.13")
        #expect(area.value == "1.13")
        #expect(angle.value == "1.13")
    }

    @Test("Negative zero length reads 0 cm, not -0 cm")
    func metricNegativeZero() {
        #expect(sut.formatLength(meters: -0.0, system: .metric) == FormattedValue(value: "0", unit: .centimeters))
    }

    @Test("Negative zero area reads 0.00, not -0.00, in both unit systems")
    func areaNegativeZero() {
        #expect(sut.formatArea(squareMeters: -0.0, system: .metric)
                == FormattedValue(value: "0.00", unit: .squareMeters))
        #expect(sut.formatArea(squareMeters: -0.0, system: .imperial)
                == FormattedValue(value: "0.00", unit: .squareFeet))
    }

    #if compiler(>=6.2) && os(macOS)
    @Test("Stops with its own message on a negative fractionDigits for every kind of value")
    func negativeFractionDigitsStop() async throws {
        let length = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = ValueFormatter().formatLength(meters: 1, system: .metric, fractionDigits: -1)
        }
        let area = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = ValueFormatter().formatArea(squareMeters: 1, system: .metric, fractionDigits: -1)
        }
        let angle = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = ValueFormatter().formatAngle(degrees: 1, fractionDigits: -1)
        }

        #if DEBUG
        for result in [length, area, angle] {
            let message = String(decoding: try #require(result).standardErrorContent, as: UTF8.self)
            #expect(message.contains("fractionDigits must not be negative"))
        }
        #endif
    }
    #endif
}
