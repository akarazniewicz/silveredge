import AppKit
import SwiftUI
import Domain

struct ProcessList: View {
    @Environment(\.panelPalette) private var palette
    let processes: [ProcessUsage]
    let metric: ProcessMetric
    @State private var icons = ProcessIcons()

    var body: some View {
        if processes.isEmpty {
            ProcessListPlaceholder(showsShare: metric == .energy)
        } else {
            rows
        }
    }

    private var rows: some View {
        ForEach(0..<PanelTheme.processRows, id: \.self) { index in
            if index < processes.count {
                let process = processes[index]
                HStack(spacing: 7) {
                    Image(nsImage: icons.icon(for: process.pid))
                        .resizable()
                        .frame(width: PanelTheme.iconSize, height: PanelTheme.iconSize)
                    Text(process.others > 0 ? L10n.tr("process.group", "\(process.name) + \(process.others)") : process.name)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 8)
                    if let share = process.share {
                        Meter(fraction: share, tint: palette.energy(EnergyImpact.level(process.value)), width: PanelTheme.shareMeterWidth)
                        Text(PanelFormat.percent(share)).font(PanelTheme.valueFont).lineLimit(1)
                            .frame(width: PanelTheme.shareValueWidth, alignment: .trailing)
                    } else {
                        Text(PanelFormat.process(process.value, metric)).font(PanelTheme.valueFont).lineLimit(1).fixedSize()
                    }
                }
                .contentShape(Rectangle())
                .help(help(for: process))
                .accessibilityElement(children: .combine)
            } else {
                Text(verbatim: " ").frame(height: PanelTheme.iconSize)
            }
        }
    }

    private func help(for process: ProcessUsage) -> String {
        if process.share != nil { return L10n.tr("energy.impactHelp", "Energy Impact \(PanelFormat.energy(process.value))") }
        if process.others > 0 {
            return L10n.tr("process.groupHelp", "With \(process.others) more system processes macOS doesn't let SilverEdge read separately.")
        }
        return ""
    }
}

private struct ProcessListPlaceholder: View {
    @Environment(\.panelPalette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let showsShare: Bool
    @State private var dimmed = false

    private static let nameWidths: [CGFloat] = [118, 92, 136, 104, 78, 124, 96, 110]

    var body: some View {
        ForEach(0..<PanelTheme.processRows, id: \.self) { index in
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .frame(width: PanelTheme.iconSize, height: PanelTheme.iconSize)
                // Shrinks like a truncating name, so the panel keeps its width.
                Capsule().frame(maxWidth: Self.nameWidths[index % Self.nameWidths.count], maxHeight: PanelTheme.placeholderBarHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
                if showsShare {
                    Capsule().frame(width: PanelTheme.shareMeterWidth, height: PanelTheme.meterHeight)
                }
                Capsule().frame(width: PanelTheme.placeholderValueWidth, height: PanelTheme.placeholderBarHeight)
            }
            .foregroundStyle(palette.track)
            .opacity(dimmed ? 0.4 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever().delay(Double(index) * 0.06), value: dimmed)
            .accessibilityHidden(index > 0)
            .accessibilityLabel(L10n.tr("process.loading", "Loading processes"))
        }
        .onAppear { dimmed = true }
    }
}

/// Icons are shrunk once to a 32 px bitmap: drawn as is, each app icon goes to the GPU at full size (≈ 4 MB).
@MainActor
final class ProcessIcons {
    private static let limit = 64
    private var icons: [Int32: NSImage] = [:]
    private lazy var executable = Self.thumbnail(NSWorkspace.shared.icon(for: .unixExecutable))

    func icon(for pid: Int32) -> NSImage {
        if let icon = icons[pid] { return icon }
        if icons.count >= Self.limit { icons.removeAll() }
        let icon = NSRunningApplication(processIdentifier: pid)?.icon.map(Self.thumbnail) ?? executable
        icons[pid] = icon
        return icon
    }

    private static func thumbnail(_ image: NSImage) -> NSImage {
        let pixels = Int(PanelTheme.iconSize * 2)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                                            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0, bitsPerPixel: 0) else { return image }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let small = NSImage(size: NSSize(width: PanelTheme.iconSize, height: PanelTheme.iconSize))
        small.addRepresentation(bitmap)
        return small
    }
}
