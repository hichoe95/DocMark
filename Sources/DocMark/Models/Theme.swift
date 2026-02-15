import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct CodeTheme {
    let lightThemeName: String
    let darkThemeName: String

    static let `default` = CodeTheme(
        lightThemeName: "xcode",
        darkThemeName: "monokai-sublime"
    )

    static let github = CodeTheme(
        lightThemeName: "github",
        darkThemeName: "github-dark"
    )
}
