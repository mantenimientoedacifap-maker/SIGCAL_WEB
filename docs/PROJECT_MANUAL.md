# SIGCAL - Manual Técnico y Funcional

**Última actualización:** 16/05/2026
**Versión reflejada:** Fase 10 completada (Fase 8 pendiente)
**Último cambio:** Carga de guía de remisión en formulario de envío implementada

---

## 1. Descripción general

SIGCAL es una aplicación web desarrollada en Flutter con backend Supabase para controlar la calibración de herramientas especiales, equipos electrónicos, instrumentos de medición y otros equipos sujetos a calibración.

La versión actual incluye: login protegido con Supabase Auth, inventario conectado con búsqueda/filtros/paginación, ficha técnica completa con trazabilidad, registro funcional de calibraciones con certificado PDF, módulo de envíos con kanban, préstamos con vales QR, dashboard con KPIs reales, reportes/estadísticas con cronograma de vencimientos, administración de usuarios y configuración de perfil con avatar.

---

## 2. Stack utilizado

- **Frontend:** Flutter web
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
- **PDF:** pdf, printing
- **QR:** qr_flutter
- **Preferencias:** shared_preferences
- **Localización:** flutter_localizations

---

## 3. Estructura de carpetas

```
lib/
├── main.dart                              # Entry point, inicialización Supabase + Riverpod
├── app.dart                               # MaterialApp.router con temas, i18n, router
├── core/
│   ├── config/
│   │   ├── app_config.dart                # Lectura de --dart-define
│   │   ├── app_router.dart                # GoRouter con auth redirect + shell
│   │   ├── supabase_config.dart           # Inicialización segura, runtime info
│   │   └── supabase_providers.dart        # Providers cliente + estado Supabase
│   ├── constants/
│   │   ├── app_colors.dart                # Paleta de colores + helpers dark/light
│   │   ├── app_routes.dart                # Constantes y helpers de rutas
│   │   └── app_strings.dart               # Strings constantes
│   ├── i18n/
│   │   └── translations.dart              # Sistema de traducciones ES/EN
│   ├── notifications/
│   │   └── notification_read_store.dart   # Estado de notificaciones leídas
│   ├── preferences/
│   │   └── app_preferences.dart           # Tema visual + idioma (SharedPreferences)
│   ├── theme/
│   │   └── app_theme.dart                 # Temas claro/oscuro/clásico
│   ├── utils/
│   │   ├── calibration_status_utils.dart  # Utilidades de estado de calibración
│   │   ├── date_utils.dart                # Formateo de fechas
│   │   └── file_utils.dart                # Utilidades de archivos
│   └── widgets/
│       ├── app_shell.dart                 # Layout principal (sidebar + topbar + contenido)
│       ├── app_sidebar.dart               # Sidebar con navegación + footer estado
│       ├── app_topbar.dart                # Topbar con título, búsqueda, notificaciones, perfil
│       ├── empty_state.dart               # Widget estado vacío reutilizable
│       ├── loading_view.dart              # Widget de carga reutilizable
│       ├── page_header.dart               # Encabezado de página con título + acciones
│       ├── route_loading_gate.dart        # Gate de carga para rutas
│       └── status_badge.dart              # Badge de estado reutilizable
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_providers.dart        # Providers de autenticación
    │   │   ├── auth_refresh_listenable.dart # Listenable para GoRouter
    │   │   └── auth_repository.dart       # Repositorio de auth (login, perfil, avatar)
    │   ├── domain/
    │   │   ├── user_profile.dart          # Modelo UserProfile
    │   │   └── user_role.dart             # Enum AppRole con permisos
    │   └── presentation/
    │       ├── login_page.dart            # Pantalla de login
    │       └── reset_password_page.dart   # Pantalla de reset password
    ├── calibrations/
    │   ├── data/
    │   │   └── calibration_repository.dart # Repositorio de calibraciones
    │   └── presentation/
    │       ├── calibration_form_page.dart  # Formulario de registro de calibración
    │       └── calibration_history_widget.dart # Widget de historial
    ├── dashboard/
    │   ├── data/
    │   │   └── dashboard_providers.dart   # DashboardSnapshot, DashboardTool, ComplianceState
    │   └── presentation/
    │       ├── dashboard_page.dart        # Dashboard con KPIs, compliance, actividad
    │       └── widgets/
    │           └── kpi_card.dart          # Card de KPI individual
    ├── loans/
    │   ├── data/
    │   │   └── loans_providers.dart       # Provider de préstamos globales
    │   └── presentation/
    │       └── loans_page.dart            # Vista global de préstamos + devolución
    ├── reports/
    │   ├── data/
    │   │   └── pdf_report_service.dart    # Servicio de generación de PDFs
    │   └── presentation/
    │       └── reports_page.dart          # Estadísticas con cronograma y distribuciones
    ├── settings/
    │   └── presentation/
    │       ├── settings_page.dart         # Configuración: perfil, dashboards, Supabase
    │       └── widgets/
    │           └── avatar_crop_dialog.dart # Diálogo de recorte de avatar
    ├── shipments/
    │   ├── data/
    │   │   └── shipment_providers.dart    # Providers y repositorio de envíos
    │   └── presentation/
    │       ├── shipment_form_page.dart     # Formulario de nuevo envío
    │       └── shipments_page.dart        # Vista kanban + tabla de envíos
    ├── tools/
    │   ├── data/
    │   │   ├── tool_catalog_providers.dart # Catálogos (categorías, fabricantes, proveedores, talleres, prestatarios)
    │   │   └── tool_detail_providers.dart  # ToolDetailRecord + modelos anidados
    │   └── presentation/
    │       ├── tool_detail_page.dart       # Ficha técnica completa
    │       ├── tool_form_page.dart         # Formulario crear/editar herramienta
    │       └── tools_inventory_page.dart   # Inventario con cards, filtros, paginación
    └── users/
        ├── data/
        │   └── user_management_providers.dart # Provider gestión de usuarios
        └── presentation/
            └── users_admin_page.dart       # Admin de usuarios (listar, editar rol, baja)
```

---

## 4. Módulos principales

### 4.1 Auth

Módulo de autenticación con Supabase Auth.

**Implementado:**
- Login con correo y contraseña en `/login`
- Reset de contraseña en `/reset-password`
- Protección de rutas con `GoRouter` + `AuthRefreshListenable`
- Cierre de sesión desde topbar
- Perfil de usuario con foto/avatar, nombre, apellido, teléfono, país
- Roles: `lider`, `administrador`, `usuario`
- Creación automática de perfil en tabla `profiles` al registrarse en Auth
- Subida de avatar con recorte (image_picker + crop dialog) a bucket `avatars`

**Archivos:** `auth_providers.dart`, `auth_refresh_listenable.dart`, `auth_repository.dart`, `user_profile.dart`, `user_role.dart`, `login_page.dart`, `reset_password_page.dart`

### 4.2 Dashboard

Panel ejecutivo con indicadores en tiempo real desde Supabase.

**Implementado:**
- KPIs: total inventario, vigentes, acción requerida, en calibración, préstamos activos
- Barras de cumplimiento por estado (vigentes, próximos, vencidos, en calibración)
- Tabla de próximos vencimientos (6 herramientas más urgentes) con navegación a ficha
- Actividad reciente (calibraciones + envíos ordenados por fecha)
- Acciones rápidas: nueva herramienta, nuevo envío, cuarentena
- Exportación PDF de estado general

**Provider:** `dashboardSnapshotProvider` consulta `tools` con `calibrations` y `calibration_shipments` anidados. Calcula `ComplianceState` por herramienta, `healthScore` global, `actionRequired`, `expiringSoon` (próximos 30 días).

**Archivos:** `dashboard_providers.dart`, `dashboard_page.dart`, `kpi_card.dart`

### 4.3 Tools (Inventario)

Módulo central de gestión de herramientas y equipos.

**Implementado:**
- **Vista principal** (`/tools`): cards con código, fabricante, ubicación, vencimiento, estado. Búsqueda textual multilínea. Filtros por estado (todos, vigentes, críticos, en calibración). Paginación de 15 items.
- **Vista retirados** (`/tools/retired`): herramientas dadas de baja con trazabilidad conservada.
- **Vista cuarentena** (`/tools/quarantine`): herramientas vencidas o con causa de cuarentena (NO_CONFORME, IRREPARABLE, INOPERATIVA, NO_CALIBRABLE).
- **Crear** (`/tools/new`): formulario con datos generales, técnicos, fabricante/categoría/ubicación, foto, manual técnico, certificado de fabricante.
- **Editar** (`/tools/:id/edit`): carga datos actuales, permite modificar y guardar.
- **Baja lógica**: confirmación con motivo y texto "DAR DE BAJA". Cambia estado a `BAJA`, ubicación a `ALMACEN DE BAJAS`, registra trazabilidad.
- **Préstamo rápido**: desde la card del inventario se puede generar un vale de préstamo.

**Archivos:** `tool_catalog_providers.dart`, `tool_detail_providers.dart`, `tools_inventory_page.dart`, `tool_form_page.dart`, `tool_detail_page.dart`

### 4.4 Tool Detail (Ficha técnica)

Pantalla de detalle completa en `/tools/:id`.

**Secciones:**
1. **TopBar**: volver, nombre, código interno, editar, menú contextual (calibrar, exportar PDF, imprimir QR, imprimir vale, dar de baja)
2. **Identity Card**: foto de la herramienta, specs (serie, código, parte, ubicación, fabricante, modelo, categoría, fecha alta), health ring con % y días, compliance badge
3. **Manual técnico**: descarga vía signed URL o subida de archivo
4. **QR Code**: visualización del código + botón imprimir etiqueta QR
5. **Action Grid**: acciones rápidas contextuales (registrar calibración, enviar, exportar PDF, imprimir QR, dar de baja)
6. **Última calibración**: resultado (CONFORME/CONDICIONADO/NO_CONFORME), fecha, proveedor, certificado, vencimiento. Botón abrir certificado PDF (signed URL). Modal de historial completo.
7. **Préstamo activo**: responsable, taller, fechas, barra de progreso. Botones vale PDF y devolver. Si no hay préstamo, botón generar préstamo.
8. **Informes técnicos**: documentos tipo INOPERATIVIDAD, NO_CONFORME, INFORME_CALIBRADOR. Botón adjuntar.
9. **Trazabilidad completa**: timeline visual con todos los eventos (alta, calibraciones, préstamos, envíos, baja, cuarentena). Cada evento con icono, color, documento adjunto descargable.

**Modelos anidados:** `ToolDetailRecord`, `ToolCalibrationRecord`, `ToolShipmentRecord`, `ToolDocumentRecord`, `ToolLoanRecord`, `ToolTraceabilityRecord`

**Archivos:** `tool_detail_page.dart` (~2000 líneas), `tool_detail_providers.dart`

### 4.5 Calibrations

Registro funcional de calibraciones desde la ficha técnica.

**Implementado:**
- Formulario en `/tools/:id/calibrations/new`
- Datos metrológicos: fecha de calibración, vigencia en meses, vencimiento automático, resultado
- Proveedor y certificado: selección de proveedor, centro/laboratorio, número de certificado, carga de PDF (bucket `calibration-certificates`)
- Si resultado es NO_CONFORME: cuarentena obligatoria con causa y notas
- Observaciones generales
- Al guardar: inserta en `calibrations`, crea registro en `tool_documents`, crea evento en `tool_traceability`, refresca ficha y dashboard

**Archivos:** `calibration_repository.dart`, `calibration_form_page.dart`, `calibration_history_widget.dart`

### 4.6 Shipments (Envíos)

Control de herramientas enviadas a centros de calibración.

**Implementado:**
- **Vista principal** (`/shipments`):
  - KPIs: abiertos, retornados, vencidos, total
  - Kanban por estado: ENVIADO, RECIBIDO_POR_PROVEEDOR, EN_PROCESO, LISTO_PARA_RECOJO
  - Tabla completa con tool, proveedor, fechas, status badge, menú de actualización de estado
- **Formulario** (`/shipments/new`): selección de herramienta, centro, proveedor, fecha envío, fecha retorno estimada, guía de remisión, observaciones
- **Actualización de estado**: popup menu en tabla permite avanzar: Recibido → En proceso → Listo para recojo → Retornado
- **Retorno**: al marcar RETORNADO, actualiza `actual_return_date`, cambia estado de herramienta a DISPONIBLE, ubicación a ALMACEN, crea trazabilidad

**Estados de envío:** `ENVIADO`, `RECIBIDO_POR_PROVEEDOR`, `EN_PROCESO`, `LISTO_PARA_RECOJO`, `RETORNADO`, `OBSERVADO`

**Archivos:** `shipment_providers.dart`, `shipments_page.dart`, `shipment_form_page.dart`

### 4.7 Loans (Préstamos)

Control global de herramientas prestadas.

**Implementado:**
- Vista global en `/loans` con filtros: todos, activos, vencidos, devueltos
- Cards con tool, prestatario, taller, fechas, barra de progreso, status badge
- Navegación a ficha técnica
- Devolución con observaciones

**Archivos:** `loans_providers.dart`, `loans_page.dart`

### 4.8 Reports (Estadísticas)

Vista de análisis y consultas en `/reports`.

**Implementado:**
- Summary strip con 7 métricas: total, vigentes, vencidos, en calibración, bajas, envíos activos, con certificado
- Cronograma de vencimientos por mes: pills horizontales con mes, total, dots de criticidad. Detalle del mes seleccionado con lista de herramientas ordenadas por urgencia.
- Distribución por categoría: barras con % vigentes
- Distribución por ubicación: barras con totales
- Exportación PDF de estado general

**Servicio PDF:**
- `printGeneralStatus()`: reporte A4 con métricas y tabla completa de herramientas
- `printToolStatus()`: ficha individual con datos técnicos e historial de calibraciones
- `printToolQrLabel()`: etiqueta QR 90×55mm con código, datos y QR
- `printLoanVoucher()`: vale de préstamo A4 con datos, QR y firmas

**Archivos:** `pdf_report_service.dart`, `reports_page.dart`

### 4.9 Users (Administración)

Gestión de usuarios del sistema en `/users`.

**Implementado:**
- Listado de perfiles registrados con rol, estado activo, fecha creación
- Editar: nombre visible, rol, estado activo
- Dar de baja lógica (`active = false`), no elimina cuenta Auth
- Solo visible para roles con permisos de administración

**Archivos:** `user_management_providers.dart`, `users_admin_page.dart`

### 4.10 Settings (Configuración)

Centro de configuración en `/settings`.

**Implementado:**
- **Perfil de usuario**: foto/avatar con recorte, nombre, apellidos, correo (read-only), país, celular. Guarda en `profiles` y sube avatar a bucket `avatars`.
- **Preferencias**: tema visual (clásico, claro, oscuro) e idioma (español, inglés) desde topbar. Persistidos en SharedPreferences.
- **Estado Supabase**: tarjeta con proyecto, URL, anon key, estado (Listo/Pendiente/Error)

**Archivos:** `settings_page.dart`, `avatar_crop_dialog.dart`

### 4.11 Alertas y Notificaciones

El sistema de alertas está integrado en dos componentes principales:

**Dashboard como panel central de alertas:**
- KPI "Acción requerida" (warning + expired) con color dinámico
- Tabla de próximos vencimientos (6 más urgentes)
- Barras de cumplimiento por estado con colores

**Campana de notificaciones (topbar):**
- Badge con color según severidad máxima: rojo (vencidos), naranja (críticos ≤15d), amarillo (alertas leves)
- Contador de alertas no leídas
- Al hacer clic, despliega el **Centro de Alertas** con:
  - Todas las alertas activas, ordenadas por criticidad
  - Resumen por severidad (chips: X vencidas, X urgentes, X avisos)
  - Solo muestra no leídas (las leídas desaparecen)
  - Navegación directa a la ficha técnica de la herramienta
  - Botón "Marcar todo como leído"
  - Auto-limpieza de notificaciones obsoletas (si una herramienta se recalibra, su alerta anterior se elimina automáticamente del store)

**Tipos de alerta detectados:**

| Tipo | Condición | Severidad | Icono |
|------|-----------|-----------|-------|
| Calibración vencida | `expired` | 3 (rojo) | error_outline |
| Vence en X días | `warning` (≤15d) | 2 (naranja) | warning_amber |
| Próximo a vencer | `grace` (16-30d) | 1 (amarillo) | notifications |
| Préstamo vencido | `loan.isOverdue` | 2 (naranja) | assignment_late |
| Sin calibración | `withoutCalibration` | 1 (amarillo) | help_outline |
| Certificado pendiente | calibración sin PDF | 0 (gris) | picture_as_pdf |

**Persistencia:**
- El estado "leído" se guarda en SharedPreferences por usuario
- Las entradas leídas se eliminan automáticamente cuando la alerta deja de estar activa
- Si una herramienta cambia de estado (ej. se calibró), su notificación anterior desaparece

**Archivos:** `app_topbar.dart` (campana + modal + lógica de alertas), `notification_read_store.dart`

---

## 5. Rutas

```
/                                           → redirige a /dashboard
/login                                      → LoginPage
/reset-password                             → ResetPasswordPage
/dashboard                                  → DashboardPage
/tools                                      → ToolsInventoryPage
/tools/new                                  → ToolFormPage (crear)
/tools/retired                              → ToolsInventoryPage (showRetired: true)
/tools/quarantine                           → ToolsInventoryPage (showQuarantine: true)
/tools/:id                                  → ToolDetailPage
/tools/:id/edit                             → ToolFormPage (editar)
/tools/:id/calibrations/new                 → CalibrationFormPage
/shipments                                  → ShipmentsPage
/shipments/new                              → ShipmentFormPage
/loans                                      → LoansPage
/reports                                    → ReportsPage
/users                                      → UsersAdminPage
/settings                                   → SettingsPage
```

Rutas protegidas: si no hay sesión activa, redirigen a `/login`. Si hay sesión, `/login` redirige a `/dashboard`.

---

## 6. Modelo de base de datos

### Tablas públicas (7)

| Tabla | Descripción |
|-------|-------------|
| `profiles` | Perfiles de usuario vinculados a `auth.users` |
| `tools` | Herramientas/equipos registrados |
| `calibrations` | Registros de calibración |
| `calibration_shipments` | Envíos a centro de calibración |
| `calibration_providers` | Proveedores/laboratorios de calibración |
| `categories` | Categorías de herramientas |
| `manufacturers` | Fabricantes |
| `locations` | Ubicaciones físicas |
| `workshops` | Talleres/oficinas para préstamos |
| `borrowers` | Personas que reciben herramientas en préstamo |
| `tool_documents` | Documentos asociados a herramientas |
| `tool_loans` | Préstamos de herramientas |
| `tool_traceability` | Trazabilidad de eventos por herramienta |

### Tipos enumerados

- `app_role`: `lider`, `administrador`, `usuario`
- `physical_status`: `DISPONIBLE`, `EN_USO`, `EN_CALIBRACION`, `BAJA`
- `calibration_result`: `CONFORME`, `CONDICIONADO`, `NO_CONFORME`
- `shipment_status`: `PENDIENTE_ENVIO`, `ENVIADO`, `RECIBIDO_POR_PROVEEDOR`, `EN_PROCESO`, `LISTO_PARA_RECOJO`, `RETORNADO`, `OBSERVADO`
- `trace_type`: `CALIBRACION`, `PRESTAMO`, `DEVOLUCION`, `BAJA`, `CUARENTENA`, `ENVIO_CALIBRACION`, `RETORNO_CALIBRACION`, `FABRICANTE`
- `document_type`: `CERTIFICADO`, `GUIA_REMISION`, `INOPERATIVIDAD`, `NO_CONFORME`, `INFORME_CALIBRADOR`, `FABRICANTE`, `MANUAL`, `FOTO`

### Buckets Storage (4)

| Bucket | Uso | Visibilidad |
|--------|-----|-------------|
| `calibration-certificates` | Certificados PDF de calibración | Privado (signed URLs) |
| `remission-guides` | Guías de remisión | Privado |
| `tool-images` | Fotos de herramientas | Público |
| `support-documents` | Documentos complementarios | Privado |

### Políticas RLS

- 26 policies públicas en tablas
- 4 policies de Storage
- Usuarios autenticados pueden leer
- `lider` y `administrador` pueden escribir
- `usuario` solo lectura

### Migraciones

```
supabase/migrations/20260430030000_phase_03_initial_schema_auth_roles_storage.sql
supabase/migrations/20260501044500_phase_03_advisor_fixes.sql
supabase/migrations/20260502060249_phase_04_profile_tool_traceability.sql
supabase/migrations/20260502060424_phase_04_advisor_fixes.sql
supabase/migrations/20260502175145_phase_05_functional_catalogs_qr_loans.sql
supabase/migrations/20260502180513_phase_05_advisor_fixes.sql
supabase/migrations/20260503010000_phase_07_inventory_retirement_codes_shipments.sql
supabase/migrations/20260503020000_phase_08_quarantine_dashboard.sql
```

---

## 7. Reglas de negocio

### Cálculo de vencimiento
- `expiration_date = calibration_date + validity_months` meses
- Se calcula automáticamente en el formulario de calibración

### Días restantes
- `daysToExpiration = expirationDate - fecha actual` (solo fecha, sin hora)
- Si no hay calibración, es `null` → estado `withoutCalibration`

### Estado de calibración (`ComplianceState`)

| Estado | Condición |
|--------|-----------|
| `compliant` | `daysToExpiration > 30` |
| `grace` | `16 <= daysToExpiration <= 30` |
| `warning` | `0 <= daysToExpiration <= 15` |
| `expired` | `daysToExpiration < 0` |
| `inCalibration` | `currentStatus == 'EN_CALIBRACION'` o `activeShipment != null` |
| `withoutCalibration` | Sin calibración registrada |

### Cuarentena
- Una herramienta entra en cuarentena si: `hasQuarantineReason == true` o `daysToExpiration < 0`
- Causas: `NO_CONFORME`, `IRREPARABLE`, `INOPERATIVA`, `NO_CALIBRABLE`
- Se asigna automáticamente al registrar calibración con resultado `NO_CONFORME`

### Baja lógica
- Cambia `current_status` a `BAJA` y `current_location` a `ALMACEN DE BAJAS`
- Registra `retired_at`, `retirement_reason`, `retired_by`
- Crea trazabilidad tipo `BAJA`
- No se elimina físicamente el registro

### Préstamos
- Al crear préstamo: cambia estado de herramienta a `EN_USO`, ubicación al taller
- Al devolver: cambia estado a `DISPONIBLE`, ubicación a `ALMACEN`
- Genera vale QR (`qr_payload`) y trazabilidad

### Envíos a calibración
- Al crear envío: cambia estado de herramienta a `EN_CALIBRACION`, ubicación al centro
- Al retornar: cambia estado a `DISPONIBLE`, ubicación a `ALMACEN`
- Crea trazabilidad de envío y retorno

### Health score
- `healthScore = (compliant + grace) / totalTools * 100`
- Individual: `(daysToExpiration / 365 * 100).clamp(12, 100)`

---

## 8. Sistema de alertas

### Estados visuales

| Estado | Color | Criterio | Acción recomendada |
|--------|-------|----------|-------------------|
| VIGENTE | Verde | `daysToExpiration > 30` | Mantener seguimiento |
| ALERTA | Amarillo | `16 <= daysToExpiration <= 30` | Planificar envío |
| CRÍTICO | Naranja | `0 <= daysToExpiration <= 15` | Priorizar envío |
| VENCIDO | Rojo | `daysToExpiration < 0` | Retirar de uso |
| EN CALIBRACIÓN | Azul | Envío activo | Dar seguimiento |
| SIN CALIBRAR | Gris | Sin calibración | Regularizar |

### Visualización de alertas
- **Dashboard**: KPI "Acción requerida" (warning + expired), tabla de próximos vencimientos
- **Inventario**: pills de filtro por estado con contadores, bordes coloreados en cards
- **Cuarentena**: vista dedicada (`/tools/quarantine`) para herramientas vencidas o no conformes
- **Campana de notificaciones**: badge con color según severidad, modal con lista priorizada solo de no leídas, auto-limpieza de leídas obsoletas
- **Badges de color**: en todas las cards y fichas técnicas

### Campana de notificaciones (detalle)
- Fuentes: herramientas (`expired`, `warning`, `grace`, `withoutCalibration`, sin certificado) + préstamos vencidos
- Persistencia: SharedPreferences por usuario. Las entradas se limpian automáticamente cuando la alerta deja de existir
- Colores del badge: rojo (severidad 3), naranja (2), amarillo (0-1)

---

## 9. Flujo de carga de archivos

### Certificados de calibración
- Bucket: `calibration-certificates` (privado)
- Formato: PDF
- Se cargan al registrar una calibración
- Se acceden mediante signed URL (300s de validez)
- Se registran también en `tool_documents` tipo `CERTIFICADO`

### Guías de remisión
- Bucket: `remission-guides` (privado)
- Formatos: PDF, JPG, JPEG, PNG
- Se cargan al registrar un envío desde el formulario de envío

### Fotos de herramientas
- Bucket: `tool-images` (público)
- Formatos: JPG, JPEG, PNG
- Se cargan al crear/editar herramienta
- Se accede mediante URL pública

### Avatares de perfil
- Bucket: `avatars` (privado)
- Formato: PNG (recortado)
- Se cargan desde Settings → Perfil

### Manuales técnicos y documentos
- Bucket: `support-documents` (privado)
- Formatos: PDF
- Se cargan desde la ficha técnica (botón "Subir manual" e "Informes técnicos → Adjuntar")
- Los informes permiten elegir tipo (`INFORME_CALIBRADOR`, `INOPERATIVIDAD`, `NO_CONFORME`) y título

### Resolución de bucket por tipo de documento

La función `_bucketForDocumentType()` en `tool_detail_page.dart` mapea el tipo de documento al bucket correcto al abrir archivos con `_openFile()`:

| `documentType`        | Bucket                     | Visibilidad |
|-----------------------|----------------------------|-------------|
| `CERTIFICADO`         | `calibration-certificates` | Privado     |
| `GUIA_REMISION`       | `remission-guides`         | Privado     |
| `FOTO`                | `tool-images`              | Público     |
| `MANUAL`              | `support-documents`        | Privado     |
| `FABRICANTE`          | `support-documents`        | Privado     |
| `INOPERATIVIDAD`      | `support-documents`        | Privado     |
| `NO_CONFORME`         | `support-documents`        | Privado     |
| `INFORME_CALIBRADOR`  | `support-documents`        | Privado     |

Los eventos de trazabilidad (`trace_type`) se mapean mediante `_documentTypeForTraceType()`:
- `CALIBRACION` → `CERTIFICADO` → `calibration-certificates`
- `FABRICANTE` → `FABRICANTE` → `support-documents`
- Otros → `null` → fallback a `support-documents`

---

## 10. Autenticación

### Implementado
- Login con email/contraseña (Supabase Auth)
- Logout desde topbar
- Protección de rutas con `GoRouter.redirect()`
- `AuthRefreshListenable` notifica cambios de sesión al router
- Tabla `profiles` vinculada a `auth.users` por trigger
- Roles cargados desde `profiles.role`
- Reset de contraseña vía Supabase Auth

### Permisos por rol

| Acción | lider | administrador | usuario |
|--------|-------|---------------|---------|
| Ver dashboard | ✅ | ✅ | ✅ |
| Ver inventario | ✅ | ✅ | ✅ |
| Crear/editar herramienta | ✅ | ✅ | ❌ |
| Dar de baja | ✅ | ✅ | ❌ |
| Registrar calibración | ✅ | ✅ | ❌ |
| Gestionar envíos | ✅ | ✅ | ❌ |
| Gestionar préstamos | ✅ | ✅ | ❌ |
| Administrar usuarios | ✅ | ❌ | ❌ |
| Ver configuración | ✅ | ✅ | ✅ |

### Pendiente
- Interfaz para crear usuarios desde la UI (actualmente solo vía Supabase Dashboard o edge function)

---

## 11. Variables de entorno

La app recibe configuración Supabase por `--dart-define`:

```
SUPABASE_URL
SUPABASE_ANON_KEY
```

Archivos relacionados:
- `lib/core/config/app_config.dart`: lectura de variables
- `lib/core/config/supabase_config.dart`: inicialización y estado runtime
- `lib/core/config/supabase_providers.dart`: providers Riverpod

Estados posibles:
- `notConfigured`: faltan variables
- `ready`: cliente inicializado correctamente
- `failed`: error al inicializar

---

## 12. Instalación local

```bash
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Para compilar web:

```bash
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## 13. Despliegue

Pendiente de definir. Comando base previsto:

```bash
flutter build web
```

El output se genera en `build/web/`.

---

## 14. Historial de cambios

| Fecha | Cambio | Archivos modificados | Motivo | Impacto |
|-------|--------|---------------------|--------|---------|
| 30/04/2026 | Fase 1: Proyecto Flutter base, tema, rutas, layout, pantallas placeholder | `lib/`, `docs/`, `web/`, `pubspec.yaml` | Iniciar base técnica | App navegable |
| 30/04/2026 | Fase 2: Configuración Supabase por `--dart-define`, estado runtime | `lib/core/config/`, `lib/features/settings/` | Conexión segura con Supabase | App lista para Supabase |
| 30/04/2026 | Fase 3: Migración SQL inicial, login protegido, RLS, Storage | `supabase/migrations/`, `lib/features/auth/`, `lib/core/config/app_router.dart` | Backend inicial | Tablas, policies, buckets creados |
| 01/05/2026 | Aplicación migraciones en Supabase remoto + datos semilla | Supabase remoto | Backend funcional | 12 tools, 11 cals, 3 shipments, 1 Lider |
| 02/05/2026 | Fase 4-5-6: Modelos, repositorios, inventario conectado, calibraciones funcionales | `lib/features/tools/`, `lib/features/calibrations/`, `lib/features/dashboard/` | Capa de datos + funcionalidad core | Inventario y calibraciones operativos |
| 02/05/2026 | Fase 6+: QR, préstamos, catálogos, trazabilidad, documentos | `lib/features/tools/`, `lib/features/loans/` | Funcionalidad extendida | QR, préstamos y trazabilidad |
| 03/05/2026 | Fase 7-8: Envíos completos, cuarentena, dashboard real, retiros | `lib/features/shipments/`, `lib/features/dashboard/` | Completar módulos operativos | Kanban de envíos, dashboard con datos reales |
| 03/05/2026 | Fase 9-10: Dashboard KPIs reales, reportes/estadísticas, PDFs | `lib/features/reports/`, `lib/features/dashboard/` | Panel ejecutivo + reportes | KPIs, cronograma, distribuciones, PDF |
| 03/05/2026 | Perfil de usuario, avatar, preferencias, i18n | `lib/features/settings/`, `lib/core/preferences/`, `lib/core/i18n/` | Experiencia de usuario | Foto, tema, idioma |
| 16/05/2026 | Actualización completa de PROJECT_MANUAL.md | `docs/PROJECT_MANUAL.md` | Reflejar estado real (Fase 10+) | Documentación al día |
| 16/05/2026 | Corrección bug `_openFile`: bucket hardcodeado → resolución por tipo de documento | `lib/features/tools/presentation/tool_detail_page.dart` | Archivos no abrían al estar en buckets distintos a `calibration-certificates` | Manuales, informes y trazabilidad ahora abren desde el bucket correcto |
| 16/05/2026 | Unificación devolución en `loans_page.dart`: query directa → `ToolMutationRepository.returnLoanById()` | `lib/features/loans/presentation/loans_page.dart`, `lib/features/tools/data/tool_catalog_providers.dart` | La devolución desde préstamos solo cerraba el préstamo sin restaurar la herramienta ni registrar trazabilidad | Devolución completa: cierra préstamo, restaura herramienta a DISPONIBLE, crea trazabilidad |
| 16/05/2026 | Edición y anulación de calibraciones con trazabilidad | `lib/features/calibrations/`, `lib/features/tools/`, `lib/features/dashboard/`, `lib/core/`, `supabase/migrations/` | Las calibraciones eran inmutables una vez registradas | Editar calibración existente, anular con motivo, trazabilidad completa, filtrado en dashboard |
| 16/05/2026 | Subida de manual técnico e informes técnicos | `lib/features/tools/data/tool_catalog_providers.dart`, `lib/features/tools/presentation/tool_detail_page.dart` | Botones TODO sin funcionalidad en ficha técnica | Manual técnico: picker PDF → `support-documents`. Informes: diálogo con tipo/título → `tool_documents`. Ambos con feedback visual |
| 16/05/2026 | Carga de guía de remisión en formulario de envío | `lib/features/shipments/data/shipment_providers.dart`, `lib/features/shipments/presentation/shipment_form_page.dart` | El formulario solo aceptaba número de guía sin archivo adjunto | Picker de PDF/JPG/PNG, subida al bucket `remission-guides`, guardado en `remission_guide_file_url` |

---

## 15. Pendientes

### Alta prioridad
1. ✅ ~~Actualizar USER_INSTRUCTION_MANUAL.md~~ → Completado en v2.0 (16/05/2026). Sección 16 documenta el sistema de alertas y notificaciones.
2. ✅ ~~Bug `_openFile`~~ → Corregido 16/05/2026. Ahora resuelve el bucket según `documentType` (CERTIFICADO → `calibration-certificates`, MANUAL/FABRICANTE/INFORMES → `support-documents`, etc.)

### Media prioridad
4. ✅ ~~Unificar devolución en `loans_page.dart`~~ → Corregido 16/05/2026. Ahora usa `ToolMutationRepository.returnLoanById()` que cierra el préstamo, restaura herramienta a DISPONIBLE y registra trazabilidad.
5. ✅ ~~Edición/eliminación de calibraciones~~ → Completado 16/05/2026. Formulario de edición, anulación con motivo, trazabilidad de ambas operaciones, calibraciones anuladas ignoradas en dashboard.
6. ✅ ~~Subida de manual técnico~~ → Completado 16/05/2026. Picker PDF, subida a `support-documents`, actualización de `tools.data_sheet_url`, feedback visual con spinner.
7. ✅ ~~Subida de informes técnicos~~ → Completado 16/05/2026. Diálogo para tipo (INFORME_CALIBRADOR/INOPERATIVIDAD/NO_CONFORME) y título, subida a `support-documents`, registro en `tool_documents`.
8. ✅ ~~Carga de guía de remisión~~ → Completado 16/05/2026. Picker de archivo (PDF/JPG/PNG) en formulario de envío, subida a bucket `remission-guides`, persistencia en `remission_guide_file_url`.

### Baja prioridad
9. **Despliegue web**: definir hosting y proceso.
10. **Creación de usuarios desde UI**: edge function o panel seguro.
