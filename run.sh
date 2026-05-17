#!/bin/bash
# SIGCAL - Script de ejecución con hot reload
# Las credenciales se leen de .env (no se sube a git)

set -a
source "$(dirname "$0")/.env"
set +a

echo "🚀 Iniciando SIGCAL en Chrome con hot reload..."
echo "   URL Supabase: $SUPABASE_URL"
echo ""
echo "   Comandos durante la ejecución:"
echo "   r = Hot reload   R = Hot restart   q = Salir"
echo ""

flutter run -d chrome \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
