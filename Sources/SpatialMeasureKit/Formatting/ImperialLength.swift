/// A length split into feet, whole inches and eighths of an inch.
///
/// It rounds once, to a whole number of eighths, before splitting, so `11' 12"` can't happen.
struct ImperialLength: Equatable {
    let feet: Int
    /// Whole inches left after the feet, `0..<12`.
    let inches: Int
    /// Eighths of an inch left after the whole inches, `0..<8`.
    let eighths: Int

    private static let eighthsPerInch = 8
    private static let eighthsPerFoot = eighthsPerInch * ImperialConstants.inchesPerFoot

    /// Eighths in lowest terms, so 2/8 shows as ¼.
    private static let fractionGlyphs = ["", "⅛", "¼", "⅜", "½", "⅝", "¾", "⅞"]

    /// Returns `nil` for a negative or non-finite length, or one too large to count in eighths.
    init?(meters: Double) {
        guard meters >= 0 else { return nil }

        let scaled = (meters / ImperialConstants.metersPerInch * Double(Self.eighthsPerInch)).rounded()
        // `Int(_:)` traps on out-of-range input; `Int(exactly:)` reports it instead.
        guard let totalEighths = Int(exactly: scaled) else { return nil }

        feet = totalEighths / Self.eighthsPerFoot
        inches = (totalEighths % Self.eighthsPerFoot) / Self.eighthsPerInch
        eighths = totalEighths % Self.eighthsPerInch
    }

    /// The fraction as one glyph, like `⅞`, or empty when there is none.
    var fractionGlyph: String {
        Self.fractionGlyphs[eighths]
    }
}
