/// A length decomposed into feet, whole inches, and eighths of an inch.
///
/// Rounding happens exactly once, into a single integer count of eighths, before the parts are
/// separated. A full twelve inches is therefore already a foot by the time `inches` is derived,
/// so the `11' 12"` carry is unreachable rather than corrected.
struct ImperialLength: Equatable {
    let feet: Int
    /// Whole inches left after the feet, `0..<12`.
    let inches: Int
    /// Eighths of an inch left after the whole inches, `0..<8`.
    let eighths: Int

    private static let eighthsPerInch = 8
    private static let eighthsPerFoot = eighthsPerInch * ImperialConstants.inchesPerFoot

    /// Eighths in lowest terms. The denominator is fixed, so reduction is a lookup rather than
    /// a gcd — `2/8` is `¼` because the table says so.
    private static let fractionGlyphs = ["", "⅛", "¼", "⅜", "½", "⅝", "¾", "⅞"]

    /// - Parameter meters: must be non-negative and finite.
    /// - Returns: `nil` if `meters` is negative, not finite, or too large to count in eighths
    ///   of an inch without overflowing `Int`.
    init?(meters: Double) {
        guard meters >= 0 else { return nil }

        let scaled = (meters / ImperialConstants.metersPerInch * Double(Self.eighthsPerInch)).rounded()
        // `Int(_:)` traps on out-of-range input; `Int(exactly:)` reports it instead.
        guard let totalEighths = Int(exactly: scaled) else { return nil }

        feet = totalEighths / Self.eighthsPerFoot
        inches = (totalEighths % Self.eighthsPerFoot) / Self.eighthsPerInch
        eighths = totalEighths % Self.eighthsPerInch
    }

    /// The fractional part as a single glyph, or an empty string when there is no fraction.
    var fractionGlyph: String {
        Self.fractionGlyphs[eighths]
    }
}
