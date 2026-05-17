# 03 — Stack Técnico

## Frontend

### Flutter

La aplicación debe desarrollarse usando Flutter como frontend principal, priorizando salida web.

Flutter permitirá que el sistema pueda crecer posteriormente a:

- Web.
- Android.
- iOS.
- Windows.
- macOS.

## Backend

### Supabase

Supabase debe usarse para:

- Base de datos PostgreSQL.
- Autenticación.
- Storage de archivos.
- Políticas de seguridad.
- API automática.
- Posibles Edge Functions en fases futuras.

## Dependencias Flutter recomendadas

Agregar al `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  supabase_flutter: ^2.0.0
  go_router: ^14.0.0
  flutter_riverpod: ^2.5.0
  intl: ^0.19.0
  file_picker: ^8.0.0
  image_picker: ^1.1.0
  flutter_form_builder: ^9.0.0
  form_builder_validators: ^11.0.0
  data_table_2: ^2.5.0
  fl_chart: ^0.68.0
  url_launcher: ^6.3.0
  shared_preferences: ^2.2.0
```

Codex puede ajustar versiones si existe incompatibilidad, pero debe mantener el mismo propósito técnico.

## Uso de dependencias

| Dependencia | Uso |
|---|---|
| `supabase_flutter` | Conexión con Supabase, Auth, Database y Storage |
| `go_router` | Navegación declarativa |
| `flutter_riverpod` | Gestión de estado |
| `intl` | Fechas y formato local |
| `file_picker` | Cargar PDF, certificados, guías |
| `image_picker` | Cargar imágenes en móvil |
| `flutter_form_builder` | Formularios estructurados |
| `form_builder_validators` | Validaciones |
| `data_table_2` | Tablas avanzadas |
| `fl_chart` | Gráficos del dashboard |
| `url_launcher` | Abrir certificados/guías |
| `shared_preferences` | Preferencias locales simples |

## Variables de entorno

La app debe usar variables de entorno o archivo de configuración seguro para:

```txt
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

Debe crearse un archivo de ejemplo:

```txt
.env.example
```

O el equivalente recomendado por Flutter para configuración segura.

## Seguridad

No colocar claves sensibles directamente en archivos públicos.

La `anon key` de Supabase puede usarse en cliente, pero debe estar protegida mediante:

- Row Level Security.
- Políticas RLS.
- Validaciones de acceso.
- Separación de permisos.
