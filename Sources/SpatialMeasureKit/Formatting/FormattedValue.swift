/// A formatted number and its unit, kept apart so they can be styled differently.
public struct FormattedValue<Unit: Equatable & Sendable>: Equatable, Sendable {
    /// The number, already rounded and localized, like `"3.45"`.
    public let value: String
    public let unit: Unit

    public init(value: String, unit: Unit) {
        self.value = value
        self.unit = unit
    }
}

/// A unit that knows how it's written after a number.
public protocol DisplayUnit: Equatable, Sendable {
    /// The symbol, like `m`, `ft²` or `°`. Not translated: unit symbols are the same everywhere.
    var symbol: String { get }
    /// What goes between the number and the symbol: a space before `m`, nothing before `°`.
    var separator: String { get }
}

extension FormattedValue where Unit: DisplayUnit {
    /// The number and its unit, joined the right way: `3.50 m`, `11' 3⅞"`, `37°`.
    public var text: String {
        value + unit.separator + unit.symbol
    }
}

public typealias FormattedLength = FormattedValue<LengthUnit>
public typealias FormattedArea = FormattedValue<AreaUnit>
public typealias FormattedAngle = FormattedValue<AngleUnit>
