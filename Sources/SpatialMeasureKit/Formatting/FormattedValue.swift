/// A measurement split into its magnitude and the unit that magnitude is expressed in.
///
/// The two are kept apart rather than joined into one string so callers can style, order, or
/// localize them independently.
public struct FormattedValue<Unit: Equatable & Sendable>: Equatable, Sendable {
    /// The magnitude, already rounded and localized — e.g. `"3.45"`, `"45"`.
    public let value: String
    /// The unit `value` is expressed in.
    public let unit: Unit

    public init(value: String, unit: Unit) {
        self.value = value
        self.unit = unit
    }
}

public protocol DisplayUnit: Equatable, Sendable {
    var symbol: String { get }
    var separator: String { get }
}

extension FormattedValue where Unit: DisplayUnit {
    public var text: String {
        value + unit.separator + unit.symbol
    }
}

public typealias FormattedLength = FormattedValue<LengthUnit>
public typealias FormattedArea = FormattedValue<AreaUnit>
public typealias FormattedAngle = FormattedValue<AngleUnit>
