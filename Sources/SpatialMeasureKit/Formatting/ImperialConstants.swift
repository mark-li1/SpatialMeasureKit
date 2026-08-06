/// Physical conversion constants shared by every imperial calculation.
///
/// Kept separate from `ImperialLength`'s eighth-inch rounding precision and fraction glyphs —
/// those are display choices, not physical facts, and don't belong in the same place as them.
enum ImperialConstants {
    /// Exact by definition — the inch has been fixed at this value since 1959.
    static let metersPerInch = 0.0254
    static let inchesPerFoot = 12
    static let metersPerFoot = metersPerInch * Double(inchesPerFoot)
    static let squareMetersPerSquareFoot = metersPerFoot * metersPerFoot
}
