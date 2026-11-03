import Foundation

/// Metric or imperial. It only changes how values are shown; they're always calculated in meters.
///
/// Backed by `String`, so it can be stored directly, for example with `@AppStorage`.
public enum UnitSystem: String, Sendable, CaseIterable {
    case metric
    case imperial

    /// The unit system people expect in `locale`.
    ///
    /// Only the US gets imperial; the UK counts as metric. If the user picked a measurement system
    /// in Settings, `Locale.current` already includes that choice.
    public init(locale: Locale) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self = locale.measurementSystem == .us ? .imperial : .metric
        } else {
            self = locale.usesMetricSystem ? .metric : .imperial
        }
    }
}
