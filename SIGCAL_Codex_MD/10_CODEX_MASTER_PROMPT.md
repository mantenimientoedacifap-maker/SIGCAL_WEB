# 10 — Prompt Maestro para Codex

Copia y pega este prompt en Codex después de colocar todos los archivos `.md` del paquete en el proyecto.

---

## PROMPT PARA CODEX

Quiero que desarrolles una aplicación web usando Flutter para el frontend y Supabase para el backend.

Nombre del proyecto:

**SIGCAL — Sistema de Gestión de Calibración**

Antes de escribir código, lee todos los archivos `.md` incluidos en este paquete de especificación:

1. `00_README_CODEX.md`
2. `01_PROJECT_OVERVIEW.md`
3. `02_FUNCTIONAL_REQUIREMENTS.md`
4. `03_TECH_STACK.md`
5. `04_FLUTTER_ARCHITECTURE.md`
6. `05_SUPABASE_DATABASE.md`
7. `06_BUSINESS_RULES.md`
8. `07_UI_UX_GUIDELINES.md`
9. `08_DEVELOPMENT_PHASES.md`
10. `09_PROJECT_MANUAL_TEMPLATE.md`
11. `11_SUPABASE_INITIAL_SCHEMA.sql.md`
12. `12_USER_INSTRUCTION_MANUAL_REQUIREMENTS.md`

Debes respetar completamente el alcance funcional, técnico y arquitectónico definido en esos documentos.

## Stack obligatorio

- Frontend: Flutter.
- Backend: Supabase.
- Base de datos: Supabase PostgreSQL.
- Autenticación: Supabase Auth.
- Storage: Supabase Storage.
- Navegación: go_router.
- Estado: flutter_riverpod.
- Fechas: intl.
- Archivos: file_picker.
- Imágenes móvil: image_picker.
- Formularios: flutter_form_builder.
- Validaciones: form_builder_validators.
- Tablas: data_table_2.
- Gráficos: fl_chart.
- Apertura de archivos/links: url_launcher.

## Objetivo funcional

Crear una web app moderna, profesional y responsive para controlar la calibración de herramientas especiales, equipos electrónicos, instrumentos de medición y otros equipos sujetos a calibración.

La app debe permitir:

1. Registrar herramientas/equipos.
2. Registrar datos técnicos.
3. Registrar calibraciones.
4. Calcular fecha de vencimiento.
5. Alertar desde 30 días antes del vencimiento.
6. Controlar equipos enviados a centros de calibración.
7. Adjuntar certificados de calibración.
8. Adjuntar guías de remisión.
9. Ver historial de calibraciones.
10. Ver historial de envíos.
11. Consultar reportes.
12. Mantener trazabilidad.

## Requisito obligatorio de documentación

Desde el inicio del proyecto debes crear y mantener actualizados dos manuales:

```txt
docs/PROJECT_MANUAL.md
docs/USER_INSTRUCTION_MANUAL.md
```

`PROJECT_MANUAL.md` debe funcionar como manual técnico y funcional del proyecto.

`USER_INSTRUCTION_MANUAL.md` debe funcionar como manual de instrucción para usuarios finales, operadores y supervisores. Debe explicar procedimientos de uso, pasos operativos, flujos de registro, interpretación de alertas, carga de certificados, carga de guías de remisión, consultas, reportes, buenas prácticas, errores frecuentes y control de cambios.

Después de cada cambio importante debes actualizar los manuales correspondientes, incluyendo:

- Estructura de carpetas.
- Componentes creados.
- Rutas creadas.
- Modelos creados.
- Repositorios creados.
- Tablas Supabase.
- Reglas de negocio.
- Flujo de archivos.
- Cambios relevantes.
- Pendientes.

Además, el `USER_INSTRUCTION_MANUAL.md` debe incluir como mínimo:

- Portada.
- Control de cambios.
- Introducción.
- Alcance del sistema.
- Definiciones y abreviaturas.
- Roles de usuario.
- Acceso al sistema.
- Descripción general de la interfaz.
- Procedimiento para registrar herramientas/equipos.
- Procedimiento para editar herramientas/equipos.
- Procedimiento para registrar calibraciones.
- Procedimiento para cargar certificados.
- Procedimiento para enviar equipos a centro de calibración.
- Procedimiento para registrar retorno.
- Explicación de alertas.
- Uso de reportes.
- Uso de búsqueda y filtros.
- Buenas prácticas.
- Errores frecuentes y solución.
- Preguntas frecuentes.
- Anexos.
- Registro de cambios por versión.

## Modo de trabajo obligatorio

No avances de forma desordenada.

Trabaja por fases:

1. Proyecto Flutter base.
2. Configuración Supabase.
3. Base de datos y Storage.
4. Modelos y repositorios.
5. Inventario.
6. Calibraciones.
7. Envíos.
8. Alertas.
9. Dashboard.
10. Reportes.
11. Mejora visual y validaciones.
12. Documentación final inicial.

Al terminar cada fase:

- Verifica que la app compile.
- Corrige errores.
- Actualiza `docs/PROJECT_MANUAL.md`.
- Resume los cambios realizados.

## Entregable inicial

Empieza por la Fase 1:

1. Crear proyecto Flutter.
2. Configurar dependencias.
3. Crear estructura de carpetas.
4. Crear tema global.
5. Crear rutas base.
6. Crear layout principal con sidebar/topbar.
7. Crear `docs/PROJECT_MANUAL.md`.
8. Crear `docs/USER_INSTRUCTION_MANUAL.md`.
9. Documentar todo lo realizado en ambos manuales según corresponda.

No implementes funcionalidades avanzadas antes de completar la base del proyecto.
