// Renders remn's app icon with the same ink engine the app draws with.
//
//   Design/Icon/render.sh [output directory]
//
// The art is drawn on a 128-point canvas, the scale of the interface, and rendered at 8×
// so the hand keeps the proportions it has in the app.

import AppKit
import SwiftUI

@main
struct RenderIcon {
    @MainActor
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
        for variant in IconArt.Variant.allCases {
            let renderer = ImageRenderer(content: IconArt(variant: variant))
            renderer.scale = 8
            guard let image = renderer.cgImage else { throw RenderError.failed(variant.rawValue) }
            let url = output.appendingPathComponent(variant.filename)
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
                throw RenderError.failed(url.path)
            }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination) else { throw RenderError.failed(url.path) }
            print("wrote \(url.path) \(image.width)×\(image.height)")
        }
    }

    enum RenderError: Error {
        case failed(String)
    }
}

struct IconArt: View {
    enum Variant: String, CaseIterable {
        case light
        case dark
        case tinted

        var filename: String {
            switch self {
            case .light: "AppIcon.png"
            case .dark: "AppIcon-Dark.png"
            case .tinted: "AppIcon-Tinted.png"
            }
        }
    }

    let variant: Variant

    var body: some View {
        ZStack {
            Rectangle().fill(paper)

            // The card underneath, shaded with red pencil hatching.
            ZStack {
                InkHatch(seed: 71, spacing: 3.1, angle: .degrees(-50), pen: InkPen(width: 1.15, touchDown: 0.7, liftOff: 0.5, pressureVariation: 0.1))
                    .fill(accent.opacity(variant == .tinted ? 0.55 : 0.85))
                    .clipShape(InkPatch(seed: 72, cornerRadius: 9))
                InkRoundedRect(seed: 73, cornerRadius: 9, pen: InkPen(width: 2.3))
                    .fill(accent)
            }
            .frame(width: 86, height: 58)
            .rotationEffect(.degrees(9))
            .offset(x: 10, y: 17)

            // The card on top: paper laid a touch off-register, an ink outline, the red index rule
            // and a line of handwriting.
            ZStack {
                InkPatch(seed: 81, cornerRadius: 9)
                    .fill(cardPaper)
                    .offset(x: 0.9, y: 1.2)
                InkRoundedRect(seed: 82, cornerRadius: 9, pen: InkPen(width: 3.1, touchDown: 0.6, liftOff: 0.35))
                    .fill(ink)
                InkLine(seed: 83, pen: InkPen(width: 2, touchDown: 0.7, liftOff: 0.5))
                    .fill(accent)
                    .frame(width: 70, height: 6)
                    .offset(y: -15)
                Scribble(seed: 84)
                    .fill(ink)
                    .frame(width: 58, height: 12)
                    .offset(x: -4, y: 2)
                InkLine(seed: 85, pen: InkPen(width: 1.15, touchDown: 0.7, liftOff: 0.5))
                    .fill(ink.opacity(0.28))
                    .frame(width: 66, height: 5)
                    .offset(y: 16)
            }
            .frame(width: 88, height: 60)
            .rotationEffect(.degrees(-7))
            .offset(x: -7, y: -8)
        }
        .frame(width: 128, height: 128)
        .environment(\.colorScheme, variant == .light ? .light : .dark)
    }

    private var paper: Color {
        switch variant {
        case .light: Color(red: 0.961, green: 0.945, blue: 0.910)
        case .dark: Color(red: 0.082, green: 0.078, blue: 0.071)
        case .tinted: .black
        }
    }

    private var cardPaper: Color {
        switch variant {
        case .light: Color(red: 0.984, green: 0.973, blue: 0.945)
        case .dark: Color(red: 0.122, green: 0.114, blue: 0.102)
        case .tinted: Color(white: 0.1)
        }
    }

    private var ink: Color {
        switch variant {
        case .light: Color(red: 0.114, green: 0.106, blue: 0.098)
        case .dark: Color(red: 0.937, green: 0.918, blue: 0.875)
        case .tinted: .white
        }
    }

    private var accent: Color {
        switch variant {
        case .light: Color(red: 0.745, green: 0.231, blue: 0.173)
        case .dark: Color(red: 0.941, green: 0.404, blue: 0.306)
        case .tinted: Color(white: 0.62)
        }
    }
}

/// A word of joined-up handwriting, reduced to its rhythm: loops of different heights.
struct Scribble: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        var random = InkRandom(seed: seed)
        let letters = 6
        let step = rect.width / CGFloat(letters + 1)
        var points: [CGPoint] = [CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.12)]
        for letter in 0..<letters {
            let tall = letter == 1 || letter == 4
            let height = rect.height * (tall ? 1 : random.value(in: 0.42...0.58))
            let lean = random.value(in: 0.26...0.34)
            let start = rect.minX + step * (CGFloat(letter) + 0.35)
            for sample in 0..<28 {
                let u = CGFloat(sample) / 28
                points.append(
                    CGPoint(
                        x: start + step * u + step * lean * sin(2 * .pi * u),
                        y: rect.maxY - height * (1 - cos(2 * .pi * u)) / 2
                    )
                )
            }
        }
        points.append(CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.2))
        return InkBrush.stroke(
            points,
            pen: InkPen(width: 1.55, touchDown: 0.55, liftOff: 0.3, attack: 3, release: 7, pressureVariation: 0.2),
            seed: seed
        )
    }
}
