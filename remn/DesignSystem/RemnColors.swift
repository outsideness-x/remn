import SwiftUI
import UIKit

/// Paper, one ink, a graphite pencil and a red pencil. Dark mode is the same kit on charcoal paper.
extension Color {
    static let remnPaper = Color(light: 0xF5F1E8, dark: 0x151412)
    static let remnCardPaper = Color(light: 0xFBF8F1, dark: 0x1F1D1A)
    static let remnInk = Color(light: 0x1D1B19, dark: 0xEFEADF)
    static let remnGraphite = Color(light: 0x5E5952, dark: 0xA39E95)
    static let remnAccent = Color(light: 0xBE3B2C, dark: 0xF0674E)
    /// Text and marks drawn on top of the red pencil.
    static let remnOnAccent = Color(light: 0xFBF8F1, dark: 0x151412)

    static let remnSurface = remnInk.opacity(0.05)

    private init(light: UInt32, dark: UInt32) {
        self.init(
            UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
