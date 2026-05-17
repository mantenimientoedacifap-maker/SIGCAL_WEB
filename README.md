# SIGCAL

Sistema de Gestión de Calibración desarrollado con Flutter web y Supabase.

## Fase actual

Fase 6 inicial: login protegido, Supabase remoto, inventario conectado, ficha tecnica con QR/prestamos, administracion inicial de usuarios/roles y registro funcional de calibraciones con certificado PDF opcional.

## Ejecutar localmente

```bash
flutter pub get
flutter run -d chrome
```

## Ejecutar con Supabase

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://ichjvyttxlzjbzbjihdn.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

Para compilar web con Supabase:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://ichjvyttxlzjbzbjihdn.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key
```

## Supabase MCP

El proyecto está preparado para usar el servidor MCP remoto de Supabase configurado en Codex:

```txt
project_ref=ichjvyttxlzjbzbjihdn
```

También se instalaron skills de agente del paquete `supabase/agent-skills` a nivel de proyecto.

## Esquema Supabase

La migración inicial está en:

```txt
supabase/migrations/20260430030000_phase_03_initial_schema_auth_roles_storage.sql
```

Incluye perfiles, roles `lider`, `administrador`, `usuario`, tablas operativas, RLS, datos iniciales y buckets privados de Storage.

Las migraciones de Fase 3 fueron reaplicadas en el nuevo proyecto Supabase `ichjvyttxlzjbzbjihdn`.

Datos de prueba cargados:

- 12 herramientas/equipos.
- 11 calibraciones con estados vigentes, criticos y vencidos.
- 3 envios a calibracion, 2 activos.
- 1 usuario Lider inicial.

## Documentación

- `docs/PROJECT_MANUAL.md`: manual técnico y funcional.
- `docs/USER_INSTRUCTION_MANUAL.md`: manual de instrucción para usuarios.
