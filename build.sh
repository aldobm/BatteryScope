#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="BatteryScope"
APP_BUNDLE="$DIR/build/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Limpiando build anterior..."
rm -rf "$DIR/build"
mkdir -p "$MACOS" "$RESOURCES"

echo "==> Copiando AppIcon.icns..."
if [ -f "$DIR/AppIcon.icns" ]; then
    cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
elif [ -f /tmp/AppIcon.icns ]; then
    cp /tmp/AppIcon.icns "$RESOURCES/AppIcon.icns"
fi

echo "==> Creando Info.plist..."
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BatteryScope</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aldo.BatteryScope</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Battery Scope</string>
    <key>CFBundleDisplayName</key>
    <string>Battery Scope</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "==> Compilando código Swift nativo..."
swiftc \
  -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  -parse-as-library \
  "$DIR/src/LocalizationManager.swift" \
  "$DIR/src/ProcessDatabase.swift" \
  "$DIR/src/BatteryService.swift" \
  "$DIR/src/LiquidTheme.swift" \
  "$DIR/src/LiquidComponents.swift" \
  "$DIR/src/SmartSyncAdvisor.swift" \
  "$DIR/src/TimelineAndEnergyViews.swift" \
  "$DIR/src/StartupAppsService.swift" \
  "$DIR/src/StartupAppsView.swift" \
  "$DIR/src/HardwareBreakdownService.swift" \
  "$DIR/src/HardwareBreakdownView.swift" \
  "$DIR/src/SettingsView.swift" \
  "$DIR/src/MainView.swift" \
  "$DIR/src/MenuBarView.swift" \
  "$DIR/src/AppDelegate.swift" \
  "$DIR/src/main.swift" \
  -o "$MACOS/$APP_NAME"

echo "==> Firmando aplicación ad-hoc..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "==> Instalando en ~/Applications/..."
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$HOME/Applications/"

echo "==> ¡Compilación e instalación completada con éxito!"
echo "Ubicación: $HOME/Applications/$APP_NAME.app"
