import SwiftUI
import UIKit

enum RemnTypography {
    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom("Neucha", size: size, relativeTo: textStyle)
            .weight(weight)
    }

    static var brand: Font { display(36, weight: .medium, relativeTo: .largeTitle) }
    static var pageTitle: Font { display(37, weight: .medium, relativeTo: .largeTitle) }
    static var navigationTitle: Font { display(23, weight: .semibold, relativeTo: .headline) }
    static var control: Font { display(20, weight: .medium, relativeTo: .body) }
    static var smallControl: Font { display(17, weight: .medium, relativeTo: .subheadline) }

    static var isDisplayFontAvailable: Bool {
        UIFont(name: "Neucha", size: 17) != nil
    }
}

/// Reserve glyph-run width for the irregular overhangs of handwritten type.
struct HandwrittenText: View {
    private let content: Text

    init(_ key: LocalizedStringKey) {
        content = Text(key)
    }

    init(verbatim value: String) {
        content = Text(verbatim: value)
    }

    init(text: Text) {
        content = text
    }

    var body: some View {
        (Text(verbatim: "\u{202F}") + content + Text(verbatim: "\u{202F}"))
            .accessibilityLabel(content)
    }
}

extension View {
    /// Give handwritten strokes room at the edges of compact controls.
    func remnHandwrittenBounds(horizontal: CGFloat = 3, vertical: CGFloat = 2) -> some View {
        padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
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

    static func counted(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(localized(count == 1 ? singular : plural))"
    }
}
