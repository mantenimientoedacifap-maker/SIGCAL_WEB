# SIGCAL

Sistema de Gestión de Calibración  
Manual de Instrucción del Usuario  
Versión: 2.0  
Fecha de actualización: 16/05/2026  
Responsable: Codex

---

## 1. Portada

Este documento describe el uso operativo de SIGCAL para usuarios finales, operadores, supervisores y personal responsable del control de calibraciones.

---

## 2. Control de cambios del manual

| Versión | Fecha | Cambio realizado | Módulo afectado | Responsable |
|---------|-------|-----------------|-----------------|-------------|
| 1.0 | 30/04/2026 | Creación inicial del manual y documentación de la base navegable | General | Codex |
| 1.1 | 30/04/2026 | Documentación de estado Supabase en Configuración | Configuración | Codex |
| 1.2 | 30/04/2026 | Documentación de login y roles iniciales | Acceso y seguridad | Codex |
| 1.3 | 02/05/2026 | Documentación de calibraciones funcionales | Calibraciones | Codex |
| 2.0 | 16/05/2026 | Actualización completa: dashboard real, inventario, ficha técnica, envíos kanban, préstamos, reportes, estadísticas, QR, PDF, perfil de usuario, administración de usuarios | Todos los módulos | Codex |

---

## 3. Introducción

SIGCAL es el Sistema de Gestión de Calibración para controlar herramientas especiales, equipos electrónicos, instrumentos de medición y otros elementos sujetos a calibración periódica.

El sistema permite registrar equipos, controlar calibraciones, calcular vencimientos automáticamente, generar alertas visuales, registrar envíos a centros de calibración, adjuntar certificados y guías de remisión, gestionar préstamos con vales QR, consultar historiales completos y mantener trazabilidad documental para auditoría.

---

## 4. Alcance del sistema

SIGCAL permite:

- Registrar herramientas y equipos con datos técnicos completos.
- Registrar calibraciones con cálculo automático de vencimiento.
- Cargar certificados de calibración en PDF.
- Controlar equipos enviados a centros de calibración con seguimiento por estados.
- Gestionar préstamos de herramientas con vales QR imprimibles.
- Visualizar alertas por estado de calibración (vigente, alerta, crítico, vencido).
- Gestionar equipos en cuarentena por no conformidad o vencimiento.
- Dar de baja herramientas conservando trazabilidad.
- Consultar historial completo de calibraciones, envíos, préstamos y trazabilidad.
- Generar reportes y estadísticas con cronograma de vencimientos.
- Exportar PDFs de estado general, ficha individual, etiquetas QR y vales de préstamo.
- Administrar usuarios y roles.
- Configurar perfil de usuario con foto, tema visual e idioma.

---

## 5. Definiciones y abreviaturas

| Término | Definición |
|---------|------------|
| Calibración | Proceso de verificación y ajuste de un instrumento contra un patrón o referencia |
| Fecha de calibración | Fecha en que se realizó la calibración |
| Fecha de vencimiento | Fecha hasta la cual la calibración se considera vigente |
| Vigente | Equipo con calibración válida por más de 30 días |
| Alerta | Equipo cuya calibración vence entre 16 y 30 días |
| Crítico | Equipo cuya calibración vence en 15 días o menos |
| Vencido | Equipo cuya fecha de vencimiento ya fue superada |
| En calibración | Equipo con un envío activo a un centro de calibración |
| Sin calibrar | Equipo sin ninguna calibración registrada |
| Centro de calibración | Laboratorio o proveedor que realiza la calibración |
| Guía de remisión | Documento que sustenta el traslado del equipo |
| Certificado de calibración | Documento que acredita el resultado de la calibración |
| Cuarentena | Estado del equipo que requiere acción correctiva por vencimiento o no conformidad |
| Trazabilidad | Historial completo de eventos de una herramienta |
| Health score | Porcentaje de salud del inventario (herramientas vigentes / total) |

---

## 6. Roles de usuario

SIGCAL maneja tres roles:

| Rol | Permisos |
|-----|----------|
| **Lider** | Acceso total. Puede gestionar herramientas, calibraciones, envíos, préstamos, administrar usuarios y roles. Es el rol de mayor jerarquía. |
| **Administrador** | Puede gestionar datos operativos: crear/editar herramientas, registrar calibraciones, gestionar envíos y préstamos. No puede administrar usuarios. |
| **Usuario** | Acceso de consulta. Puede ver dashboard, inventario, reportes y fichas técnicas. No puede modificar datos operativos. |

Todo usuario nuevo recibe inicialmente el rol **Usuario**. Un Lider debe ajustar el rol si corresponde.

---

## 7. Acceso al sistema

### Cómo ingresar

1. Abrir la web de SIGCAL en el navegador.
2. Ingresar su correo electrónico autorizado.
3. Ingresar su contraseña.
4. Hacer clic en **Acceder**.

Si las credenciales son correctas, el sistema mostrará el Dashboard.

### Cómo cerrar sesión

1. Hacer clic en el ícono de usuario en la parte superior derecha.
2. Seleccionar **Cerrar sesión**.
3. El sistema volverá a la pantalla de login.

### Si no puede acceder

- Verifique que su correo y contraseña sean correctos.
- Si olvidó su contraseña, use la opción **¿Olvidaste tu contraseña?** en la pantalla de login.
- Si su usuario no existe, solicite a un Lider que lo registre.

---

## 8. Descripción general de la interfaz

La interfaz de SIGCAL se compone de tres zonas principales:

### Sidebar (izquierda)
Barra lateral oscura con navegación a todos los módulos:
- **Dashboard**: panel principal con indicadores.
- **Inventario**: gestión de herramientas y equipos.
- **Envíos**: control de envíos a calibración.
- **Préstamos**: control de herramientas prestadas.
- **Estadísticas**: reportes y análisis.
- **Usuarios**: administración de perfiles (solo Lider).
- **Configuración**: perfil y estado del sistema.

En la parte inferior del sidebar se muestra:
- Estado de conexión con Supabase (punto verde = conectado).
- Correo y rol del usuario activo.

### Topbar (superior)
Barra superior con:
- Título de la sección actual.
- Botones de tema visual (clásico, claro, oscuro).
- Selector de idioma (español, inglés).
- Campana de notificaciones.
- Menú de usuario (perfil, cerrar sesión).

### Área central
Contenido principal que cambia según el módulo seleccionado. Incluye encabezados, cards, tablas, formularios y gráficos.

### Colores de estado

| Color | Significado |
|-------|-------------|
| Verde | Vigente / Conforme / Saludable |
| Amarillo | Alerta (16-30 días para vencer) |
| Naranja | Crítico (1-15 días para vencer) |
| Rojo | Vencido / No conforme / Peligro |
| Azul | En calibración / Informativo |
| Gris | Sin calibración / Sin información |

---

## 9. Dashboard

El Dashboard es la pantalla principal. Muestra indicadores en tiempo real del sistema.

### KPIs (tarjetas superiores)
- **Total**: cantidad de herramientas en inventario activo.
- **Vigentes**: herramientas con calibración al día (>30 días).
- **Acción requerida**: herramientas vencidas o críticas que necesitan atención inmediata.
- **En calibración**: herramientas enviadas a centros de calibración.
- **Préstamos**: herramientas actualmente prestadas. Si hay préstamos vencidos, el color cambia a rojo.

### Cumplimiento
Barras de progreso que muestran la distribución del inventario por estado:
- Vigentes (verde)
- Próximos a vencer (amarillo)
- Vencidos (rojo)
- En calibración (azul)

### Próximos vencimientos
Tabla con las 6 herramientas más urgentes. Muestra código, nombre, fecha de vencimiento y estado. Al hacer clic en una fila, navega a la ficha técnica de esa herramienta.

### Actividad reciente
Lista de las últimas calibraciones y envíos registrados, ordenados por fecha.

### Acciones rápidas
Botones de acceso directo:
- **Nueva herramienta**: va al formulario de registro.
- **Nuevo envío**: va al formulario de envío a calibración.
- **Cuarentena**: va a la vista de herramientas en cuarentena.

### Exportar PDF
El botón **Exportar PDF** genera un reporte A4 con el estado general de todas las herramientas.

---

## 10. Inventario de herramientas/equipos

La pantalla de Inventario es el punto central para consultar y gestionar herramientas.

### Vista principal

Muestra todas las herramientas activas (no vencidas ni en cuarentena) en formato de cards. Cada card muestra:
- **Nombre** de la herramienta.
- **Código interno**, fabricante, ubicación.
- **Fecha de vencimiento** de la última calibración.
- **Badge de estado** con color.
- Borde izquierdo coloreado según criticidad.

### Búsqueda

Escriba en la barra de búsqueda para filtrar por código, nombre, categoría, fabricante, ubicación o estado. Puede usar múltiples palabras separadas por espacio.

### Filtros por estado

Pills horizontales que filtran por:
- **Todos**: sin filtro.
- **Vigentes**: herramientas con calibración al día.
- **Críticos**: herramientas que vencen en 15 días o menos.
- **En calibración**: herramientas enviadas a centro de calibración.

Cada pill muestra el contador de herramientas en esa categoría.

### Paginación

Si hay más de 15 herramientas, aparecen controles de paginación en la parte inferior.

### Acciones desde la card

Cada card tiene botones de acción rápida:
- **Prestar** (icono de asignación): abre el diálogo de préstamo.
- **Calibrar** (icono de verificación): va al formulario de calibración.
- **Baja** (icono de archivo): inicia el proceso de baja (solo administradores).
- Hacer clic en la card: abre la ficha técnica completa.

### Vistas especiales

- **Cuarentena**: botón superior que muestra herramientas vencidas o con causa de cuarentena (no conforme, irreparable, inoperativa, no calibrable).
- **Retirados**: accesible desde el menú contextual, muestra herramientas dadas de baja.

---

## 10.1 Cómo registrar una herramienta/equipo

1. En Inventario, haga clic en **+ Nuevo registro**.
2. Complete los campos del formulario:

   **Datos generales:**
   - **Nomenclatura**: nombre descriptivo de la herramienta (obligatorio).
   - **Código interno**: código único de su organización.
   - **Descripción**: detalle adicional del equipo.
   - **Categoría**: seleccione de la lista o escriba una nueva.
   - **Fabricante**: seleccione de la lista o escriba uno nuevo.
   - **Ubicación actual**: lugar físico donde se encuentra.

   **Datos técnicos:**
   - **Modelo**: modelo del fabricante.
   - **Número de serie**: identificador único de fábrica.
   - **Número de parte**: referencia del repuesto o componente.
   - **Fecha de adquisición**: cuándo se incorporó al inventario.

   **Documentos:**
   - **Fotografía**: imagen del equipo (JPG/PNG).
   - **Manual técnico**: PDF del fabricante.
   - **Certificado de fabricante**: documento de origen.

3. Haga clic en **Guardar herramienta**.

---

## 10.2 Cómo editar una herramienta/equipo

1. Busque la herramienta en el Inventario.
2. Haga clic en la card para abrir la ficha técnica.
3. Haga clic en el ícono de **Editar** (lápiz) en la parte superior.
4. Modifique los campos necesarios.
5. Haga clic en **Guardar cambios**.

---

## 10.3 Cómo consultar la ficha técnica

1. Busque la herramienta en el Inventario.
2. Haga clic en la card para abrir la ficha técnica completa.
3. La ficha muestra:

   **Identity Card:**
   - Fotografía de la herramienta.
   - Especificaciones técnicas: serie, código interno, parte, ubicación, fabricante, modelo, categoría, fecha de alta.
   - **Health ring**: anillo circular con el porcentaje de salud y los días restantes hasta el vencimiento.
   - Badge de estado actual.

   **Manual técnico:** si está cargado, puede descargarlo con un clic.

   **Código QR:** identificador único. Puede imprimir la etiqueta QR.

   **Última calibración:** resultado, fecha, proveedor, número de certificado, vencimiento. Si hay certificado PDF, puede abrirlo. El botón **Ver historial completo** muestra todas las calibraciones registradas.

   **Préstamo activo:** si la herramienta está prestada, muestra responsable, taller, fechas y barra de progreso. Puede imprimir el vale PDF o registrar la devolución.

   **Informes técnicos:** documentos de inoperatividad, no conformidad o informes de calibrador.

   **Trazabilidad completa:** línea de tiempo con todos los eventos (alta, calibraciones, préstamos, envíos, baja, cuarentena). Cada evento muestra fecha y documento adjunto si existe.

---

## 10.4 Cómo dar de baja una herramienta

1. En la ficha técnica, abra el menú contextual (tres puntos) y seleccione **Dar de baja**.
2. También puede usar el botón **Baja** desde la card del inventario.
3. En el diálogo de confirmación:
   - Escriba el **motivo** de la baja (obligatorio, ej. OBSOLESCENCIA, DAÑO IRREPARABLE).
   - Escriba **DAR DE BAJA** en mayúsculas para confirmar.
4. Haga clic en **Ejecutar baja**.

La herramienta pasa a estado **BAJA**, su ubicación cambia a **ALMACEN DE BAJAS** y el evento queda registrado en la trazabilidad. La herramienta seguirá visible en la vista de Retirados.

**Precaución:** La baja no elimina el historial. Úsela solo cuando el equipo ya no estará disponible para uso.

---

## 11. Registro de calibración

### Procedimiento

1. Desde la ficha técnica de la herramienta, haga clic en **Registrar calibración** (en el grid de acciones o en el menú contextual).
2. Complete el formulario:

   **Datos metrológicos:**
   - **Fecha de calibración**: seleccione la fecha en que se realizó.
   - **Vigencia (meses)**: duración de la calibración (ej. 12 para un año). Máximo 120 meses.
   - **Próximo vencimiento**: se calcula automáticamente. Verifique que sea correcto.
   - **Resultado**: seleccione Conforme, Condicionado o No conforme.

   **Proveedor y certificado:**
   - **Proveedor de calibración**: seleccione de la lista de proveedores registrados.
   - **Centro/laboratorio**: nombre del laboratorio que realizó la calibración.
   - **Número de certificado**: identificador del documento.
   - **Certificado PDF**: opcional. Haga clic en el selector para cargar un archivo PDF.

   **Si el resultado es No conforme:**
   - Aparecerá la sección **Cuarentena obligatoria**.
   - Seleccione la **causa**: No conforme, Irreparable, Inoperativa, No calibrable.
   - Agregue **notas** explicativas.

   **Observaciones:** campo libre para notas adicionales.

3. Haga clic en **Guardar calibración vigente**.

Al guardar, el sistema:
- Registra la calibración en el historial.
- Actualiza el estado de la herramienta.
- Si cargó un certificado, lo almacena y lo asocia como documento.
- Genera un evento en la trazabilidad.
- Si es No conforme, marca la herramienta en cuarentena.

---

## 12. Carga de certificado de calibración

### Formatos permitidos
- **PDF** (recomendado y único formato aceptado en el formulario de calibración).

### Dónde se almacena
El certificado se guarda en Supabase Storage de forma segura. Solo usuarios autenticados pueden acceder mediante un enlace firmado temporal.

### Cómo abrir un certificado
1. En la ficha técnica, en la sección **Última calibración**, haga clic en **Abrir certificado PDF**.
2. También puede abrir certificados desde el historial de calibraciones (cada registro tiene su botón PDF).

---

## 13. Envío a centro de calibración

### Procedimiento para crear un envío

1. Desde el menú lateral, ingrese a **Envíos**.
2. Haga clic en **+ Nuevo envío**.
3. Complete el formulario:
   - **Herramienta**: seleccione de la lista de herramientas disponibles.
   - **Centro de calibración**: nombre del laboratorio o proveedor destino.
   - **Proveedor**: opcional, seleccione de la lista de proveedores.
   - **Fecha de envío**: fecha en que se remite el equipo.
   - **Fecha estimada de retorno**: cuándo se espera que regrese.
   - **Guía de remisión**: número de documento de traslado.
   - **Observaciones**: notas adicionales.
4. Haga clic en **Registrar envío**.

Al registrar el envío:
- La ubicación de la herramienta cambia al centro de calibración.
- El estado cambia a **EN CALIBRACIÓN**.
- Aparece en el tablero Kanban de envíos.

### Seguimiento de envíos

La pantalla de Envíos muestra:
- **KPIs**: total de envíos abiertos, retornados, vencidos y total general.
- **Kanban**: columnas por estado del envío:
  - **Enviado**: el equipo fue remitido.
  - **Recibido por proveedor**: el centro confirmó recepción.
  - **En proceso**: la calibración está en curso.
  - **Listo para recojo**: el equipo está listo para retornar.
- **Tabla general**: listado completo con todas las columnas y acción de actualizar estado.

### Cómo actualizar el estado de un envío

1. En la tabla de envíos, ubique el envío.
2. En la columna **Acción**, haga clic en el chip **Actualizar**.
3. Seleccione el nuevo estado:
   - Recibido por proveedor
   - En proceso
   - Listo para recojo
   - **Marcar retornado** (cierra el envío)

Al marcar **Retornado**:
- El envío se cierra con la fecha real de retorno.
- La herramienta vuelve a estado **DISPONIBLE**.
- La ubicación vuelve a **ALMACEN**.
- Se recomienda registrar inmediatamente la nueva calibración.

---

## 14. Retorno de equipo calibrado

1. En Envíos, ubique el equipo en la tabla o en el kanban.
2. Haga clic en **Actualizar** y seleccione **Marcar retornado**.
3. Vaya a la ficha técnica de la herramienta.
4. Haga clic en **Registrar calibración**.
5. Complete el formulario con los datos del nuevo certificado.
6. Adjunte el certificado PDF.
7. Guarde.

---

## 15. Préstamos de herramientas

### Cómo generar un préstamo

1. Desde la ficha técnica de la herramienta, en la sección **Préstamo**, haga clic en **Generar préstamo**.
2. Complete el diálogo:
   - **Taller / oficina destino**: seleccione de la lista.
   - **Persona responsable**: seleccione de la lista o ingrese manualmente.
   - **Fecha estimada de retorno**: opcional.
   - **Observaciones**: condiciones o notas.
3. Haga clic en **Confirmar préstamo**.

Al generar el préstamo:
- La herramienta cambia a estado **EN USO**.
- La ubicación se actualiza al taller de destino.
- Se genera un **vale QR** que puede imprimirse como PDF.

### Cómo registrar una devolución

1. En la ficha técnica, en la sección **Préstamo activo**, haga clic en **Devolver**.
2. Ingrese observaciones sobre la condición de la herramienta al retornar.
3. Haga clic en **Confirmar retorno**.

La herramienta vuelve a estado **DISPONIBLE** y ubicación **ALMACEN**.

### Vista global de préstamos

En el menú lateral, **Préstamos** muestra todos los préstamos del sistema con filtros:
- **Todos**: sin filtro.
- **Activos**: préstamos vigentes.
- **Vencidos**: préstamos con fecha de retorno superada.
- **Devueltos**: préstamos cerrados.

Cada card muestra el progreso del período de préstamo con una barra visual.

---

## 16. Alertas de calibración

### Dónde se visualizan las alertas

SIGCAL concentra las alertas en dos lugares principales:

**1. Dashboard (panel central):**
- El KPI **Acción requerida** agrupa todas las herramientas que necesitan atención (críticas + vencidas).
- La tabla de **Próximos vencimientos** lista las 6 más urgentes con su estado.
- Las barras de cumplimiento muestran la distribución completa del inventario.

**2. Campana de notificaciones (topbar superior derecha):**
- Muestra un **badge con color** según la criticidad máxima: rojo (vencidos), naranja (críticos ≤15d), amarillo (avisos leves).
- El número indica cuántas alertas **no has visto aún**.
- Al hacer clic, se abre el **Centro de Alertas** con:
  - Lista priorizada de todas las alertas activas.
  - Chips de resumen: "X vencidas", "X urgentes", "X avisos".
  - Cada alerta muestra el tipo, la herramienta y un ícono de navegación.
  - Al tocar una alerta, navegas directo a la ficha técnica y se marca como leída.
  - Botón **Marcar todo como leído** para limpiar la lista de una vez.
  - Las alertas leídas **desaparecen** del centro de alertas.
  - Si una herramienta se recalibra, su alerta anterior se elimina automáticamente.

### Tipos de alertas detectadas

| Alerta | Severidad | Color | ¿Qué hacer? |
|--------|-----------|-------|-------------|
| **Calibración vencida** | Crítica | Rojo | Retirar de uso. Enviar a calibrar inmediatamente |
| **Vence en X días** (≤15d) | Urgente | Naranja | Priorizar envío a calibración |
| **Préstamo vencido** | Urgente | Naranja | Gestionar devolución inmediata |
| **Próximo a vencer** (16-30d) | Aviso | Amarillo | Planificar envío |
| **Sin calibración** | Aviso | Amarillo | Regularizar registrando primera calibración |
| **Certificado pendiente** | Informativo | Gris | Adjuntar PDF del certificado |

### Significado de cada estado

| Estado | Color | Significado | ¿Qué hacer? |
|--------|-------|-------------|-------------|
| **VIGENTE** | Verde | Vence en más de 30 días | Mantener seguimiento normal |
| **ALERTA** | Amarillo | Vence en 16 a 30 días | Planificar el envío a calibración |
| **CRÍTICO** | Naranja | Vence en 1 a 15 días | Priorizar el envío inmediatamente |
| **VENCIDO** | Rojo | Fecha de vencimiento superada | Retirar de uso y enviar a calibrar |
| **EN CALIBRACIÓN** | Azul | Tiene un envío activo | Dar seguimiento al proveedor |
| **SIN CALIBRAR** | Gris | No tiene calibración registrada | Regularizar registrando una calibración |

### Otras vistas de alerta

- **Inventario**: las cards tienen borde izquierdo coloreado según el estado. Los filtros permiten ver solo las críticas o solo las vigentes.
- **Cuarentena** (`/tools/quarantine`): vista dedicada para herramientas vencidas o con causa de cuarentena (no conforme, irreparable, inoperativa, no calibrable).

---

## 17. Reportes y estadísticas

### Cómo acceder

En el menú lateral, seleccione **Estadísticas**.

### Información disponible

**Summary strip:** 7 métricas principales:
- Total de herramientas
- Vigentes
- Vencidos
- En calibración
- Bajas
- Envíos activos
- Con certificado

**Cronograma de vencimientos:**
- Pills mensuales que muestran cuántas herramientas vencen cada mes.
- Cada pill indica con puntos de colores: verde (próximos), amarillo (alerta), rojo (críticos).
- Al seleccionar un mes, se despliega el detalle con la lista de herramientas ordenadas por urgencia.

**Distribución por categoría:**
- Barras que muestran cuántas herramientas hay en cada categoría.
- Indicador de porcentaje de herramientas vigentes por categoría.

**Distribución por ubicación:**
- Barras que muestran cuántas herramientas hay en cada ubicación física.

### Exportar PDF

El botón **Exportar PDF** en la parte superior genera un reporte A4 con el inventario completo.

---

## 18. Búsqueda y filtros

### Búsqueda por texto

En el Inventario, escriba en la barra de búsqueda. El sistema busca en:
- Código interno
- Nombre de la herramienta
- Categoría
- Fabricante
- Ubicación
- Fecha de vencimiento
- Estado de calibración

Puede usar múltiples palabras. Cada palabra debe coincidir (búsqueda AND).

### Filtros por estado

Use las pills de filtro sobre la barra de búsqueda:
- **Todos**: muestra todas las herramientas activas.
- **Vigentes**: solo herramientas con calibración al día.
- **Críticos**: herramientas con 15 días o menos para vencer.
- **En calibración**: herramientas con envío activo.

### Cómo limpiar filtros

Haga clic en la **X** de la barra de búsqueda para limpiar el texto. Seleccione **Todos** en los filtros para ver el inventario completo.

---

## 19. Administración de usuarios (solo Lider)

### Cómo acceder

En el menú lateral, seleccione **Usuarios** (solo visible para el rol Lider).

### Acciones disponibles

- **Ver listado**: tabla con todos los perfiles registrados, su rol, estado activo y fecha de creación.
- **Editar perfil**: cambiar nombre visible, rol (Lider, Administrador, Usuario) y estado activo.
- **Dar de baja**: desactivar un usuario (`active = false`). El usuario no podrá iniciar sesión, pero su cuenta no se elimina.

**Nota:** La creación de nuevas cuentas de usuario se realiza actualmente desde Supabase Dashboard. La creación desde la interfaz de SIGCAL estará disponible en una fase posterior.

---

## 20. Configuración y perfil

### Cómo acceder

En el menú lateral, seleccione **Configuración**.

### Perfil de usuario

- **Foto de perfil**: haga clic en **Cambiar foto**, seleccione una imagen, recórtela y guarde. La foto aparece en el topbar.
- **Nombre y apellidos**: editables.
- **Correo electrónico**: solo lectura (gestionado por Supabase Auth).
- **País y celular**: seleccione su país y agregue su número.

Haga clic en **Guardar perfil** para aplicar los cambios.

### Tema visual e idioma

Estas opciones se cambian desde el **topbar** (parte superior derecha), no desde Configuración:

- **Tema**: clic en el ícono de paleta para alternar entre modo Clásico, Claro y Oscuro.
- **Idioma**: clic en el selector de idioma para alternar entre Español e Inglés.

Ambas preferencias se guardan automáticamente y persisten al cerrar sesión.

### Estado de Supabase

La tarjeta **Estado Supabase** muestra información de la conexión con el backend:
- **Listo** (verde): conexión activa y funcionando.
- **Pendiente** (amarillo): credenciales no configuradas.
- **Error** (rojo): fallo en la conexión.

Si aparece Pendiente o Error, contacte al administrador técnico.

---

## 21. Buenas prácticas de uso

1. **Registre certificados inmediatamente** después de recibirlos del centro de calibración.
2. **No use herramientas vencidas.** Si aparece en rojo, retire el equipo de uso.
3. **Revise las alertas semanalmente.** El dashboard facilita identificar qué herramientas necesitan acción.
4. **Verifique el número de serie** antes de registrar una herramienta nueva para evitar duplicados.
5. **Use códigos internos únicos** para identificar cada herramienta sin ambigüedad.
6. **Adjunte documentos legibles.** Los PDFs deben ser claros y completos.
7. **Mantenga actualizada la ubicación.** Si mueve una herramienta, edite su ficha.
8. **Cierre los envíos** apenas el equipo retorne del centro de calibración.
9. **Registre la calibración inmediatamente después del retorno.**
10. **No dé de baja sin autorización.** La baja es irreversible a nivel operativo y debe estar justificada.

---

## 22. Errores frecuentes y solución

| Problema | Posible causa | Solución |
|----------|---------------|----------|
| No puedo guardar un registro | Campos obligatorios incompletos | Revise los campos marcados con asterisco |
| No carga el certificado | Formato no permitido | Use PDF (único formato aceptado para certificados) |
| No aparece una herramienta | Filtros activos o está en cuarentena/retirados | Limpiar filtros o revisar vistas de Cuarentena y Retirados |
| La fecha de vencimiento no coincide | Vigencia en meses mal ingresada | Revise el campo de meses; el sistema suma meses, no días |
| El equipo sigue en calibración | Envío no cerrado | Vaya a Envíos y marque el envío como Retornado |
| No puedo modificar datos | Su rol no tiene permisos de escritura | Solicite cambio de rol a un Lider |
| No veo la opción Usuarios | Solo disponible para rol Lider | Solicite acceso a un Lider |
| Supabase aparece Pendiente | Faltan credenciales de conexión | Contacte al administrador técnico |
| El certificado no abre | El enlace temporal expiró | Recargue la página y vuelva a intentar |
| No puedo iniciar sesión | Credenciales incorrectas o cuenta desactivada | Verifique correo/contraseña o contacte a un Lider |

---

## 23. Preguntas frecuentes

### ¿Cuándo empieza la alerta de vencimiento?
Treinta (30) días antes de la fecha de vencimiento. Entre 16-30 días aparece como **Alerta** (amarillo). Entre 1-15 días como **Crítico** (naranja). Al vencer aparece como **Vencido** (rojo).

### ¿Puedo registrar varias calibraciones para una misma herramienta?
Sí. Cada herramienta mantiene su historial completo de calibraciones. La más reciente determina el estado actual.

### ¿Puedo adjuntar más de un documento?
Sí. En la ficha técnica puede tener: certificados de calibración, manual técnico, certificado de fabricante, fotografía e informes técnicos. Cada uno se gestiona por separado.

### ¿Qué hago si un equipo está vencido?
Retírelo de uso inmediatamente. Priorice su envío a calibración. Si ya no es útil, gestione la baja con la autorización correspondiente.

### ¿Qué hago si el certificado está observado o es no conforme?
Registre la calibración con resultado **No conforme**. El sistema marcará la herramienta en cuarentena automáticamente. Esto deja trazabilidad del evento mientras se define la acción correctiva.

### ¿Qué significa EN CALIBRACIÓN?
Significa que la herramienta tiene un envío activo a un centro de calibración. No está disponible para uso hasta que se registre el retorno.

### ¿Qué es la cuarentena?
Es un estado especial para herramientas que requieren acción correctiva. Puede deberse a: calibración vencida, resultado no conforme, equipo irreparable, inoperativo o no calibrable. Las herramientas en cuarentena no aparecen en el inventario principal.

### ¿Cómo imprimo una etiqueta QR?
En la ficha técnica, use el menú contextual (tres puntos) o el grid de acciones y seleccione **Imprimir etiqueta QR**. Se genera un PDF en formato 90×55mm listo para imprimir y pegar en la herramienta.

### ¿Cómo imprimo un vale de préstamo?
En la ficha técnica, en la sección de Préstamo activo, haga clic en **Vale PDF**. Se genera un documento A4 con los datos del préstamo y un código QR de validación.

### ¿Qué roles existen y qué puede hacer cada uno?
- **Lider**: acceso total, incluyendo administración de usuarios.
- **Administrador**: gestión operativa (herramientas, calibraciones, envíos, préstamos).
- **Usuario**: solo consulta (ver dashboard, inventario, reportes).

### ¿Puedo cambiar mi contraseña?
Sí. Use la opción **¿Olvidaste tu contraseña?** en la pantalla de login para recibir un enlace de restablecimiento por correo.

---

## 24. Anexos

### Formatos de códigos internos
Se recomienda usar un formato estandarizado como:
- `EQ-001`, `EQ-002` para equipos electrónicos.
- `HE-001`, `HE-002` para herramientas especiales.
- `IM-001`, `IM-002` para instrumentos de medición.

### Flujo de proceso típico
1. Alta de herramienta en inventario.
2. Registro de calibración inicial con certificado.
3. Seguimiento periódico desde dashboard.
4. Al aparecer alerta amarilla: planificar envío.
5. Al aparecer alerta naranja: ejecutar envío.
6. Registrar envío en el sistema.
7. Dar seguimiento en kanban de envíos.
8. Al retornar: marcar envío como retornado.
9. Registrar nueva calibración con certificado.
10. Repetir ciclo.

### Matriz de roles

| Funcionalidad | Lider | Administrador | Usuario |
|---------------|-------|---------------|---------|
| Ver dashboard | ✅ | ✅ | ✅ |
| Ver inventario | ✅ | ✅ | ✅ |
| Ver ficha técnica | ✅ | ✅ | ✅ |
| Crear herramienta | ✅ | ✅ | ❌ |
| Editar herramienta | ✅ | ✅ | ❌ |
| Dar de baja | ✅ | ✅ | ❌ |
| Registrar calibración | ✅ | ✅ | ❌ |
| Crear envío | ✅ | ✅ | ❌ |
| Actualizar estado envío | ✅ | ✅ | ❌ |
| Generar préstamo | ✅ | ✅ | ❌ |
| Registrar devolución | ✅ | ✅ | ❌ |
| Ver reportes | ✅ | ✅ | ✅ |
| Exportar PDFs | ✅ | ✅ | ✅ |
| Administrar usuarios | ✅ | ❌ | ❌ |
| Cambiar preferencias propias | ✅ | ✅ | ✅ |
