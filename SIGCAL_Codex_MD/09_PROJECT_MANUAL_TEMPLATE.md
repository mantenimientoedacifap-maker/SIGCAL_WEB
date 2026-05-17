# 09 — Plantilla PROJECT_MANUAL.md

Codex debe crear este archivo en:

```txt
docs/PROJECT_MANUAL.md
```

El contenido inicial debe tener la siguiente estructura:

---

# SIGCAL — Manual Técnico y Funcional

## 1. Descripción general

SIGCAL es una aplicación web desarrollada en Flutter con backend Supabase para controlar la calibración de herramientas especiales, equipos electrónicos, instrumentos de medición y otros equipos sujetos a calibración.

## 2. Stack utilizado

- Flutter.
- Supabase.
- Supabase PostgreSQL.
- Supabase Auth.
- Supabase Storage.
- go_router.
- flutter_riverpod.
- intl.
- file_picker.
- image_picker.
- flutter_form_builder.
- form_builder_validators.
- data_table_2.
- fl_chart.
- url_launcher.

## 3. Estructura de carpetas

Documentar aquí la estructura real del proyecto.

## 4. Módulos principales

### 4.1 Auth

Descripción del módulo de autenticación.

### 4.2 Dashboard

Descripción del dashboard.

### 4.3 Tools

Descripción del inventario de herramientas/equipos.

### 4.4 Calibrations

Descripción del control de calibraciones.

### 4.5 Shipments

Descripción del control de envíos.

### 4.6 Alerts

Descripción del sistema de alertas.

### 4.7 Reports

Descripción del sistema de reportes.

### 4.8 Settings

Descripción de configuración y catálogos.

## 5. Rutas

Documentar rutas reales:

```txt
/
 /dashboard
 /tools
 /tools/:id
 /tools/new
 /tools/:id/edit
 /alerts
 /shipments
 /reports
 /settings
```

## 6. Modelo de base de datos

Documentar tablas:

- tools.
- calibrations.
- calibration_shipments.
- categories.
- manufacturers.
- locations.

## 7. Reglas de negocio

Documentar:

- Cálculo de vencimiento.
- Cálculo de días restantes.
- Estado de calibración.
- Estado físico.
- Estado de envío.
- Retorno de calibración.
- Baja lógica.

## 8. Sistema de alertas

Documentar rangos:

- Vigente.
- Alerta amarilla.
- Alerta naranja.
- Vencido.
- En calibración.
- Sin calibración.

## 9. Flujo de carga de archivos

Documentar:

- Certificados.
- Guías de remisión.
- Fotos.
- Documentos complementarios.
- Buckets Supabase.

## 10. Autenticación

Documentar:

- Login.
- Logout.
- Sesión.
- Usuarios.
- Políticas de acceso.

## 11. Variables de entorno

Documentar:

```txt
SUPABASE_URL
SUPABASE_ANON_KEY
```

## 12. Instalación local

Documentar comandos:

```bash
flutter pub get
flutter run -d chrome
```

## 13. Despliegue

Documentar proceso de despliegue web.

## 14. Historial de cambios

Cada cambio importante debe registrarse así:

```txt
Fecha:
Cambio:
Archivos modificados:
Motivo:
Impacto:
```

## 15. Pendientes

Registrar mejoras futuras.


---

# Manual adicional obligatorio

Además de este archivo, Codex debe crear y mantener actualizado:

```txt
docs/USER_INSTRUCTION_MANUAL.md
```

Ese archivo debe funcionar como Manual de Instrucción del Usuario e incluir:

- Portada.
- Control de cambios.
- Introducción.
- Alcance.
- Definiciones.
- Roles.
- Acceso al sistema.
- Descripción de interfaz.
- Procedimientos de uso.
- Registro de herramientas/equipos.
- Registro de calibraciones.
- Carga de certificados.
- Envíos a centro de calibración.
- Retorno de equipos.
- Alertas.
- Reportes.
- Búsqueda y filtros.
- Buenas prácticas.
- Errores frecuentes.
- Preguntas frecuentes.
- Anexos.
