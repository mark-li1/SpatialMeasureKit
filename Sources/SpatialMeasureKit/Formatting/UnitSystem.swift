/// The unit system a measurement is displayed in.
///
/// Values are always stored and calculated in meters — this only affects presentation.
/// Backed by `String` so callers can persist it directly (e.g. `@AppStorage`).
public enum UnitSystem: String, Sendable, CaseIterable {
    case metric
    case imperial
}
