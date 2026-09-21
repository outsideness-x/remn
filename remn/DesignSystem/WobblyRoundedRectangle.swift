import SwiftUI

struct WobblyRoundedRectangle: Shape {
    let seed: Int
    var cornerRadius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        let wobble = offsets(seed: seed)
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius + wobble[0], y: rect.minY + wobble[1]))
        path.addLine(to: CGPoint(x: rect.maxX - radius + wobble[2], y: rect.minY + wobble[3]))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX + wobble[4], y: rect.minY + radius),
            control: CGPoint(x: rect.maxX + wobble[5], y: rect.minY + wobble[6])
        )
        path.addLine(to: CGPoint(x: rect.maxX + wobble[7], y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY + wobble[8]),
            control: CGPoint(x: rect.maxX + wobble[9], y: rect.maxY + wobble[10])
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY + wobble[11]))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + wobble[12], y: rect.maxY - radius),
            control: CGPoint(x: rect.minX + wobble[13], y: rect.maxY + wobble[14])
        )
        path.addLine(to: CGPoint(x: rect.minX + wobble[15], y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius + wobble[0], y: rect.minY + wobble[1]),
            control: CGPoint(x: rect.minX + wobble[2], y: rect.minY + wobble[3])
        )
        path.closeSubpath()
        return path
    }

    private func offsets(seed: Int) -> [CGFloat] {
        (0..<16).map { index in
            let value = abs((seed &* 31 &+ index &* 17) % 11) - 5
            return CGFloat(value) * 0.11
        }
    }
}
