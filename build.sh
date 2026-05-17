#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# SIGCAL – Build de producción para Flutter web
#
# En Vercel, las variables SUPABASE_URL y SUPABASE_ANON_KEY se inyectan
# automáticamente desde el dashboard (Settings → Environment Variables).
# En local, se leen desde el archivo .env (gitignored, nunca se sube).
#
# Si Flutter no está instalado (entorno Vercel), se descarga automáticamente.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── 1. Asegurar que Flutter esté disponible ─────────────────────────────────
if ! command -v flutter &>/dev/null; then
  FLUTTER_DIR="/tmp/flutter-sdk"
  if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📦 Descargando Flutter SDK (esto puede tomar ~2 min en Vercel)..."
    git clone --depth 1 --branch stable \
      https://github.com/flutter/flutter.git "$FLUTTER_DIR" 2>&1 | tail -1
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
  flutter config --no-analytics 2>/dev/null || true
  flutter precache --web 2>&1 | tail -1
  echo "✅ Flutter $(flutter --version | head -1) instalado"
fi

# ── 2. Cargar variables de entorno ──────────────────────────────────────────
# En local: cargar .env si existe
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

# Validar que las variables obligatorias estén definidas
if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "❌ Error: SUPABASE_URL y SUPABASE_ANON_KEY deben estar definidas."
  echo "   En local: asegúrate de que .env exista con ambas variables."
  echo "   En Vercel: configúralas en Settings → Environment Variables."
  exit 1
fi

# ── 3. Compilar ─────────────────────────────────────────────────────────────
echo "🔧 Compilando SIGCAL para web..."
echo "   SUPABASE_URL: $SUPABASE_URL"
echo ""

flutter build web \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "✅ Build completado: build/web/"
