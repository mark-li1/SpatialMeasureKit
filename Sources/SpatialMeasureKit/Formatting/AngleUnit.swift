/// The unit of a formatted angle.
public enum AngleUnit: String, Sendable, CaseIterable, DisplayUnit {
    case degrees

    public var symbol: String { "°" }

    public var separator: String { "" }
}
