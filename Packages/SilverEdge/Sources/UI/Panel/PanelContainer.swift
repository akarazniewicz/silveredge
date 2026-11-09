import SwiftUI
import Domain

package struct PanelActions {
    package var openActivityMonitor: (ActivityMonitorTab) -> Void
    package var quit: () -> Void
    package var setCPUListMetric: (ProcessMetric) -> Void

    package init(openActivityMonitor: @escaping (ActivityMonitorTab) -> Void, quit: @escaping () -> Void,
                 setCPUListMetric: @escaping (ProcessMetric) -> Void) {
        self.openActivityMonitor = openActivityMonitor
        self.quit = quit
        self.setCPUListMetric = setCPUListMetric
    }
}

struct PanelContainer<Cards: View>: View {
    @Environment(\.panelPalette) private var palette
    let actions: PanelActions
    let tab: ActivityMonitorTab
    @ViewBuilder let cards: Cards

    var body: some View {
        VStack(spacing: PanelTheme.cardSpacing) {
            cards
            PanelFooter(actions: actions, tab: tab)
        }
        .padding(PanelTheme.padding)
        .frame(width: PanelTheme.width)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(palette.primaryText, palette.secondaryText)
        // The material's mask rounds only the material; the theme's own surface needs its own corners.
        .background(palette.surface, in: RoundedRectangle(cornerRadius: PanelTheme.cornerRadius, style: .continuous))
    }
}

private struct PanelFooter: View {
    let actions: PanelActions
    let tab: ActivityMonitorTab

    var body: some View {
        HStack {
            button(L10n.tr("footer.activityMonitor", "Open Activity Monitor"), symbol: "waveform.path.ecg.rectangle",
                   action: { actions.openActivityMonitor(tab) })
            Spacer()
            button(L10n.tr("footer.quit", "Quit SilverEdge"), symbol: "power", action: actions.quit)
        }
        .padding(.horizontal, 6)
        .padding(.top, 2)
    }

    private func button(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: PanelTheme.footerIconSize))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(title)
        .accessibilityLabel(title)
    }
}
