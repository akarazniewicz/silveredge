import Foundation

/// Native resource lookup in this target's bundle.
enum L10n {
    static func tr(_ key: StaticString, _ value: String.LocalizationValue) -> String {
        String(localized: key, defaultValue: value, bundle: .module)
    }
}
