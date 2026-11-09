import SwiftUI

struct PanelCard<Accessory: View, Content: View>: View {
    @Environment(\.panelPalette) private var palette
    let title: String
    let symbol: String
    var trailing: String?
    let accessory: Accessory
    let content: Content

    init(title: String, symbol: String, @ViewBuilder accessory: () -> Accessory, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: symbol)
                    .textCase(.uppercase)
                    .font(PanelTheme.headerFont)
                    .foregroundStyle(palette.secondaryText)
                    .labelStyle(.titleAndIcon)
                Spacer()
                accessory
                if let trailing {
                    Text(trailing).font(PanelTheme.headlineFont)
                }
            }
            VStack(alignment: .leading, spacing: PanelTheme.rowSpacing) {
                content
            }
            .font(PanelTheme.rowFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PanelTheme.cardPadding)
        .background(palette.cardFill, in: RoundedRectangle(cornerRadius: PanelTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PanelTheme.cardRadius, style: .continuous)
                .strokeBorder(palette.cardKeyline, lineWidth: 1)
        }
    }
}

extension PanelCard where Accessory == EmptyView {
    init(title: String, symbol: String, trailing: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.trailing = trailing
        accessory = EmptyView()
        self.content = content()
    }
}
