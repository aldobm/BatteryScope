import SwiftUI
import AppKit

// MARK: - Language Card Component (Inspired by Mac Storage & Account Cards)

public struct LanguageFichaCard: View {
    public let language: AppLanguage
    public let isSelected: Bool
    public let onSelect: () -> Void
    
    @State private var isHovered: Bool = false
    
    private var regionSubtitle: String {
        switch language {
        case .english: return "United States • United Kingdom • Global"
        case .spanish: return "España • Latinoamérica • Caribe"
        case .french: return "France • Canada • Suisse • Belgique"
        case .german: return "Deutschland • Österreich • Schweiz"
        case .portuguese: return "Brasil • Portugal • Lusofonia"
        case .italian: return "Italia • Svizzera • San Marino"
        case .japanese: return "日本 • 全域 (日本語ネイティブ対応)"
        }
    }
    
    private var badgeText: String {
        switch language {
        case .english: return "DEFAULT"
        case .spanish: return "NATIVO"
        case .french: return "EUROPE"
        case .german: return "DACH"
        case .portuguese: return "GLOBAL"
        case .italian: return "ITALIA"
        case .japanese: return "ASIA"
        }
    }
    
    private var localeCode: String {
        switch language {
        case .english: return "en_US • ISO 639-1 • en"
        case .spanish: return "es_ES • es_419 • es"
        case .french: return "fr_FR • fr_CA • fr"
        case .german: return "de_DE • de_AT • de"
        case .portuguese: return "pt_BR • pt_PT • pt"
        case .italian: return "it_IT • it_CH • it"
        case .japanese: return "ja_JP • UTF-8 • ja"
        }
    }
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Row: Flag + Title + Badge + Checkmark
                HStack(alignment: .top, spacing: 12) {
                    // Flag Container with soft ambient glow
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isSelected ?
                                LinearGradient(colors: [Color.liquidCyan.opacity(0.25), Color.liquidPurple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(isSelected ? Color.liquidCyan.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        Text(language.flag)
                            .font(.system(size: 24))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(language.displayName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(badgeText)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(isSelected ? Color.liquidCyan : Color.liquidPurple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(isSelected ? Color.liquidCyan.opacity(0.18) : Color.liquidPurple.opacity(0.18))
                                .clipShape(Capsule())
                        }
                        
                        Text(regionSubtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Selected Checkmark or Subtle Circle
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.liquidCyan)
                            .shadow(color: Color.liquidCyan.opacity(0.6), radius: 6)
                    } else {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                    }
                }
                
                // Technical Path / Locale code (Identical to '/Users/aldo' in the screenshot)
                Text(localeCode)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.textMuted)
                
                Divider()
                    .background(Color.white.opacity(isSelected ? 0.16 : 0.08))
                
                // Bottom Row: Status + Coverage (Identical to 'Libre: 257 GB  Total: 494 GB')
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isSelected ? Color.liquidCyan : Color.textMuted)
                            .frame(width: 6, height: 6)
                            .shadow(color: isSelected ? Color.liquidCyan : Color.clear, radius: 3)
                        
                        Text(isSelected ? loc("settings_status_active") : loc("settings_status_select"))
                            .font(.system(size: 12, weight: isSelected ? .heavy : .semibold, design: .rounded))
                            .foregroundColor(isSelected ? Color.liquidCyan : Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(loc("settings_translation_coverage"))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? Color.liquidEmerald : Color.textMuted)
                }
            }
            .padding(14)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(hex: "131D38"), Color(hex: "1F0F3D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(hex: "140828").opacity(0.85)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ?
                        LinearGradient(colors: [Color.liquidCyan, Color.liquidCyan.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.white.opacity(isHovered ? 0.25 : 0.12), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.liquidCyan.opacity(0.22) : Color.black.opacity(0.3),
                radius: isSelected ? 12 : 5,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { h in isHovered = h }
    }
}

// MARK: - Dedicated Settings & Options View

public struct SettingsView: View {
    @ObservedObject var locMgr = LocalizationManager.shared
    @ObservedObject var service = BatteryService.shared
    
    @State private var autoPauseDevDaemonsOnBattery: Bool = true
    @State private var scanIntervalSeconds: Double = 3.0
    @State private var showResetAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section 1: Language Selection in Interactive Fichas
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundColor(Color.liquidCyan)
                        .font(.system(size: 16, weight: .bold))
                    Text(loc("settings_lang_section"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(loc("settings_lang_note"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .lineSpacing(2)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270, maximum: 380), spacing: 14)], spacing: 14) {
                    ForEach(AppLanguage.allCases) { lang in
                        LanguageFichaCard(
                            language: lang,
                            isSelected: locMgr.currentLanguage == lang,
                            onSelect: {
                                locMgr.setLanguage(lang)
                            }
                        )
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
            .liquidGlassCard(cornerRadius: 18)
            
            // Section 2: Monitoring Preferences
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(Color.liquidAmber)
                        .font(.system(size: 16, weight: .bold))
                    Text(loc("settings_general_section"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    // Option Row: Refresh interval
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("settings_refresh_rate"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(loc("settings_refresh_desc"))
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            ForEach([2.0, 3.0, 5.0], id: \.self) { sec in
                                Button(action: { scanIntervalSeconds = sec }) {
                                    Text("\(Int(sec))s")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(scanIntervalSeconds == sec ? Color.liquidCyan : Color.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(scanIntervalSeconds == sec ? Color.liquidCyan.opacity(0.18) : Color.white.opacity(0.06))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().strokeBorder(scanIntervalSeconds == sec ? Color.liquidCyan.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "0A0414").opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Option Row: Auto-pause dev daemons
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("settings_autopause_title"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(loc("settings_autopause_desc"))
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoPauseDevDaemonsOnBattery)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color.liquidCyan))
                    }
                    .padding(12)
                    .background(Color(hex: "0A0414").opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(18)
            .liquidGlassCard(cornerRadius: 18)
            
            // Section 3: About BatteryPulse & GitHub
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color.liquidPink, Color.liquidPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 42, height: 42)
                        Image(systemName: "bolt.batteryblock.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BatteryPulse Pro • macOS Native")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(loc("settings_about_desc"))
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text(loc("settings_github_btn"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(colors: [Color.liquidPurple, Color.liquidPink], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.liquidPurple.opacity(0.4), radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .liquidGlassCard(cornerRadius: 18)
        }
    }
}
