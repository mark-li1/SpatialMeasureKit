/// The unit a formatted length is expressed in.
///
/// This is the *result* of formatting, not a user preference — a single `UnitSystem` can yield
/// more than one of these depending on magnitude.
public enum LengthUnit: String, Sendable, CaseIterable, DisplayUnit {
    case meters
    case centimeters
    /// A combined feet-and-inches string such as `11' 3⅞"`, which carries its own symbols.
    case feetAndInches

    /// The standard symbol for the unit, or an empty string when the formatted value already
    /// includes its own symbols.
    ///
    /// Symbols are given in their conventional lowercase form and are not localized — SI symbols
    /// are identical across locales. Callers that display them uppercased should do so themselves.
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
