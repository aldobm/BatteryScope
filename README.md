# ⚡ Battery Scope — macOS Native Battery & Power Analyzer

<p align="center">
  <img src="docs/screenshots/app_icon.png" width="128" height="128" alt="Battery Scope Icon" />
</p>

<p align="center">
  <b>Language / Idioma:</b>
  <a href="README.md"><b>🇺🇸 English</b></a> | 
  <a href="README.es.md"><b>🇪🇸 Español</b></a>
</p>

<p align="center">
  <b>A sleek, native macOS power diagnostic and energy optimization suite built in SwiftUI.</b><br>
  Engineered for Apple Silicon (M1, M2, M3, M4) and Intel Mac laptops running macOS 13+ (Ventura, Sonoma, Sequoia).
</p>

<p align="center">
  <a href="https://github.com/aldobm/BatteryScope/releases/latest">
    <img src="https://img.shields.io/github/v/release/aldobm/BatteryScope?style=for-the-badge&logo=apple&color=00D2FF&label=Release" alt="Latest Release" />
  </a>
  <a href="https://github.com/aldobm/BatteryScope/releases">
    <img src="https://img.shields.io/github/downloads/aldobm/BatteryScope/total?style=for-the-badge&logo=apple&color=30D158&label=Downloads" alt="Total Downloads" />
  </a>
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-5856D6?style=for-the-badge&logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-AF52DE?style=for-the-badge" alt="Architecture" />
  <img src="https://img.shields.io/badge/Swift-5.10%20%2F%206.0-F05138?style=for-the-badge&logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/AI-Smart%20Advisor-FF2D55?style=for-the-badge" alt="Smart Advisor" />
  <img src="https://img.shields.io/badge/UI-SwiftUI%20Liquid-34C759?style=for-the-badge" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/License-MIT-FF9500?style=for-the-badge" alt="License" />
</p>

---

## 📥 Download & Install (DMG)

Download the ready-to-run native installer directly:

<p align="center">
  <a href="https://github.com/aldobm/BatteryScope/releases/download/v1.0.0/BatteryScope-v1.0.0.dmg">
    <img src="https://img.shields.io/badge/⬇️%20Download-BatteryScope--v1.0.0.dmg-30D158?style=for-the-badge&labelColor=1c1c1e" height="42" alt="Download Battery Scope DMG" />
  </a>
</p>

1. Download **[BatteryScope-v1.0.0.dmg](https://github.com/aldobm/BatteryScope/releases/download/v1.0.0/BatteryScope-v1.0.0.dmg)**.
2. Double-click the DMG and drag **Battery Scope** into your **Applications** folder.
3. Launch from Launchpad, Finder, or Spotlight.

---

## 📸 Interface & Feature Showcase

### 🌟 Smart Analysis Dashboard
<p align="center">
  <img src="docs/screenshots/01_smart_analysis.jpg" alt="Battery Scope Smart Analysis" width="95%" />
</p>

---

### 🧠 Automated Intelligent Recommendations & Process Inspector

Unlike standard task managers that just show cryptic numbers and PIDs, Battery Scope actively **analyzes the root cause of energy drain and gives you automated, actionable recommendations**:

<p align="center">
  <img src="docs/screenshots/smart_recommendations.jpg" alt="Automated Smart Recommendations" width="95%" />
</p>

- ℹ️ **Process Role in macOS**: Explains what the daemon actually does (e.g. `WindowServer` compositing, `fileproviderd` syncing, `siriactionsd` background requests).
- ❓ **Why is it active?**: Automatically pinpoints the triggering cause (high window density, video streams, or external displays).
- 💡 **What should you do?**: Concrete, non-destructive recommendations to immediately reduce power consumption and reclaim hours of battery life.
- 📊 **Real-Time Telemetry Curve**: Live wattage trend, cumulative mWh drained, CPU thread workload, and percentage share of total drain.

---

### 🔍 Power Diagnostics & Timeline

| 🔥 Process Drain & Telemetry | 📈 Interval History & DarkWake |
| :---: | :---: |
| <img src="docs/screenshots/02_process_drain.jpg" alt="Process Drain" width="100%" /> | <img src="docs/screenshots/03_interval_history.jpg" alt="Interval History" width="100%" /> |
| *Real-time mWh, wattage curves & background service explanations* | *30-min block telemetry & background lid-closed power drains* |

| 📉 Timeline Consumption Charts | 🔋 3-Cell Hardware Health & Telemetry |
| :---: | :---: |
| <img src="docs/screenshots/04_timeline_charts.jpg" alt="Timeline Charts" width="100%" /> | <img src="docs/screenshots/05_health_cells.jpg" alt="Health & Cells" width="100%" /> |
| *Historical timeline tracing battery and charging events* | *Live 3-cell voltage balancing, temperature sensor & cycle capacity* |

---

### 🔌 Hardware Inspection & Power Delivery

| ⚡ USB-C Charger & Power Delivery | 🖥️ Hardware Subsystems Breakdown |
| :---: | :---: |
| <img src="docs/screenshots/06_usbc_charger.jpg" alt="USB-C Charger" width="100%" /> | <img src="docs/screenshots/07_hardware_breakdown.jpg" alt="Hardware Breakdown" width="100%" /> |
| *Negotiated PD wattage, adapter voltage, amperage & cable health* | *Real-time energy draw per component: SoC, Retina Display, RAM, SSD* |

---

### 🛠️ Maintenance, Startup & Preferences

| 🚀 Startup Apps Audit (Login Items) | 🛑 Smart Process Freeze & Optimization |
| :---: | :---: |
| <img src="docs/screenshots/08_startup_apps.jpg" alt="Startup Apps" width="100%" /> | <img src="docs/screenshots/09_optimization.jpg" alt="Optimization" width="100%" /> |
| *Audit background launch agents and manage boot delay impact* | *SIGSTOP freeze heavy sync hogs without quitting; display brightness tips* |

### 🌐 Multi-Language Settings
<p align="center">
  <img src="docs/screenshots/10_settings.jpg" alt="Settings & Multi-language" width="95%" />
  <br>
  <i>Instant live language switching across 7 native languages with interactive flag cards</i>
</p>

---

## ✨ Features

- **🧠 Automated Intelligent Recommendations**:
  - Automatically identifies why background processes consume energy and provides specific, actionable battery-saving guidance for 30+ macOS daemons.
- **🔋 Real-Time Smart Battery Telemetry**:
  - Live wattage (W), voltage (V), and amperage (A) monitoring.
  - Individual 3-cell voltage balance visualizer.
  - Cycle count, retained design capacity, and health condition.
- **⚡ USB-C Charger & Power Delivery Inspector**:
  - Live negotiated wattage, voltage, amperage, and cable condition.
- **📊 Temporal Consumption & Interval History**:
  - Interactive block bar charts for hourly / 30-min drain history.
  - DarkWake / Lid Closed background power tracking.
- **🔥 Process Drain & Energy Hogs**:
  - Process power consumption rating, CPU thread usage, and milliwatt (mW) metrics.
  - Temporal consumption charts per process.
  - Built-in explanation database for 30+ system daemons and user apps.
- **🛑 Smart Process Control & SIGSTOP/SIGCONT Pausing**:
  - Temporarily pause heavy cloud sync daemons (`Google Drive`, `Synology Drive`, `fileproviderd`) while on battery without quitting them.
- **🚀 Startup Apps Audit**:
  - Review login items, launch agents, and their boot delay impact.
- **🖥️ Hardware Subsystems Breakdown**:
  - Live power breakdown across physical components: Retina Display, Apple M-Series SoC, Unified RAM, NVMe SSD, Audio, and Peripherals.
- **🌐 7 Native Languages Built-in**:
  - 🇺🇸 English *(Default on first launch)*
  - 🇪🇸 Español
  - 🇫🇷 Français
  - 🇩🇪 Deutsch
  - 🇧🇷 Português
  - 🇮🇹 Italiano
  - 🇯🇵 日本語
  - Seamless real-time switching without app restart via interactive language cards in Settings.
- **🧭 Liquid Glass Design**:
  - Modern, crystal dark mode interface with responsive animations and Menu Bar status item.

---

## 🛠️ System Requirements

- **Mac hardware**: MacBook Air, MacBook Pro, Mac mini, Mac Studio, iMac, or Mac Pro.
- **Chip**: Apple Silicon (M1, M2, M3, M4) or Intel Core (x86_64).
- **Operating System**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), or macOS 15.0+ (Sequoia).

---

## 🚀 Build from Source

You can also build the application directly with Xcode Command Line Tools:

```bash
git clone https://github.com/aldobm/BatteryScope.git
cd BatteryScope
chmod +x build.sh
./build.sh
```

The script compiles the native Swift application, signs it, and installs it to:
```
~/Applications/BatteryScope.app
```

---

## 📂 Project Architecture

```
BatteryScope/
├── AppIcon.icns                # Native macOS icon bundle
├── AppIcon.png                 # App icon image
├── build.sh                    # Build and compilation script
├── create_dmg.sh               # DMG disk image packager
├── publish_release.sh          # Automated GitHub Release publisher
├── .github/workflows/          # GitHub Actions CI/CD workflows
├── docs/screenshots/           # Screenshots and interface assets
├── README.md                   # Project documentation in English
├── README.es.md                # Project documentation in Spanish
└── src/
    ├── main.swift              # App entry point
    ├── AppDelegate.swift       # NSApplicationDelegate & MenuBar popover controller
    ├── MainView.swift          # Main split navigation canvas & tabs
    ├── MenuBarView.swift       # Menu bar quick status popup
    ├── BatteryService.swift    # IOKit & IOPS battery power service
    ├── ProcessDatabase.swift   # Explanations & macOS process database
    ├── LocalizationManager.swift # 7-language reactive localization manager
    ├── SettingsView.swift      # Preferences & language card selector
    ├── HardwareBreakdownService.swift # Component energy distribution model
    ├── HardwareBreakdownView.swift    # Hardware monitoring UI
    ├── StartupAppsService.swift       # Login items & launch agents analyzer
    ├── StartupAppsView.swift          # Startup apps management UI
    ├── TimelineAndEnergyViews.swift   # Temporal charts & interval history
    ├── SmartSyncAdvisor.swift         # Developer cloud sync optimizer
    ├── LiquidTheme.swift              # Design tokens & color palettes
    └── LiquidComponents.swift         # Custom SwiftUI cards, pills, buttons
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
