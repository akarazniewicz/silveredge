import AppKit
import Domain
import SwiftUI

package struct PanelPalette {
    package var appearance: NSAppearance.Name?
    package var material: NSVisualEffectView.Material
    package var surface: Color
    package var primaryText: Color
    package var secondaryText: Color
    package var cardFill: Color
    package var cardKeyline: Color
    package var tileFill: Color
    package var track: Color
    package var accent: Color
    package var system: Color
    package var efficiency: Color
    package var green: Color
    package var yellow: Color
    package var orange: Color
    package var red: Color
    package var purple: Color
    package var teal: Color

    package func load(_ perCore: Double) -> Color {
        perCore < 0.5 ? accent : perCore < 1 ? orange : red
    }

    package func energy(_ level: EnergyImpact.Level) -> Color {
        switch level {
        case .light: accent
        case .moderate: yellow
        case .high: orange
        case .extreme: red
        }
    }

    package func fan(_ fraction: Double) -> Color {
        fraction < 0.4 ? accent : fraction < 0.75 ? orange : red
    }

    package func thermal(_ pressure: ThermalPressure) -> Color {
        switch pressure {
        case .nominal: green
        case .moderate: yellow
        case .heavy, .trapping, .sleeping: red
        }
    }

    package func pressure(_ pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: green
        case .warning: yellow
        case .critical: red
        }
    }

    package func breakdown(_ part: MemoryPart) -> Color {
        switch part {
        case .app: accent
        case .wired: orange
        case .compressed: purple
        case .cached: teal
        case .free: track
        }
    }
}

extension PanelPalette {
    package static func make(_ theme: ThemeID) -> PanelPalette {
        switch theme {
        case .frost: .frosted(material: .hudWindow)
        case .system: .frosted(material: .popover)
        case .opal: .opal
        case .graphitePro: .graphitePro
        case .oneDarkPro: .oneDarkPro
        case .quartzPro: .quartzPro
        }
    }

    private static func frosted(material: NSVisualEffectView.Material) -> PanelPalette {
        PanelPalette(
            appearance: nil, material: material, surface: .clear,
            primaryText: .primary, secondaryText: .secondary,
            cardFill: .primary.opacity(0.06), cardKeyline: .primary.opacity(0.09), tileFill: .primary.opacity(0.05),
            track: .primary.opacity(0.1),
            accent: Color(nsColor: .systemBlue), system: Color(nsColor: .systemRed), efficiency: Color(nsColor: .systemTeal),
            green: Color(nsColor: .systemGreen), yellow: Color(nsColor: .systemYellow), orange: Color(nsColor: .systemOrange),
            red: Color(nsColor: .systemRed), purple: Color(nsColor: .systemPurple), teal: Color(nsColor: .systemTeal)
        )
    }

    private struct Tones {
        var light: Bool
        var base: UInt32
        var card: UInt32
        var text: UInt32
        var secondary: UInt32
        var accent: UInt32
        var red: UInt32
        var green: UInt32
        var amber: UInt32
        var cyan: UInt32
        var purple: UInt32
    }

    private static func solid(_ tones: Tones) -> PanelPalette {
        let (light, base, card, text, secondary) = (tones.light, tones.base, tones.card, tones.text, tones.secondary)
        let (accent, red, green, amber, cyan, purple) = (tones.accent, tones.red, tones.green, tones.amber, tones.cyan, tones.purple)
        let ink: Color = light ? .black : .white
        return PanelPalette(
            appearance: light ? .aqua : .darkAqua, material: light ? .popover : .hudWindow, surface: hex(base).opacity(0.94),
            primaryText: hex(text), secondaryText: hex(secondary),
            cardFill: hex(card), cardKeyline: ink.opacity(light ? 0.08 : 0.07), tileFill: ink.opacity(light ? 0.04 : 0.05),
            track: ink.opacity(light ? 0.09 : 0.1),
            accent: hex(accent), system: hex(red), efficiency: hex(cyan),
            green: hex(green), yellow: hex(amber), orange: hex(amber).mix(with: hex(red), by: 0.45),
            red: hex(red), purple: hex(purple), teal: hex(cyan)
        )
    }

    private static let opal = solid(Tones(light: false, base: 0x1c1c1d, card: 0x262628, text: 0xffffff, secondary: 0x8c8c8e,
                                    accent: 0x4d9eff, red: 0xed3b3b, green: 0x34c759, amber: 0xf2a829, cyan: 0x5ac8d8, purple: 0xbf5af2))
    private static let graphitePro = solid(Tones(light: false, base: 0x111214, card: 0x18191c, text: 0xeeeff1, secondary: 0xa4a5ad,
                                           accent: 0x8b8bd5, red: 0xcd7b80, green: 0x87b894, amber: 0xd2b577, cyan: 0x88aaa9, purple: 0xb08bd5))
    private static let oneDarkPro = solid(Tones(light: false, base: 0x282c34, card: 0x2c313a, text: 0xd7dae0, secondary: 0xabb2bf,
                                          accent: 0x61afef, red: 0xe06c75, green: 0x98c379, amber: 0xe5c07b, cyan: 0x56b6c2, purple: 0xc678dd))
    private static let quartzPro = solid(Tones(light: true, base: 0xececed, card: 0xf8f8f9, text: 0x262628, secondary: 0x66666a,
                                         accent: 0x5a5fc0, red: 0xc44b44, green: 0x3d8a57, amber: 0xb57f27, cyan: 0x4a8585, purple: 0x8a55b5))

    private static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xff) / 255, green: Double((value >> 8) & 0xff) / 255, blue: Double(value & 0xff) / 255)
    }
}

// A plain key, not `@Entry`: the Command Line Tools have no SwiftUI macros.
private struct PanelPaletteKey: EnvironmentKey {
    static let defaultValue = PanelPalette.make(.defaultID)
}

extension EnvironmentValues {
    package var panelPalette: PanelPalette {
        get { self[PanelPaletteKey.self] }
        set { self[PanelPaletteKey.self] = newValue }
    }
}
