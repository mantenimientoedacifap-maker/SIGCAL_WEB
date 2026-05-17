# 04 — Arquitectura Flutter

## Principio arquitectónico

La app debe estar organizada por módulos funcionales usando una estructura clara y escalable.

## Estructura obligatoria

```txt
lib/
  main.dart
  app.dart

  core/
    config/
      app_config.dart
      supabase_config.dart

    constants/
      app_colors.dart
      app_routes.dart
      app_strings.dart

    theme/
      app_theme.dart

    utils/
      date_utils.dart
      calibration_status_utils.dart
      file_utils.dart

    widgets/
      app_sidebar.dart
      app_topbar.dart
      status_badge.dart
      loading_view.dart
      empty_state.dart

  features/
    auth/
      data/
      domain/
      presentation/

    dashboard/
      data/
      domain/
      presentation/
        dashboard_page.dart
        widgets/

    tools/
      data/
        tools_repository.dart
      domain/
        tool_model.dart
      presentation/
        tools_inventory_page.dart
        tool_detail_page.dart
        tool_form_page.dart
        widgets/

    calibrations/
      data/
        calibrations_repository.dart
      domain/
        calibration_model.dart
      presentation/
        calibration_form_page.dart
        calibration_history_widget.dart

    shipments/
      data/
        shipments_repository.dart
      domain/
        shipment_model.dart
      presentation/
        shipments_page.dart
        shipment_form_page.dart

    alerts/
      data/
      domain/
      presentation/
        calibration_alerts_page.dart

    reports/
      data/
      domain/
      presentation/
        reports_page.dart

    settings/
      data/
      domain/
      presentation/
        settings_page.dart

  docs/
    PROJECT_MANUAL.md
```

## main.dart

Debe inicializar:

- Flutter bindings.
- Supabase.
- ProviderScope de Riverpod.
- App principal.

## app.dart

Debe contener:

- MaterialApp.router.
- Theme.
- Router principal.
- Configuración global.

## core/config

Configuraciones generales:

- URL de Supabase.
- Llaves públicas.
- Parámetros globales.
- Inicialización del cliente Supabase.

## core/constants

Constantes reutilizables:

- Colores.
- Rutas.
- Textos.
- Estados.
- Nombres de buckets.

## core/theme

Tema visual global:

- Colores.
- Tipografía.
- Inputs.
- Botones.
- Cards.
- DataTables.
- AppBar.
- Sidebar.

## core/utils

Utilidades:

- Cálculo de fecha de vencimiento.
- Cálculo de días restantes.
- Cálculo de estado de calibración.
- Formato de fechas.
- Validaciones de archivos.
- Utilidades para Storage.

## core/widgets

Widgets compartidos:

- Sidebar.
- Topbar.
- Badge de estado.
- Vista de carga.
- Vista vacía.
- Cards KPI.
- Botones base.

## features/tools

Módulo principal de inventario.

Debe contener:

- Modelo Tool.
- Repositorio de herramientas.
- Pantalla de inventario.
- Pantalla de detalle.
- Pantalla de formulario.
- Widgets específicos.

## features/calibrations

Módulo de calibraciones.

Debe contener:

- Modelo Calibration.
- Repositorio de calibraciones.
- Formulario de calibración.
- Widget de historial.

## features/shipments

Módulo de envíos a calibración.

Debe contener:

- Modelo Shipment.
- Repositorio de envíos.
- Pantalla de envíos.
- Formulario de envío.

## features/alerts

Módulo de alertas.

Debe contener:

- Pantalla de alertas.
- Filtros.
- Listados por estado.
- Alertas visuales.

## features/reports

Módulo de reportes.

Debe contener:

- Reportes filtrables.
- Resúmenes.
- Preparación para exportación futura.

## features/settings

Módulo de configuración.

Debe contener:

- Catálogos.
- Ubicaciones.
- Fabricantes.
- Categorías.
- Preferencias del sistema.
