//
//  ScaleBarView.swift
//  GoInfoGame
//
//  Ported from the Android app's ScaleBar.kt (StreetComplete) so both platforms
//  render the same bracket-style, dual-unit scale indicator.
//

import SwiftUI

/// A unit system the scale bar can render a bracket for (mirrors Android's
/// `ScaleBarMeasure`): a base unit in meters, the "nice" round stops it snaps to,
/// and how a stop value is formatted once picked.
private struct ScaleBarMeasure {
    let unitInMeters: Double
    let stops: [Double]
    let label: (Double) -> String

    /// 1-2-5 progression × powers of ten — e.g. exponents -1...3 gives
    /// 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000.
    static func buildStops(mantissas: [Double] = [1, 2, 5], exponents: ClosedRange<Int>) -> [Double] {
        exponents.flatMap { e in mantissas.map { $0 * pow(10, Double(e)) } }
    }

    private static func formatted(_ value: Double, symbol: String) -> String {
        let rounded = (value * 10).rounded() / 10
        let text = rounded.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
        return "\(text) \(symbol)"
    }

    static let metric = ScaleBarMeasure(
        unitInMeters: 1,
        stops: buildStops(exponents: -1...7),
        label: { stop in
            stop >= 1_000 ? formatted(stop / 1_000, symbol: "km") : formatted(stop, symbol: "m")
        }
    )

    static let feetAndMiles = ScaleBarMeasure(
        unitInMeters: 0.3048,
        stops: Array(buildStops(exponents: -1...3).dropLast(1))
            + buildStops(exponents: 0...4).map { $0 * 5_280 },
        label: { stop in
            stop >= 5_280 ? formatted(stop / 5_280, symbol: "mi") : formatted(stop, symbol: "ft")
        }
    )
}

/// Which measure(s) to show — always feet/miles on top with meters/kilometers
/// underneath, matching the shared app's scale bar reference regardless of the
/// device's own region. (The Android source this was ported from derives this
/// from the device's locale — non-metric regions show their local unit with
/// metric underneath, metric regions show metric only — but that would hide
/// the second line entirely on a metric-region device like this one's.)
private func defaultScaleBarMeasures() -> (primary: ScaleBarMeasure, secondary: ScaleBarMeasure?) {
    (.feetAndMiles, .metric)
}

/// Dual-unit map scale bar — a bracket line with tick marks at both ends (plus a
/// middle tick when a shorter secondary unit is shown) matching the Android app's
/// scale indicator: bare black strokes/text directly over the map, no card
/// background. MapLibre's built-in `MLNScaleBar` only supports one unit system
/// and renders as a striped ruler, so this replaces it with a custom view driven
/// by `metersPerPoint` (from `MLNMapView.metersPerPoint(atLatitude:)`, updated as
/// the camera moves).
struct ScaleBarView: View {
    /// Real-world distance, in meters, that one screen point represents at the
    /// map's current zoom/latitude. Non-positive values render nothing.
    let metersPerPoint: Double

    private let maxBarWidth: CGFloat = 80
    private let tickHeight: CGFloat = 6
    private let lineWidth: CGFloat = 1.5

    private struct Segment {
        let widthPoints: CGFloat
        let label: String
    }

    private func segment(for measure: ScaleBarMeasure) -> Segment {
        let maxUnits = Double(maxBarWidth) * metersPerPoint / measure.unitInMeters
        let stop = measure.stops.last(where: { $0 <= maxUnits }) ?? measure.stops.first!
        let widthPoints = CGFloat(stop * measure.unitInMeters / metersPerPoint)
        return Segment(widthPoints: widthPoints, label: measure.label(stop))
    }

    var body: some View {
        if metersPerPoint > 0 {
            let measures = defaultScaleBarMeasures()
            let primary = segment(for: measures.primary)
            let secondary = measures.secondary.map(segment(for:))

            let fullWidth = max(primary.widthPoints, secondary?.widthPoints ?? 0)
            let shortWidth = secondary.map { min(primary.widthPoints, $0.widthPoints) }

            VStack(alignment: .trailing, spacing: 1) {
                Text(primary.label)

                // The bracket sits between the two labels — primary's ticks hang
                // down to it, secondary's hang up to it — rather than below both.
                Canvas { context, size in
                    let baselineY = size.height / 2
                    var baseline = Path()
                    baseline.move(to: CGPoint(x: 0, y: baselineY))
                    baseline.addLine(to: CGPoint(x: fullWidth, y: baselineY))
                    context.stroke(baseline, with: .color(.black), lineWidth: lineWidth)

                    var ticks: [CGFloat] = [0, fullWidth]
                    if let shortWidth { ticks.append(shortWidth) }
                    for x in ticks {
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: baselineY - tickHeight / 2))
                        tick.addLine(to: CGPoint(x: x, y: baselineY + tickHeight / 2))
                        context.stroke(tick, with: .color(.black), lineWidth: lineWidth)
                    }
                }
                .frame(width: fullWidth, height: tickHeight + lineWidth)

                if let secondary {
                    Text(secondary.label)
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.black)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Map scale: \(primary.label)")
        }
    }
}

#Preview {
    ScaleBarView(metersPerPoint: 0.6)
        .padding()
        .background(Color.gray.opacity(0.2))
}
