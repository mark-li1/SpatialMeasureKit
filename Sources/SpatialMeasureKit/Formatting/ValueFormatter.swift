import Foundation

/// Formats measurements expressed in meters into display-ready text.
public struct ValueFormatter: Sendable {
    private let locale: Locale

    /// - Parameter locale: drives the decimal separator and grouping of the formatted magnitude.
    public init(locale: Locale = .current) {
        self.locale = locale
    }

    /// Formats a length given in meters for display in `system`.
    ///
    /// Metric output falls back to centimeters below one meter, so short lengths read as
    /// `45 cm` rather than `0.45 m`. Imperial output combines feet and inches, rounded to the
    /// nearest eighth of an inch — `11' 3⅞"`.
    ///
    /// - Parameters:
    ///   - meters: the length to format. Must be finite and non-negative.
    ///   - system: the unit system to present the length in.
    ///   - fractionDigits: digits after the decimal separator. Applies to metric output only;
    ///     imperial precision is the eighth-inch it rounds to, not a count of decimal places.
    /// - Returns: the formatted length, or `nil` if `meters` is negative, not finite, or too
    ///   large to represent.
    public func formatLength(meters: Float, system: UnitSystem, fractionDigits: Int = 2) -> FormattedLength? {
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
        let inchPart = (length.inches > 0 ? "\(length.inches)" : "") + length.fractionGlyph
        let feetPart = number(Double(length.feet), fractionDigits: 0)

        let value = switch (length.feet > 0, inchPart.isEmpty) {
        case (true, false): "\(feetPart)' \(inchPart)\""
        case (true, true): "\(feetPart)'"
        case (false, false): "\(inchPart)\""
        case (false, true): "0\""
        }
        return FormattedValue(value: value, unit: .feetAndInches)
    }

    /// Formats an area given in square meters for display in `system`.
    ///
    /// Unlike `formatLength`, both branches are plain decimal — area is never expressed as a
    /// feet-and-inches-style combination, so `fractionDigits` applies to imperial output too.
    ///
    /// - Parameters:
    ///   - squareMeters: the area to format. Must be finite and non-negative.
    ///   - system: the unit system to present the area in.
    ///   - fractionDigits: digits after the decimal separator, for both unit systems.
    /// - Returns: the formatted area, or `nil` if `squareMeters` is negative or not finite.
    public func formatArea(squareMeters: Float, system: UnitSystem, fractionDigits: Int = 2) -> FormattedArea? {
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

    private func number(_ value: Double, fractionDigits: Int) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(fractionDigits))
                .locale(locale)
        )
    }
}
