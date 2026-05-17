# 12 — Manual de Instrucción y Registro de Cambios

Codex debe crear y mantener actualizado un manual adicional orientado al usuario final y al uso operativo del sistema.

Este manual debe crearse en:

```txt
docs/USER_INSTRUCTION_MANUAL.md
```

## Objetivo del manual

El `USER_INSTRUCTION_MANUAL.md` debe funcionar como manual de instrucción, operación y consulta para los usuarios de SIGCAL.

Debe explicar de forma clara cómo usar la aplicación, cómo registrar información, cómo interpretar alertas, cómo cargar documentos, cómo consultar reportes y cómo mantener trazabilidad de las calibraciones.

## Diferencia con PROJECT_MANUAL.md

La app debe mantener dos manuales separados:

| Archivo | Propósito |
|---|---|
| `docs/PROJECT_MANUAL.md` | Manual técnico y funcional para desarrolladores, mantenimiento del código, arquitectura y configuración |
| `docs/USER_INSTRUCTION_MANUAL.md` | Manual de instrucción para usuarios, operadores, supervisores y personal que usará el sistema |

## Requisito obligatorio

Cada vez que Codex implemente, modifique o elimine una funcionalidad que afecte el uso del sistema, debe actualizar también el `USER_INSTRUCTION_MANUAL.md`.

No basta con actualizar el manual técnico. Si el cambio modifica un flujo de usuario, pantalla, botón, formulario, reporte, alerta o proceso de carga documental, debe quedar explicado en el manual de instrucción.

---

# Estructura obligatoria del USER_INSTRUCTION_MANUAL.md

## 1. Portada

Debe incluir:

- Nombre del sistema: SIGCAL.
- Nombre completo: Sistema de Gestión de Calibración.
- Versión del manual.
- Fecha de actualización.
- Responsable o área usuaria, si se define posteriormente.

Ejemplo:

```txt
SIGCAL
Sistema de Gestión de Calibración
Manual de Instrucción del Usuario
Versión: 1.0
Fecha de actualización: DD/MM/AAAA
```

---

## 2. Control de cambios del manual

Debe registrar cada modificación importante.

Formato obligatorio:

| Versión | Fecha | Cambio realizado | Módulo afectado | Responsable |
|---|---|---|---|---|

Ejemplo:

| Versión | Fecha | Cambio realizado | Módulo afectado | Responsable |
|---|---|---|---|---|
| 1.0 | 30/04/2026 | Creación inicial del manual | General | Codex |

---

## 3. Introducción

Debe explicar:

- Qué es SIGCAL.
- Para qué sirve.
- Qué problema resuelve.
- Qué usuarios lo utilizarán.
- Qué información se controla.

---

## 4. Alcance del sistema

Debe indicar qué permite hacer el sistema:

- Registrar herramientas/equipos.
- Controlar calibraciones.
- Controlar vencimientos.
- Alertar con 30 días de anticipación.
- Registrar envíos a centros de calibración.
- Adjuntar certificados.
- Adjuntar guías de remisión.
- Consultar historial.
- Consultar reportes.

También debe indicar límites del sistema si aplica.

---

## 5. Definiciones y abreviaturas

Debe incluir términos importantes:

| Término | Definición |
|---|---|
| Calibración | Proceso de verificación y ajuste de un instrumento contra un patrón o referencia |
| Fecha de calibración | Fecha en que se realizó la calibración |
| Fecha de vencimiento | Fecha hasta la cual la calibración se considera vigente |
| Vigente | Equipo con calibración válida por más de 30 días |
| Próximo a vencer | Equipo cuya calibración vence dentro de los próximos 30 días |
| Vencido | Equipo cuya fecha de vencimiento ya fue superada |
| Centro de calibración | Laboratorio o proveedor que realiza la calibración |
| Guía de remisión | Documento que sustenta el traslado del equipo |
| Certificado de calibración | Documento que acredita el resultado de la calibración |

---

## 6. Roles de usuario

Documentar los roles cuando se implementen.

Roles iniciales sugeridos:

- Administrador.
- Supervisor.
- Técnico.
- Consulta.

Para cada rol se debe explicar:

- Qué puede ver.
- Qué puede registrar.
- Qué puede modificar.
- Qué no puede hacer.

---

## 7. Acceso al sistema

Debe explicar:

- Cómo ingresar.
- Cómo cerrar sesión.
- Qué hacer si no se puede acceder.
- Consideraciones de usuario y contraseña.

---

## 8. Descripción general de la interfaz

Debe explicar las partes principales de la app:

- Sidebar.
- Topbar.
- Dashboard.
- Inventario.
- Calibraciones.
- Envíos.
- Alertas.
- Reportes.
- Configuración.

Debe explicar el significado de colores, íconos y estados visuales.

---

## 9. Dashboard

Debe explicar:

- Qué información muestra.
- Cómo interpretar los KPI.
- Cómo interpretar los gráficos.
- Cómo revisar próximos vencimientos.
- Cómo revisar equipos vencidos.
- Cómo revisar equipos en calibración.

---

## 10. Inventario de herramientas/equipos

Debe explicar paso a paso:

### 10.1 Cómo registrar una herramienta/equipo

Incluir procedimiento:

1. Ingresar a Inventario.
2. Seleccionar Nuevo registro.
3. Completar datos generales.
4. Completar datos técnicos.
5. Seleccionar ubicación.
6. Guardar.

### 10.2 Cómo editar una herramienta/equipo

Incluir procedimiento:

1. Buscar el equipo.
2. Seleccionar Editar.
3. Modificar campos.
4. Guardar cambios.

### 10.3 Cómo consultar detalle

Incluir procedimiento:

1. Buscar el equipo.
2. Seleccionar Ver detalle.
3. Revisar datos técnicos, calibraciones, envíos y archivos.

### 10.4 Cómo dar de baja

Incluir procedimiento y advertencia:

- La baja debe usarse cuando el equipo ya no estará disponible.
- No debe eliminarse el historial.
- El estado debe cambiar a `BAJA`.

---

## 11. Registro de calibración

Debe explicar paso a paso:

1. Ingresar al detalle de la herramienta/equipo.
2. Seleccionar Registrar calibración.
3. Ingresar fecha de calibración.
4. Ingresar duración en meses.
5. Verificar fecha de vencimiento calculada.
6. Ingresar centro de calibración.
7. Ingresar número de certificado.
8. Adjuntar certificado.
9. Seleccionar resultado.
10. Guardar.

Debe explicar que la fecha de vencimiento se calcula automáticamente.

---

## 12. Carga de certificado de calibración

Debe explicar:

- Formatos permitidos.
- Peso máximo si se define.
- Dónde queda almacenado.
- Cómo abrirlo.
- Cómo reemplazarlo si aplica.
- Qué hacer si se cargó un archivo incorrecto.

Formatos iniciales permitidos:

- PDF.
- JPG.
- JPEG.
- PNG.

---

## 13. Envío a centro de calibración

Debe explicar paso a paso:

1. Buscar la herramienta/equipo.
2. Seleccionar Enviar a calibración.
3. Seleccionar o escribir centro de calibración.
4. Ingresar fecha de remisión.
5. Ingresar número de guía de remisión.
6. Adjuntar guía de remisión.
7. Ingresar fecha estimada de retorno.
8. Guardar.

Debe indicar que al registrar el envío:

- La ubicación cambia a Centro de calibración.
- El estado cambia a EN_CALIBRACION.
- El equipo aparece en la vista de envíos.

---

## 14. Retorno de equipo calibrado

Debe explicar paso a paso:

1. Ingresar a Envíos.
2. Buscar el equipo.
3. Seleccionar Registrar retorno.
4. Ingresar fecha real de retorno.
5. Cambiar estado del envío a Retornado.
6. Registrar nueva calibración.
7. Adjuntar certificado.
8. Actualizar ubicación actual.

---

## 15. Alertas de calibración

Debe explicar:

- Qué significa cada alerta.
- Cómo se calculan.
- Cómo priorizarlas.

### Estados visuales

| Estado | Criterio | Acción recomendada |
|---|---|---|
| Vigente | Vence en más de 30 días | Mantener seguimiento |
| Alerta amarilla | Faltan 16 a 30 días | Planificar envío |
| Alerta naranja | Faltan 1 a 15 días | Priorizar envío |
| Vencido | Fecha vencida | Retirar de uso y enviar a calibración |
| En calibración | Equipo enviado a proveedor | Realizar seguimiento |
| Sin calibración | Sin datos válidos | Regularizar información |

---

## 16. Reportes

Debe explicar:

- Cómo ingresar a Reportes.
- Cómo filtrar información.
- Qué reportes existen.
- Cómo interpretar los resultados.
- Cómo exportar cuando se implemente la función.

---

## 17. Búsqueda y filtros

Debe explicar:

- Cómo buscar por texto.
- Cómo filtrar por fabricante.
- Cómo filtrar por ubicación.
- Cómo filtrar por estado.
- Cómo filtrar por fecha de vencimiento.
- Cómo limpiar filtros.

---

## 18. Buenas prácticas de uso

Incluir recomendaciones:

- Registrar certificados inmediatamente después de recibirlos.
- No usar herramientas vencidas.
- Revisar alertas semanalmente.
- Verificar número de serie antes de registrar.
- Usar códigos internos únicos.
- Adjuntar documentos legibles.
- Mantener actualizada la ubicación.
- Cerrar envíos cuando el equipo retorne.
- No dar de baja sin autorización correspondiente.

---

## 19. Errores frecuentes y solución

Debe incluir una tabla:

| Problema | Posible causa | Solución |
|---|---|---|
| No puedo guardar un registro | Campos obligatorios incompletos | Revisar campos marcados |
| No carga el certificado | Formato no permitido | Usar PDF, JPG, JPEG o PNG |
| No aparece un equipo | Filtros activos | Limpiar filtros |
| La fecha de vencimiento no coincide | Duración mal ingresada | Revisar meses de vigencia |
| El equipo sigue en calibración | Envío no cerrado | Registrar retorno |

---

## 20. Preguntas frecuentes

Debe incluir preguntas como:

- ¿Cuándo empieza la alerta de vencimiento?
- ¿Puedo registrar varias calibraciones para una misma herramienta?
- ¿Puedo adjuntar más de un documento?
- ¿Qué hago si un equipo está vencido?
- ¿Qué hago si el certificado está observado?
- ¿Qué significa EN_CALIBRACION?

---

## 21. Anexos

Incluir anexos futuros:

- Formatos de códigos internos.
- Flujos de proceso.
- Matriz de roles.
- Convenciones de nomenclatura.
- Procedimiento para auditoría.
- Procedimiento para respaldo de información.

---

# Reglas de actualización del manual

Codex debe actualizar el manual cuando:

- Se cree una nueva pantalla.
- Se modifique un flujo de usuario.
- Se agregue un nuevo botón o acción.
- Se agregue un nuevo estado.
- Se modifique una regla de alerta.
- Se cambie un formulario.
- Se agregue carga de archivos.
- Se agregue un reporte.
- Se cambie la navegación.
- Se implemente autenticación o roles.
- Se agregue una validación relevante.

---

# Registro de cambios mínimo por cada actualización

Cada actualización debe dejar registro en la sección de control de cambios:

```txt
Versión:
Fecha:
Cambio realizado:
Módulo afectado:
Responsable:
```

## Criterio de versionado sugerido

- Cambios menores de texto o aclaraciones: incrementar tercer número.
  - Ejemplo: 1.0.1

- Cambios funcionales pequeños: incrementar segundo número.
  - Ejemplo: 1.1.0

- Cambios grandes o nueva fase completa: incrementar primer número.
  - Ejemplo: 2.0.0

---

# Instrucción final para Codex

Durante todo el desarrollo, Codex debe mantener actualizados simultáneamente:

```txt
docs/PROJECT_MANUAL.md
docs/USER_INSTRUCTION_MANUAL.md
```

El primero documenta el sistema desde la perspectiva técnica y funcional interna.

El segundo documenta el uso operativo para usuarios finales, incluyendo procedimientos, instrucciones, buenas prácticas, errores frecuentes y control de cambios.
