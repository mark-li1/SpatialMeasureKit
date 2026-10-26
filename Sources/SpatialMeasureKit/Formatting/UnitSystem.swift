import Foundation

/// The unit system a measurement is displayed in.
///
/// Values are always stored and calculated in meters — this only affects presentation.
/// Backed by `String` so callers can persist it directly (e.g. `@AppStorage`).
public enum UnitSystem: String, Sendable, CaseIterable {
    case metric
    case imperial

    public init(locale: Locale) {
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, *) {
            self = locale.measurementSystem == .us ? .imperial : .metric
        } else {
            self = locale.usesMetricSystem ? .metric : .imperial
        }
    }
}
