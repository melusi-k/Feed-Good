import SwiftUI
import UIKit

enum FeedGoodTheme {
    static let background = adaptive(light: 0xF3F2E9, dark: 0x171F19)
    static let surface = adaptive(light: 0xFDFCF7, dark: 0x222C24)
    static let leaf = adaptive(light: 0x294B3B, dark: 0xA7C69A)
    static let sage = adaptive(light: 0xA9B99C, dark: 0x526B54)
    static let moss = adaptive(light: 0x678B5D, dark: 0x9BB98A)
    static let soil = adaptive(light: 0x494139, dark: 0xF0EDE2)
    static let muted = adaptive(light: 0x6D7365, dark: 0xB6C0B1)
    static let mist = adaptive(light: 0xE6EBDD, dark: 0x2C3B30)
    static let bloom = adaptive(light: 0xC29679, dark: 0xD7A98B)
    static let border = adaptive(light: 0xDDE2D5, dark: 0x405044)
    static let primaryForeground = adaptive(light: 0xFFFFFF, dark: 0x172019)

    static let cardRadius: CGFloat = 24
    static let contentPadding: CGFloat = 22

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

enum FeedGoodAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
