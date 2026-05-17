#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# SIGCAL – Build de producción para Flutter web
#
# En Vercel, las variables SUPABASE_URL y SUPABASE_ANON_KEY se inyectan
# automáticamente desde el dashboard (Settings → Environment Variables).
# En local, se leen desde el archivo .env (gitignored, nunca se sube).
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

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

echo "🔧 Compilando SIGCAL para web..."
echo "   SUPABASE_URL: $SUPABASE_URL"
echo ""

flutter build web \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "✅ Build completado: build/web/"
