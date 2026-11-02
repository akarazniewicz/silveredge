import SwiftUI
import Domain

/// One bar of a `BarGraph`: segments stacked up from the baseline and, in a mirrored graph, one down from it.
struct GraphBar {
    struct Segment {
        /// 0…1 of the graph's height (of each half, when mirrored).
        var fraction: Double
        var color: Color
    }

    var up: [Segment]
    var down: Segment?
}

/// The panels' history graph: a slot per bar, newest at the right, nil slots left empty.
/// `capped` draws each bar faint with a solid top edge — an area under a level, for discrete states.
///
/// Drawn as one filled path per colour, not a `Canvas`: in a panel a `Canvas` this size held ≈ 130 MB of
/// graphics memory (measured); shapes cost next to nothing.
struct BarGraph: View {
    @Environment(\.panelPalette) private var palette
    let capacity: Int
    let bars: [GraphBar?]
    var height = PanelTheme.graphHeight
    var mirrored = false
    var capped = false

    var body: some View {
        GeometryReader { proxy in
            let layers = layout(proxy.size)
            ZStack(alignment: .topLeading) {
                Self.path(layers.baseline).fill(palette.track)
                ForEach(layers.fills.indices, id: \.self) { index in
                    let layer = layers.fills[index]
                    Self.path(layer.rects).fill(capped ? layer.color.opacity(0.28) : layer.color)
                    if capped {
                        Self.path(layer.rects.map { CGRect(x: $0.minX, y: $0.minY, width: $0.width, height: min(1.5, $0.height)) })
                            .fill(layer.color)
                    }
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private static func path(_ rects: [CGRect]) -> Path {
        Path { $0.addRects(rects) }
    }

    private struct Layer {
        var color: Color
        var rects: [CGRect]
    }

    /// Every bar's rectangles, grouped by colour, and the baseline.
    private func layout(_ size: CGSize) -> (fills: [Layer], baseline: [CGRect]) {
        let slot = size.width / CGFloat(capacity)
        let width = max(1, slot - PanelTheme.graphBarGap)
        let baseline = mirrored ? (size.height / 2).rounded() : size.height
        let span = mirrored ? baseline : size.height
        var layers: [Layer] = []
        func add(_ rect: CGRect, _ color: Color) {
            if let index = layers.firstIndex(where: { $0.color == color }) {
                layers[index].rects.append(rect)
            } else {
                layers.append(Layer(color: color, rects: [rect]))
            }
        }
        for (index, bar) in bars.enumerated() {
            guard let bar else { continue }
            let x = size.width - CGFloat(bars.count - index) * slot
            var top = baseline
            for segment in bar.up {
                // Stacked segments never run past the top.
                let length = min(span * segment.fraction.clampedToUnit, top - (baseline - span))
                guard length > 0 else { continue }
                top -= length
                add(CGRect(x: x, y: top, width: width, height: length), segment.color)
            }
            if let down = bar.down {
                let length = span * down.fraction.clampedToUnit
                if length > 0 { add(CGRect(x: x, y: baseline, width: width, height: length), down.color) }
            }
        }
        return (layers, [CGRect(x: 0, y: baseline - (mirrored ? 0.5 : 1), width: size.width, height: 1)])
    }
}
