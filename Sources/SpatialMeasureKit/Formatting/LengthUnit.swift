/// The unit of a formatted length. One `UnitSystem` can give more than one, depending on size.
public enum LengthUnit: String, Sendable, CaseIterable, DisplayUnit {
    case meters
    case centimeters
    /// Feet and inches in one value, like `11' 3⅞"`. The value carries its own marks, so the
    /// symbol is empty.
    case feetAndInches

    public var symbol: String {
        switch self {
        case .meters: "m"
        case .centimeters: "cm"
        case .feetAndInches: ""
        }
    }

    public var separator: String {
        switch self {
        case .meters, .centimeters: " "
        case .feetAndInches: ""
        }
    }
}
