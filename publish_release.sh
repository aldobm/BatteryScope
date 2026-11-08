#!/usr/bin/env bash
set -e

# Battery Scope - Automated GitHub Publisher & Release Script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=============================================="
echo "⚡ BATTERY SCOPE - PUBLICADOR AUTOMÁTICO GITHUB"
echo "=============================================="

# 1. Verificar si gh está autenticado
if ! /opt/homebrew/bin/gh auth status >/dev/null 2>&1; then
    echo "⚠️  Primero necesitamos autorizar tu cuenta de GitHub (aldobm)..."
    echo "Abriendo el navegador para autorizar..."
    /opt/homebrew/bin/gh auth login --web -p https --scopes "repo,read:org"
fi

echo "✅ Autenticación con GitHub confirmada."

# 2. Crear repositorio en GitHub si no existe
echo "🚀 Verificando/Creando repositorio BatteryScope en GitHub..."
if ! /opt/homebrew/bin/gh repo view aldobm/BatteryScope >/dev/null 2>&1; then
    /opt/homebrew/bin/gh repo create aldobm/BatteryScope --public --description "Mac Menu Bar Energy & Battery Monitor in Swift" --source=. --remote=origin --push
    echo "✅ Repositorio aldobm/BatteryScope creado exitosamente."
else
    echo "ℹ️  El repositorio ya existe. Subiendo cambios y ramas..."
    git push -u origin main
fi

# 3. Subir tags
echo "🏷️  Subiendo etiquetas de versión (v1.0.0)..."
git push origin --tags

# 4. Publicar Release con el instalador DMG adjunto
DMG_PATH="$DIR/build/BatteryScope-v1.0.0.dmg"
if [ ! -f "$DMG_PATH" ]; then
    echo "⚙️  Generando instalador DMG..."
    ./create_dmg.sh
fi

echo "📦 Publicando Release v1.0.0 en GitHub con el archivo DMG..."
if /opt/homebrew/bin/gh release view v1.0.0 >/dev/null 2>&1; then
    echo "ℹ️  El release v1.0.0 ya existe. Subiendo asset DMG..."
    /opt/homebrew/bin/gh release upload v1.0.0 "$DMG_PATH" --clobber
else
    /opt/homebrew/bin/gh release create v1.0.0 "$DMG_PATH" \
        --title "Battery Scope v1.0.0" \
        --notes "### Battery Scope v1.0.0 - Release Oficial 🎉

Monitor avanzado de batería, consumo energético y salud del hardware para macOS (Apple Silicon M1/M2/M3/M4 e Intel).

#### Novedades:
- **Diagnóstico Inteligente** y recomendaciones de salud de batería.
- **Drenaje por Procesos** con métricas en tiempo real de mWh, vatios y cuota de consumo.
- **Gráficos de Consumo Temporal** interactivos.
- **Gestión de Apps de Arranque** (Login Items).
- **Multi-idioma completo:** Español, Inglés, Francés, Alemán, Portugués, Italiano y Japonés.

#### Instalación:
1. Descarga **BatteryScope-v1.0.0.dmg**.
2. Abre el archivo y arrastra **Battery Scope** a la carpeta **Aplicaciones**."
fi

echo ""
echo "======================================================="
echo "🎉 ¡LISTO! Tu proyecto y release están públicos en:"
echo "👉 https://github.com/aldobm/BatteryScope/releases/tag/v1.0.0"
echo "======================================================="

# Abrir en el navegador
open "https://github.com/aldobm/BatteryScope/releases/tag/v1.0.0" || true
