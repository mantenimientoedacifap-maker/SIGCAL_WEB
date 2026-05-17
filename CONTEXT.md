# SIGCAL – Guía de Contexto para IA

> **Frase de entrada:** _"Abrimos SIGCAL. Continúa desde donde quedamos."_

Al leer esta frase, la IA debe:
1. Leer este archivo (`CONTEXT.md`)
2. Cargar `.env` para tener todas las claves disponibles
3. Revisar `docs/PROJECT_MANUAL.md` para el estado actual
4. Verificar rama activa y estado de deploy

---

## 📦 Stack

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter Web 3.41+ con Riverpod + go_router |
| Backend | Supabase (Auth, DB, Storage, Edge Functions) |
| Hosting | Vercel (CI/CD desde GitHub) |
| Control | GitHub + Vercel + Supabase (tokens en `.env`) |

---

## 🔑 Servicios disponibles (tokens en `.env`)

| Servicio | Variable | Permisos |
|----------|----------|----------|
| **Supabase** | `SUPABASE_URL`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `DB_PASSWORD`, `PROJECT_REF` | Admin total |
| **Vercel** | `VERCEL_TOKEN`, `PROJECT_ID`, `TEAM` | Deploy, logs, env vars |
| **GitHub** | `GITHUB_TOKEN`, `GITHUB_REPO` | repo (push, pull, merge) |

---

## 🌿 Ramas

| Rama | Propósito | Deploy |
|------|-----------|--------|
| `sigcalweb-v1` | Producción | ✅ Vercel auto-deploy |
| `sigcalweb-v1.1` | Desarrollo activo | ❌ |

---

## 📁 Archivos clave

| Archivo | Qué contiene |
|---------|-------------|
| `.env` | **TODAS las claves** (NUNCA se sube a git) |
| `vercel.json` | Config de deploy (SPA rewrites) |
| `build.sh` | Build Flutter con `--dart-define-from-file` |
| `docs/PROJECT_MANUAL.md` | Documentación técnica completa |
| `docs/USER_INSTRUCTION_MANUAL.md` | Manual de usuario |
| `supabase/functions/` | Edge Functions |
| `supabase/migrations/` | Migraciones SQL |

---

## 🚀 Comandos rápidos

```bash
# Ejecutar localmente
./run.sh

# Desplegar Edge Function
supabase functions deploy create-user --project-ref ichjvyttxlzjbzbjihdn

# Verificar estado Vercel (el último deploy)
# (la IA usa VERCEL_TOKEN de .env)

# Build manual
./build.sh
```

---

## ⚠️ Reglas de trabajo con IA

1. **NUNCA** hacer commit, push, merge o deploy sin autorización explícita
2. Siempre mostrar plan antes de ejecutar
3. Mantener `PROJECT_MANUAL.md` actualizado
4. El `.env` contiene todas las claves — usarlas sin pedirlas de nuevo

---

## 📊 Estado actual (16/05/2026)

- **v1.0**: 10 módulos completos, desplegado en Vercel
- **v1.1**: En desarrollo. Último cambio: Edge Function create-user v2 (JWT + validación Lider)
- **Usuario Lider**: franciscobances@sigcal.com
- **URL producción**: sigcal-*.vercel.app (consultar Vercel)
