#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# SIGCAL – Build de producción para Flutter web (v3 – dart-define-from-file)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "📦 SIGCAL build.sh v3 (dart-define-from-file)"

# ── 1. Asegurar que Flutter esté disponible ─────────────────────────────────
if ! command -v flutter &>/dev/null; then
  FLUTTER_DIR="/tmp/flutter-sdk"
  if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📦 Descargando Flutter SDK (~2 min)..."
    git clone --depth 1 --branch stable \
      https://github.com/flutter/flutter.git "$FLUTTER_DIR" 2>&1 | tail -1
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
  flutter config --no-analytics 2>/dev/null || true
  flutter precache --web 2>&1 | tail -1
  echo "✅ Flutter $(flutter --version | head -1) instalado"
fi

# ── 2. Cargar variables ──────────────────────────────────────────────────
if [ -f .env ]; then
  set -a && source .env && set +a
fi

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "❌ Error: SUPABASE_URL y SUPABASE_ANON_KEY deben estar definidas."
  exit 1
fi

# ── 3. Compilar ───────────────────────────────────────────────────────────
echo "🔧 Compilando SIGCAL para web..."
echo "   URL:  $SUPABASE_URL"
echo "   KEY:  ${SUPABASE_ANON_KEY:0:20}..."
echo ""

# Escribir defines como JSON (printf evita problemas de heredoc/escaping)
printf '{"SUPABASE_URL":"%s","SUPABASE_ANON_KEY":"%s"}\n' \
  "$SUPABASE_URL" \
  "$SUPABASE_ANON_KEY" \
  > /tmp/sigcal-defines.json

flutter build web --dart-define-from-file=/tmp/sigcal-defines.json

echo ""
echo "✅ Build completado: build/web/"
