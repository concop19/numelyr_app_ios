import Foundation
import SwiftUI

struct DailyConstellationView: View {
    let date: Date
    let profileKey: String
    var calendar = Calendar.autoupdatingCurrent

    private var symbol: ConstellationSymbolPreset {
        ConstellationEngine.dailySymbol(
            date: date,
            profileKey: profileKey,
            calendar: calendar
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if let geometry = try? ConstellationEngine.buildGeometry(for: symbol) {
                ConstellationCanvasView(geometry: geometry)
            } else {
                Color.clear
                    .accessibilityLabel("Biểu tượng hôm nay đang tạm ẩn")
            }

            Text("BIỂU TƯỢNG HÔM NAY · \(symbol.title.uppercased())")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.75)
                .foregroundStyle(Color(red: 0.43, green: 0.92, blue: 1))
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.9), radius: 6)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

struct ConstellationCanvasView: View {
    let geometry: ConstellationGeometry
    var ambientStars = ConstellationEngine.ambientStars(seed: 0x4E55_4D45, count: 105)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let compact = size.height > 0 && size.height < 720
                let fitted = ConstellationEngine.fit(
                    geometry,
                    inside: .init(
                        x: size.width * 0.16,
                        y: size.height * (compact ? 0.23 : 0.24),
                        width: size.width * 0.68,
                        height: size.height * (compact ? 0.27 : 0.32)
                    )
                )
                let pulse = reduceMotion
                    ? 1.0
                    : 0.94 + sin(timeline.date.timeIntervalSinceReferenceDate * 1.75) * 0.06

                Canvas(opaque: false, colorMode: .linear) { context, canvasSize in
                    drawAmbientStars(in: &context, size: canvasSize)
                    drawConstellation(fitted, in: &context)
                }
                .opacity(pulse)
                .scaleEffect(0.996 + (pulse - 0.88) / 0.12 * 0.008)
                .accessibilityHidden(true)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawAmbientStars(in context: inout GraphicsContext, size: CGSize) {
        for star in ambientStars {
            let radius = CGFloat(star.radius)
            let rect = CGRect(
                x: CGFloat(star.x) * size.width - radius,
                y: CGFloat(star.y) * size.height - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.opacity = star.opacity
            context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.84, green: 0.96, blue: 1)))
        }
        context.opacity = 1
    }

    private func drawConstellation(
        _ geometry: ConstellationGeometry,
        in context: inout GraphicsContext
    ) {
        for contour in geometry.contours {
            var line = Path()
            guard let first = contour.points.first else { continue }
            line.move(to: CGPoint(x: first.x, y: first.y))
            for point in contour.points.dropFirst() {
                line.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            if contour.isClosed { line.closeSubpath() }

            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Color(red: 0.15, green: 0.75, blue: 1).opacity(0.85), radius: 6))
                layer.stroke(
                    line,
                    with: .color(Color(red: 0.15, green: 0.75, blue: 1).opacity(0.28)),
                    lineWidth: 4
                )
            }
            context.stroke(
                line,
                with: .color(Color(red: 0.89, green: 0.98, blue: 1).opacity(0.96)),
                lineWidth: 1.25
            )

            for point in contour.points {
                drawStar(at: CGPoint(x: point.x, y: point.y), in: &context)
            }
        }
    }

    private func drawStar(at point: CGPoint, in context: inout GraphicsContext) {
        let haloRect = CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)
        let middleRect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
        let coreRect = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)

        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Color(red: 0.09, green: 0.77, blue: 1).opacity(0.9), radius: 10))
            layer.fill(
                Path(ellipseIn: haloRect),
                with: .color(Color(red: 0.07, green: 0.75, blue: 1).opacity(0.22))
            )
        }
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Color(red: 0.66, green: 0.95, blue: 1), radius: 5))
            layer.fill(
                Path(ellipseIn: middleRect),
                with: .color(Color(red: 0.35, green: 0.87, blue: 1))
            )
        }
        context.fill(Path(ellipseIn: coreRect), with: .color(.white))

        var rays = Path()
        rays.move(to: CGPoint(x: point.x - 12, y: point.y))
        rays.addLine(to: CGPoint(x: point.x + 12, y: point.y))
        rays.move(to: CGPoint(x: point.x, y: point.y - 15))
        rays.addLine(to: CGPoint(x: point.x, y: point.y + 15))
        context.stroke(
            rays,
            with: .color(Color(red: 0.91, green: 0.98, blue: 1).opacity(0.9)),
            lineWidth: 1
        )
    }
}

private struct DailyConstellationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.01, green: 0.04, blue: 0.12).ignoresSafeArea()
            DailyConstellationView(
                date: Date(timeIntervalSince1970: 1_791_331_200),
                profileKey: "preview|1998-10-20"
            )
            .padding(.bottom, 40)
        }
        .previewDisplayName("Daily constellation")
    }
}
