# 13 — Estado Actual del Proyecto (Checkpoint entre sesiones)

**Última actualización:** 16/05/2026
**Última sesión activa:** 16/05/2026
**Último cambio:** Inventario modernizado, campana de notificaciones inteligente, cuarentena integrada en toolbar, RLS reparado, base de datos poblada, documentación actualizada

---

## Resumen de fases completadas

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1 | Proyecto Flutter base + tema + layout + rutas | ✅ |
| 2 | Configuración Supabase (`--dart-define`) | ✅ |
| 3 | DB (13 tablas), RLS, Storage (4 buckets), seeds | ✅ |
| 4 | Modelos Dart + repositorios + providers Riverpod | ✅ |
| 5 | Inventario (grid/lista moderno, toolbar, filtros, paginación) | ✅ |
| 6 | Calibraciones (formulario, vencimiento auto, certificado PDF) | ✅ |
| 7 | Envíos (KPIs, kanban, tabla, actualización de estado) | ✅ |
| 8 | Alertas integradas (dashboard + campana inteligente) | ✅ |
| 9 | Dashboard (KPIs reales, compliance, actividad, quick actions) | ✅ |
| 10 | Reportes/Estadísticas (cronograma, distribuciones, PDF) | ✅ |
| 11 | Mejora visual (inventario modernizado, cuarentena en toolbar) | ✅ |
| 12 | Documentación actualizada | ✅ |

---

## Cambios de la última sesión (16/05/2026)

### 1. Documentación actualizada
- `PROJECT_MANUAL.md` → refleja Fase 10+ con todos los módulos
- `USER_INSTRUCTION_MANUAL.md` → v2.0 con procedimientos completos
- `SIGCAL_Codex_MD/13_CURRENT_STATE.md` → este archivo

### 2. Base de datos reconstruida
- Schema limpiado y recreado con todas las migraciones
- 5 herramientas de prueba creadas
- Catálogos: 12 categorías, 8 fabricantes, 2 proveedores, 2 talleres, 2 prestatarios
- **Usuario:** `lider@sigcal.com` / `S1gecal2026` (rol: lider)

### 3. RLS reparado
- Políticas SELECT/INSERT/UPDATE/DELETE para `authenticated` en todas las tablas
- Conexión directa `supabase db query` funcionando

### 4. Campana de notificaciones inteligente
- Detecta: vencidos, críticos (≤15d), alerta (16-30d), sin calibrar, sin certificado, préstamos vencidos
- Badge con color por severidad: rojo/naranja/amarillo
- Modal solo muestra **no leídas** (lo visto desaparece)
- Auto-limpieza de entradas obsoletas
- Archivos: `app_topbar.dart`, `notification_read_store.dart`

### 5. Inventario modernizado
- Vista **Grid** (1-4 columnas adaptativas) con cards compactas
- Vista **Lista** con filas densas
- Toggle Grid/Lista guardado en SharedPreferences
- Toolbar unificada: buscador + chips de filtro + botón cuarentena + toggle + nuevo
- Eliminados: paginación numérica antigua, cards con bordes laterales
- Archivo: `tools_inventory_page.dart` (reescrito completo)

### 6. Botón de Cuarentena en toolbar
- Ícono ⚠️ con badge numérico, visible solo en inventario principal
- Navega a vista de cuarentena existente (`/tools/quarantine`)
- Lógica `isInQuarantine` corregida: ahora incluye herramientas **sin calibrar**
- Archivos: `tools_inventory_page.dart`, `dashboard_providers.dart`, `tool_detail_providers.dart`

### 7. Credenciales guardadas
- `.env` con: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_PASSWORD`
- `run.sh` para ejecutar con hot reload automático
- `.env` y `run.sh` en `.gitignore`

---

## Cómo ejecutar el proyecto

```bash
cd "/Users/franciscobances1997/Documents/C&E_TC"
./run.sh
```

Login: `lider@sigcal.com` / `S1gecal2026`

Hot reload: `r` | Hot restart: `R` | Salir: `q`

---

## Procedimiento de capturas de pantalla

Cuando encuentres un error visual o necesites mostrarme algo:
1. Toma la captura (Cmd+Shift+4)
2. Guárdala en: `~/Desktop/capturas_deepcode/`
3. Dime "revisa la captura en capturas_deepcode"
4. Yo la leo con mi herramienta Read y veo exactamente lo que ves

---

## Estructura de archivos (actualizada)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── app_router.dart
│   │   ├── supabase_config.dart
│   │   └── supabase_providers.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_routes.dart
│   │   └── app_strings.dart
│   ├── i18n/
│   │   └── translations.dart
│   ├── notifications/
│   │   └── notification_read_store.dart    ← removeStale() agregado
│   ├── preferences/
│   │   └── app_preferences.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── calibration_status_utils.dart
│   │   ├── date_utils.dart
│   │   └── file_utils.dart
│   └── widgets/
│       ├── app_shell.dart
│       ├── app_sidebar.dart
│       ├── app_topbar.dart                ← campana reescrita
│       ├── empty_state.dart
│       ├── loading_view.dart
│       ├── page_header.dart
│       ├── route_loading_gate.dart
│       └── status_badge.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_providers.dart
    │   │   ├── auth_refresh_listenable.dart
    │   │   └── auth_repository.dart
    │   ├── domain/
    │   │   ├── user_profile.dart
    │   │   └── user_role.dart
    │   └── presentation/
    │       ├── login_page.dart
    │       └── reset_password_page.dart
    ├── calibrations/
    │   ├── data/
    │   │   └── calibration_repository.dart
    │   └── presentation/
    │       ├── calibration_form_page.dart
    │       └── calibration_history_widget.dart
    ├── dashboard/
    │   ├── data/
    │   │   └── dashboard_providers.dart    ← isInQuarantine corregido
    │   └── presentation/
    │       ├── dashboard_page.dart
    │       └── widgets/
    │           └── kpi_card.dart
    ├── loans/
    │   ├── data/
    │   │   └── loans_providers.dart
    │   └── presentation/
    │       └── loans_page.dart
    ├── reports/
    │   ├── data/
    │   │   └── pdf_report_service.dart
    │   └── presentation/
    │       └── reports_page.dart
    ├── settings/
    │   └── presentation/
    │       ├── settings_page.dart
    │       └── widgets/
    │           └── avatar_crop_dialog.dart
    ├── shipments/
    │   ├── data/
    │   │   └── shipment_providers.dart
    │   └── presentation/
    │       ├── shipment_form_page.dart
    │       └── shipments_page.dart
    ├── tools/
    │   ├── data/
    │   │   ├── tool_catalog_providers.dart
    │   │   └── tool_detail_providers.dart  ← isInQuarantine corregido
    │   └── presentation/
    │       ├── tool_detail_page.dart
    │       ├── tool_form_page.dart
    │       └── tools_inventory_page.dart   ← reescrito completo
    └── users/
        ├── data/
        │   └── user_management_providers.dart
        └── presentation/
            └── users_admin_page.dart
```

---

## Pendientes

### Media prioridad
1. **Bug `_openFile`** en `tool_detail_page.dart`: bucket hardcodeado. Debe detectar bucket correcto.
2. **Devolución en `loans_page.dart`**: usa query directa en vez de `ToolMutationRepository`.
3. **Subida de manual técnico e informes**: botones con TODO pendiente.
4. **Carga de guía de remisión** en formulario de envío.
