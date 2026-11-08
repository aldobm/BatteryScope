#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="BatteryScope"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="BatteryScope-v1.0.0.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGE_DIR="$BUILD_DIR/dmg_stage"

echo "==> Verificando que la app esté compilada..."
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Compilando aplicación..."
    "$DIR/build.sh"
fi

echo "==> Creando carpeta temporal para el instalador DMG..."
rm -rf "$STAGE_DIR" "$BUILD_DIR"/*.dmg
mkdir -p "$STAGE_DIR"

echo "==> Copiando $APP_NAME.app..."
cp -R "$APP_BUNDLE" "$STAGE_DIR/"

echo "==> Creando acceso directo a /Applications (Drag & Drop)..."
ln -s /Applications "$STAGE_DIR/Applications"

echo "==> Generando imagen de disco comprimida ($DMG_NAME)..."
hdiutil create \
    -volname "Battery Scope Installer" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "==> Limpiando carpeta temporal..."
rm -rf "$STAGE_DIR"

# También crear una copia amigable sin versión para enlaces fijos
cp "$DMG_PATH" "$BUILD_DIR/BatteryScope.dmg"

echo "==> ✅ ¡Instalador DMG creado con éxito!"
echo "Ubicación: $DMG_PATH"
ls -lh "$DMG_PATH"
