import SwiftUI
import UIKit

extension Color {
    static let remnPaper = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.051, green: 0.047, blue: 0.071, alpha: 1)
                : UIColor(red: 0.957, green: 0.945, blue: 0.914, alpha: 1)
        }
    )

    static let remnInk = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.957, green: 0.937, blue: 0.875, alpha: 1)
                : UIColor(red: 0.110, green: 0.106, blue: 0.102, alpha: 1)
        }
    )

    static let remnGraphite = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.66, green: 0.63, blue: 0.59, alpha: 1)
                : UIColor(red: 0.36, green: 0.34, blue: 0.31, alpha: 1)
        }
    )

    static let remnAccent = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.87, green: 0.46, blue: 0.23, alpha: 1)
                : UIColor(red: 0.71, green: 0.25, blue: 0.19, alpha: 1)
        }
    )

    static let remnCardPaper = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.080, green: 0.074, blue: 0.102, alpha: 1)
                : UIColor(red: 0.982, green: 0.969, blue: 0.925, alpha: 1)
        }
    )

    static let remnSurface = remnInk.opacity(0.055)
}
