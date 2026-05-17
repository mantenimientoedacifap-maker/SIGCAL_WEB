# SIGCAL — Paquete de especificación para Codex

Este paquete contiene la documentación inicial que Codex debe leer antes de desarrollar la aplicación.

## Nombre del proyecto

**SIGCAL — Sistema de Gestión de Calibración**

## Stack obligatorio

- **Frontend:** Flutter
- **Backend:** Supabase
- **Base de datos:** Supabase PostgreSQL
- **Autenticación:** Supabase Auth
- **Storage:** Supabase Storage
- **Navegación:** go_router
- **Estado:** flutter_riverpod
- **Fechas:** intl
- **Archivos:** file_picker, image_picker
- **Formularios:** flutter_form_builder, form_builder_validators
- **Tablas:** data_table_2
- **Gráficos:** fl_chart
- **Apertura de archivos/links:** url_launcher

## Orden recomendado de lectura para Codex

1. `01_PROJECT_OVERVIEW.md`
2. `02_FUNCTIONAL_REQUIREMENTS.md`
3. `03_TECH_STACK.md`
4. `04_FLUTTER_ARCHITECTURE.md`
5. `05_SUPABASE_DATABASE.md`
6. `06_BUSINESS_RULES.md`
7. `07_UI_UX_GUIDELINES.md`
8. `08_DEVELOPMENT_PHASES.md`
9. `09_PROJECT_MANUAL_TEMPLATE.md`
10. `10_CODEX_MASTER_PROMPT.md`
11. `11_SUPABASE_INITIAL_SCHEMA.sql.md`
12. `12_USER_INSTRUCTION_MANUAL_REQUIREMENTS.md`

## Instrucción obligatoria para Codex

Antes de escribir código, Codex debe leer todos los archivos `.md` de este paquete y respetar el alcance funcional, técnico y arquitectónico definido.

Codex debe trabajar por fases, sin avanzar desordenadamente, y debe mantener actualizado el archivo `docs/PROJECT_MANUAL.md` durante todo el desarrollo.


## Manuales obligatorios durante el desarrollo

Codex debe mantener actualizados dos manuales:

1. `docs/PROJECT_MANUAL.md`
   - Manual técnico y funcional del proyecto.
   - Documenta arquitectura, código, rutas, modelos, Supabase, reglas, configuración y despliegue.

2. `docs/USER_INSTRUCTION_MANUAL.md`
   - Manual de instrucción para usuarios finales.
   - Documenta cómo usar el sistema, procedimientos, flujos operativos, alertas, reportes, carga documental, buenas prácticas, errores frecuentes y registro de cambios.

Ambos manuales deben actualizarse conforme avance el desarrollo.
