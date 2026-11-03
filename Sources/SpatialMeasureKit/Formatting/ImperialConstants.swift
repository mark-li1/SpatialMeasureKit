/// Exact conversion factors for imperial units.
enum ImperialConstants {
    /// Exact by definition since 1959.
    static let metersPerInch = 0.0254
    static let inchesPerFoot = 12
    static let metersPerFoot = metersPerInch * Double(inchesPerFoot)
    static let squareMetersPerSquareFoot = metersPerFoot * metersPerFoot
}
