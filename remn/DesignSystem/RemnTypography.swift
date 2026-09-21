import SwiftUI
import UIKit

enum RemnTypography {
    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom("Caveat-Regular", size: size, relativeTo: textStyle)
            .weight(weight)
    }

    static var brand: Font { display(36, weight: .medium, relativeTo: .largeTitle) }
    static var pageTitle: Font { display(37, weight: .medium, relativeTo: .largeTitle) }
    static var navigationTitle: Font { display(23, weight: .semibold, relativeTo: .headline) }
    static var control: Font { display(20, weight: .medium, relativeTo: .body) }
    static var smallControl: Font { display(17, weight: .medium, relativeTo: .subheadline) }

    static var isDisplayFontAvailable: Bool {
        UIFont(name: "Caveat-Regular", size: 17) != nil
    }
}

enum RemnLanguage {
    static let locale = Locale(identifier: "en")

    private static let bundle: Bundle = {
        guard
            let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }()

    static func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
