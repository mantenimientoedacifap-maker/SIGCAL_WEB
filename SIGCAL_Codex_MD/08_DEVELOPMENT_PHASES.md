# 08 — Fases de Desarrollo

Codex debe trabajar por fases y actualizar `docs/PROJECT_MANUAL.md` después de cada cambio importante.

---

# Fase 1 — Proyecto Flutter base

## Objetivo

Crear la base técnica inicial del proyecto.

## Tareas

1. Crear proyecto Flutter.
2. Activar soporte web.
3. Configurar dependencias.
4. Crear estructura de carpetas.
5. Crear `main.dart`.
6. Crear `app.dart`.
7. Crear tema global.
8. Crear rutas base.
9. Crear layout principal.
10. Crear `docs/PROJECT_MANUAL.md`.

## Entregable

Proyecto Flutter compilando correctamente con pantalla base.

---

# Fase 2 — Configuración Supabase

## Objetivo

Conectar Flutter con Supabase.

## Tareas

1. Configurar `supabase_flutter`.
2. Crear archivo de configuración.
3. Crear `.env.example` o equivalente.
4. Crear cliente Supabase.
5. Validar conexión.
6. Documentar configuración.

## Entregable

App conectada a Supabase.

---

# Fase 3 — Base de datos y Storage

## Objetivo

Crear estructura backend.

## Tareas

1. Crear SQL inicial.
2. Crear tablas.
3. Crear índices.
4. Crear datos iniciales.
5. Activar RLS.
6. Crear políticas iniciales.
7. Crear buckets de Storage.
8. Documentar todo en `PROJECT_MANUAL.md`.

## Entregable

Supabase listo para operar.

---

# Fase 4 — Modelos y repositorios

## Objetivo

Crear capa de datos en Flutter.

## Tareas

1. Crear modelos Dart.
2. Crear `ToolModel`.
3. Crear `CalibrationModel`.
4. Crear `ShipmentModel`.
5. Crear repositorio de tools.
6. Crear repositorio de calibrations.
7. Crear repositorio de shipments.
8. Crear providers Riverpod.
9. Crear utilidades de fechas y estados.

## Entregable

Capa de datos funcional.

---

# Fase 5 — Inventario

## Objetivo

Crear el módulo de herramientas/equipos.

## Tareas

1. Pantalla de inventario.
2. Tabla principal.
3. Buscador.
4. Filtros.
5. Crear herramienta/equipo.
6. Editar herramienta/equipo.
7. Ver detalle.
8. Dar de baja.

## Entregable

Inventario funcional.

---

# Fase 6 — Calibraciones

## Objetivo

Registrar y controlar calibraciones.

## Tareas

1. Formulario de calibración.
2. Cálculo automático de vencimiento.
3. Cálculo de días restantes.
4. Estado automático.
5. Carga de certificado.
6. Historial de calibraciones.
7. Visualización de último certificado.

## Entregable

Control de calibraciones funcional.

---

# Fase 7 — Envíos a centro de calibración

## Objetivo

Controlar herramientas enviadas a laboratorios o proveedores.

## Tareas

1. Formulario de envío.
2. Registro de centro de calibración.
3. Fecha de remisión.
4. Guía de remisión.
5. Carga de guía.
6. Fecha estimada de retorno.
7. Estado del envío.
8. Retorno de equipo.
9. Actualización automática de ubicación.

## Entregable

Módulo de envíos funcional.

---

# Fase 8 — Alertas

## Objetivo

Mostrar alertas desde 30 días antes del vencimiento.

## Tareas

1. Vista de alertas.
2. Filtro próximos 30 días.
3. Filtro próximos 15 días.
4. Filtro vencidos.
5. Filtro en calibración.
6. Filtro sin calibración.
7. Filtro sin certificado.
8. Orden por criticidad.

## Entregable

Sistema de alertas funcional.

---

# Fase 9 — Dashboard

## Objetivo

Crear panel ejecutivo del sistema.

## Tareas

1. Cards KPI.
2. Gráfico por estado.
3. Próximos vencimientos.
4. Vencidos.
5. En calibración.
6. Sin calibración.
7. Accesos rápidos.

## Entregable

Dashboard funcional.

---

# Fase 10 — Reportes

## Objetivo

Crear vistas de consulta y reportes.

## Tareas

1. Reporte de vigentes.
2. Reporte de vencidos.
3. Reporte de próximos a vencer.
4. Reporte de en calibración.
5. Reporte por fabricante.
6. Reporte por ubicación.
7. Reporte por categoría.
8. Preparar exportación futura.

## Entregable

Reportes funcionales.

---

# Fase 11 — Mejora visual y validaciones

## Objetivo

Pulir calidad visual y robustez.

## Tareas

1. Validaciones de formularios.
2. Mensajes de error.
3. Loading states.
4. Empty states.
5. Badges visuales.
6. Responsive design.
7. Pruebas de flujo completo.

## Entregable

Versión estable inicial.

---

# Fase 12 — Documentación final inicial

## Objetivo

Completar manual técnico y funcional.

## Tareas

1. Actualizar descripción.
2. Actualizar estructura.
3. Documentar rutas.
4. Documentar modelos.
5. Documentar Supabase.
6. Documentar reglas de negocio.
7. Documentar flujo de archivos.
8. Documentar instalación.
9. Documentar despliegue.

## Entregable

`PROJECT_MANUAL.md` completo.
