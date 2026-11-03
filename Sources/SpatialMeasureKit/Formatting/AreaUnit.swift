/// The unit of a formatted area. Imperial area is always decimal square feet.
public enum AreaUnit: String, Sendable, CaseIterable, DisplayUnit {
    case squareMeters
    case squareFeet

    public var symbol: String {
        switch self {
        case .squareMeters: "m²"
        case .squareFeet: "ft²"
        }
    }

    public var separator: String { " " }
}
