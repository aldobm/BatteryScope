# ⚡ Battery Scope — macOS Native Battery & Power Analyzer

<p align="center">
  <img src="AppIcon.icns" width="128" height="128" alt="Battery Scope Icon" />
</p>

<p align="center">
  <b>A sleek, native macOS power diagnostic and energy optimization suite built in SwiftUI.</b><br>
  Engineered for Apple Silicon (M1, M2, M3, M4) and Intel Mac laptops running macOS 13+ (Ventura, Sonoma, Sequoia).
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg" alt="Platform" />
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-purple.svg" alt="Architecture" />
  <img src="https://img.shields.io/badge/Swift-5.10%20%2F%206.0-orange.svg" alt="Swift" />
  <img src="https://img.shields.io/badge/UI-SwiftUI%20Native-cyan.svg" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" />
</p>

---

## ✨ Features

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
  - Seamless real-time switching without app restart via interactive language cards.
- **🧭 Liquid Glass Design**:
  - Modern, crystal dark mode interface with responsive animations and Menu Bar status item.

---

## 🛠️ Requirements

- **Mac hardware**: MacBook Air, MacBook Pro, Mac mini, Mac Studio, iMac, or Mac Pro.
- **Chip**: Apple Silicon (M1, M2, M3, M4) or Intel Core (x86_64).
- **Operating System**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), or macOS 15.0+ (Sequoia).
- **Developer Tools**: Xcode Command Line Tools (`swiftc`).

---

## 🚀 Quick Start & Build

Clone this repository and run the standalone build script:

```bash
git clone https://github.com/aldobm/BatteryScope.git
cd BatteryScope
chmod +x build.sh
./build.sh
```

The script compiles the native Swift application with the macOS SDK, signs it ad-hoc, and installs it to:
```
~/Applications/BatteryScope.app
```

You can then launch it from Spotlight, Finder, or Terminal:
```bash
open -a ~/Applications/BatteryScope.app
```

---

## 📂 Project Architecture

```
BatteryScope/
├── AppIcon.icns                # App icon bundle
├── build.sh                    # Build and packaging automation script
├── .gitignore                  # Git exclusions
├── README.md                   # Documentation
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
