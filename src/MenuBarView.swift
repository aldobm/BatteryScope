import SwiftUI
import AppKit

public struct MenuBarView: View {
    @ObservedObject var service = BatteryService.shared
    @ObservedObject var locMgr = LocalizationManager.shared
    public var onOpenMainWindow: () -> Void
    public var onQuit: () -> Void
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header Bar
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(service.snapshot.isCharging ? Color.liquidAmber.opacity(0.2) : Color.liquidEmerald.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: service.snapshot.isCharging ? "bolt.fill" : "battery.100")
                        .foregroundColor(service.snapshot.isCharging ? Color.liquidAmber : Color.liquidEmerald)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("\(service.snapshot.chargePercent)%")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        if service.snapshot.isCharging {
                            Text(loc("charging"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.liquidAmber)
                        }
                    }
                    Text("\(loc("health")): \(service.snapshot.maxCapacityPercent)% • \(service.snapshot.cycleCount) \(loc("cycles"))")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f W", service.snapshot.systemPower > 0 ? service.snapshot.systemPower : service.snapshot.adapterPower))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.liquidCyan)
                    Text(loc("current_flow"))
                        .font(.system(size: 10))
                        .foregroundColor(Color.textMuted)
                }
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 16)
            
            // Top 3 Devoradores
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(loc("battery_devourers"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                    Text(loc("live_badge"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.liquidPink)
                }
                
                ForEach(service.topApps.prefix(3)) { app in
                    HStack(spacing: 8) {
                        if let img = app.icon {
                            Image(nsImage: img)
                                .resizable()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "app.fill")
                                .foregroundColor(Color.textSecondary)
                                .frame(width: 20, height: 20)
                        }
                        
                        Text(app.appName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f pts", app.powerScore))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(app.powerScore > 20 ? Color.liquidPink : Color.liquidAmber)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 14)
            
            // Bottom Action Buttons
            HStack(spacing: 8) {
                Button(action: onOpenMainWindow) {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow.on.rectangle")
                        Text(loc("open_analyzer"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color.liquidPurple, Color.liquidPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.liquidPurple.opacity(0.4), radius: 6)
                }
                .buttonStyle(.plain)
                
                LanguageFlagPickerMenu()
                
                Button(action: onQuit) {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                        .padding(9)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .help(loc("close_app"))
            }
        }
        .padding(14)
        .frame(width: 330)
        .background(
            ZStack {
                Color.liquidDarkBg
                Color.liquidViolet.opacity(0.5)
            }
        )
    }
}
