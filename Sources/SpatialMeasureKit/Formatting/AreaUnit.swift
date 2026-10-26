/// The unit a formatted area is expressed in.
///
/// Unlike `LengthUnit`, there is no self-describing compositional case — imperial area is always
/// decimal square feet, never a feet-and-inches-style combination. Square feet and square inches
/// aren't mixed in speech the way feet and inches are.
public enum AreaUnit: String, Sendable, CaseIterable, DisplayUnit {
    case squareMeters
    case squareFeet

    /// The standard symbol for the unit, in conventional lowercase form. Not localized — these
    /// symbols are identical across locales. Callers that display them uppercased do so themselves.
    public var symbol: String {
        switch self {
        case .squareMeters: "m²"
        case .squareFeet: "ft²"
        }
    }

    public var separator: String { " " }
}
