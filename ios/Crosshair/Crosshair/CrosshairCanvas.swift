import SwiftUI

struct CrosshairCanvas: View {
    let style: CrosshairStyle
    var previewBackground: Bool = false

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            draw(style, in: &context, center: center)
        }
        .background(previewBackground ? Color.black.opacity(0.35) : Color.clear)
    }

    private func draw(_ style: CrosshairStyle, in context: inout GraphicsContext, center: CGPoint) {
        let color = style.color
        let arm = style.length
        let thick = style.thickness
        let gap = style.gap

        func stroke(_ path: Path, width: Double, col: Color) {
            context.stroke(path, with: .color(col), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }

        func line(_ a: CGPoint, _ b: CGPoint) -> Path {
            var path = Path()
            path.move(to: a)
            path.addLine(to: b)
            return path
        }

        if style.outline {
            drawShape(style.shape, center: center, arm: arm, gap: gap, in: &context, color: .black.opacity(0.85), width: thick + 2.2)
        }
        drawShape(style.shape, center: center, arm: arm, gap: gap, in: &context, color: color, width: thick)
    }

    private func drawShape(
        _ shape: ReticleShape,
        center: CGPoint,
        arm: Double,
        gap: Double,
        in context: inout GraphicsContext,
        color: Color,
        width: Double
    ) {
        func stroke(_ path: Path) {
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        func fill(_ path: Path) {
            context.fill(path, with: .color(color))
        }
        func h(_ y: Double, from dx1: Double, to dx2: Double) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: center.x + dx1, y: center.y + y))
            path.addLine(to: CGPoint(x: center.x + dx2, y: center.y + y))
            return path
        }
        func v(_ x: Double, from dy1: Double, to dy2: Double) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: center.x + x, y: center.y + dy1))
            path.addLine(to: CGPoint(x: center.x + x, y: center.y + dy2))
            return path
        }
        func plus(gaped: Bool) {
            let g = gaped ? gap : 0
            stroke(h(0, from: -arm, to: -g))
            stroke(h(0, from: g, to: arm))
            stroke(v(0, from: -arm, to: -g))
            stroke(v(0, from: g, to: arm))
        }
        func cross(gaped: Bool) {
            let g = gaped ? gap * 0.7 : 0
            var a = Path()
            a.move(to: CGPoint(x: center.x - arm, y: center.y - arm))
            a.addLine(to: CGPoint(x: center.x - g, y: center.y - g))
            var b = Path()
            b.move(to: CGPoint(x: center.x + g, y: center.y + g))
            b.addLine(to: CGPoint(x: center.x + arm, y: center.y + arm))
            var c = Path()
            c.move(to: CGPoint(x: center.x + arm, y: center.y - arm))
            c.addLine(to: CGPoint(x: center.x + g, y: center.y - g))
            var d = Path()
            d.move(to: CGPoint(x: center.x - g, y: center.y + g))
            d.addLine(to: CGPoint(x: center.x - arm, y: center.y + arm))
            stroke(a); stroke(b); stroke(c); stroke(d)
        }
        func dot(_ radius: Double) {
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            fill(Path(ellipseIn: rect))
        }

        switch shape {
        case .plus:
            plus(gaped: false)
        case .plusGap:
            plus(gaped: true)
        case .plusDot:
            plus(gaped: true)
            dot(max(1.4, width * 0.7))
        case .cross:
            cross(gaped: false)
        case .crossGap:
            cross(gaped: true)
        case .dot:
            dot(max(2.2, width * 1.1))
        case .microDot:
            dot(1.4)
        case .circle:
            stroke(Path(ellipseIn: CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
        case .circleDot:
            stroke(Path(ellipseIn: CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
            dot(max(1.6, width * 0.8))
        case .circlePlus:
            stroke(Path(ellipseIn: CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
            plus(gaped: true)
        case .dualRing:
            stroke(Path(ellipseIn: CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
            stroke(Path(ellipseIn: CGRect(x: center.x - arm * 0.55, y: center.y - arm * 0.55, width: arm * 1.1, height: arm * 1.1)))
        case .square:
            stroke(Path(CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
        case .squareDot:
            stroke(Path(CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
            dot(max(1.6, width * 0.8))
        case .squareGap:
            let s = arm
            stroke(h(-s, from: -s, to: -gap))
            stroke(h(-s, from: gap, to: s))
            stroke(h(s, from: -s, to: -gap))
            stroke(h(s, from: gap, to: s))
            stroke(v(-s, from: -s, to: -gap))
            stroke(v(-s, from: gap, to: s))
            stroke(v(s, from: -s, to: -gap))
            stroke(v(s, from: gap, to: s))
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y - arm))
            path.addLine(to: CGPoint(x: center.x + arm, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + arm))
            path.addLine(to: CGPoint(x: center.x - arm, y: center.y))
            path.closeSubpath()
            stroke(path)
        case .diamondDot:
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y - arm))
            path.addLine(to: CGPoint(x: center.x + arm, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + arm))
            path.addLine(to: CGPoint(x: center.x - arm, y: center.y))
            path.closeSubpath()
            stroke(path)
            dot(max(1.5, width * 0.7))
        case .tScope:
            stroke(h(0, from: -arm, to: arm))
            stroke(v(0, from: 0, to: arm))
        case .chevron:
            var path = Path()
            path.move(to: CGPoint(x: center.x - arm, y: center.y + arm * 0.4))
            path.addLine(to: CGPoint(x: center.x, y: center.y - arm * 0.5))
            path.addLine(to: CGPoint(x: center.x + arm, y: center.y + arm * 0.4))
            stroke(path)
        case .brackets:
            var l = Path()
            l.move(to: CGPoint(x: center.x - arm * 0.3, y: center.y - arm))
            l.addLine(to: CGPoint(x: center.x - arm, y: center.y - arm))
            l.addLine(to: CGPoint(x: center.x - arm, y: center.y + arm))
            l.addLine(to: CGPoint(x: center.x - arm * 0.3, y: center.y + arm))
            var r = Path()
            r.move(to: CGPoint(x: center.x + arm * 0.3, y: center.y - arm))
            r.addLine(to: CGPoint(x: center.x + arm, y: center.y - arm))
            r.addLine(to: CGPoint(x: center.x + arm, y: center.y + arm))
            r.addLine(to: CGPoint(x: center.x + arm * 0.3, y: center.y + arm))
            stroke(l); stroke(r)
        case .corners:
            let s = arm
            let m = arm * 0.45
            stroke(h(-s, from: -s, to: -s + m))
            stroke(v(-s, from: -s, to: -s + m))
            stroke(h(-s, from: s - m, to: s))
            stroke(v(s, from: -s, to: -s + m))
            stroke(h(s, from: -s, to: -s + m))
            stroke(v(-s, from: s - m, to: s))
            stroke(h(s, from: s - m, to: s))
            stroke(v(s, from: s - m, to: s))
        case .hLine:
            stroke(h(0, from: -arm, to: arm))
        case .vLine:
            stroke(v(0, from: -arm, to: arm))
        case .asterisk:
            plus(gaped: false)
            cross(gaped: false)
        case .sniper:
            stroke(Path(ellipseIn: CGRect(x: center.x - arm, y: center.y - arm, width: arm * 2, height: arm * 2)))
            stroke(h(0, from: -arm * 1.35, to: -arm * 0.2))
            stroke(h(0, from: arm * 0.2, to: arm * 1.35))
            stroke(v(0, from: -arm * 1.35, to: -arm * 0.2))
            stroke(v(0, from: arm * 0.2, to: arm * 1.35))
            dot(1.3)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y - arm))
            path.addLine(to: CGPoint(x: center.x + arm, y: center.y + arm * 0.7))
            path.addLine(to: CGPoint(x: center.x - arm, y: center.y + arm * 0.7))
            path.closeSubpath()
            stroke(path)
        case .rangeFinder:
            stroke(h(0, from: -arm, to: -gap))
            stroke(h(0, from: gap, to: arm))
            stroke(v(0, from: -arm, to: -gap))
            stroke(v(0, from: gap, to: arm))
            stroke(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)))
        }
    }
}
