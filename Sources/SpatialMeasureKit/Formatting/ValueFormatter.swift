import Foundation

/// Turns lengths, areas and angles into text for the user's language and unit system.
///
/// Ties round away from zero, so 1.125 m shows as `1.13 m`, and a value that rounds to zero never
/// shows a minus sign.
public struct ValueFormatter: Sendable {
    private let locale: Locale

    /// Creates a formatter. `locale` decides the decimal separator, digit grouping and digits.
    public init(locale: Locale = .current) {
        self.locale = locale
    }

    /// Formats a length in meters for `system`.
    ///
    /// Metric shows centimeters below one meter: `45 cm`, not `0.45 m`. Imperial shows feet and
    /// inches to the nearest eighth, like `11' 3⅞"`, and ignores `fractionDigits`, which must not
    /// be negative.
    ///
    /// Returns `nil` for a negative or non-finite length, or one too large to count in inches.
    public func formatLength(meters: Float, system: UnitSystem, fractionDigits: Int = 2) -> FormattedLength? {
        precondition(fractionDigits >= 0, "fractionDigits must not be negative, got \(fractionDigits)")
        guard meters.isFinite, meters >= 0 else { return nil }

        switch system {
        case .metric:
            return metricLength(meters: Double(meters), fractionDigits: fractionDigits)
        case .imperial:
            return imperialLength(meters: Double(meters))
        }
    }

    private func metricLength(meters: Double, fractionDigits: Int) -> FormattedLength {
        // Round before picking the unit, or 0.999 m formats as "100 cm" instead of carrying to "1 m".
        let centimeters = (meters * 100).rounded()
        guard centimeters < 100 else {
            return FormattedValue(value: number(meters, fractionDigits: fractionDigits), unit: .meters)
        }
        return FormattedValue(value: number(centimeters, fractionDigits: 0), unit: .centimeters)
    }

    private func imperialLength(meters: Double) -> FormattedLength? {
        guard let length = ImperialLength(meters: meters) else { return nil }

        // A zero component is left unsaid: `12'`, not `12' 0"`; `8¼"`, not `0' 8¼"`.
        let inchPart = (length.inches > 0 ? number(Double(length.inches), fractionDigits: 0) : "") + length.fractionGlyph
        let feetPart = number(Double(length.feet), fractionDigits: 0)

        let value = switch (length.feet > 0, inchPart.isEmpty) {
        case (true, false): "\(feetPart)' \(inchPart)\""
        case (true, true): "\(feetPart)'"
        case (false, false): "\(inchPart)\""
        case (false, true): "\(number(0, fractionDigits: 0))\""
        }
        return FormattedValue(value: value, unit: .feetAndInches)
    }

    /// Formats an area in square meters for `system`, as square meters or square feet.
    ///
    /// `fractionDigits` applies to both systems and must not be negative. Returns `nil` for a
    /// negative or non-finite area.
    public func formatArea(squareMeters: Float, system: UnitSystem, fractionDigits: Int = 2) -> FormattedArea? {
        precondition(fractionDigits >= 0, "fractionDigits must not be negative, got \(fractionDigits)")
        guard squareMeters.isFinite, squareMeters >= 0 else { return nil }

        switch system {
        case .metric:
            return FormattedValue(
                value: number(Double(squareMeters), fractionDigits: fractionDigits),
                unit: .squareMeters
            )
        case .imperial:
            let squareFeet = Double(squareMeters) / ImperialConstants.squareMetersPerSquareFoot
            return FormattedValue(value: number(squareFeet, fractionDigits: fractionDigits), unit: .squareFeet)
        }
    }

    /// Formats an angle in degrees, like `37°`.
    ///
    /// `fractionDigits` must not be negative. Returns `nil` for NaN or infinity.
    public func formatAngle(degrees: Float, fractionDigits: Int = 0) -> FormattedAngle? {
        precondition(fractionDigits >= 0, "fractionDigits must not be negative, got \(fractionDigits)")
        guard degrees.isFinite else { return nil }

        let scale = pow(10, Double(fractionDigits))
        let rounded = (Double(degrees) * scale).rounded() / scale
        return FormattedValue(value: number(rounded, fractionDigits: fractionDigits), unit: .degrees)
    }

    private func number(_ value: Double, fractionDigits: Int) -> String {
        (value == 0 ? 0 : value).formatted(
            .number
                .precision(.fractionLength(fractionDigits))
                .rounded(rule: .toNearestOrAwayFromZero)
                .locale(locale)
        )
    }
}
