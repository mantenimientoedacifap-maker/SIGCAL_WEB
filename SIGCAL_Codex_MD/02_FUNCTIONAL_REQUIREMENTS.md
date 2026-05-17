# 02 — Requerimientos Funcionales

## 1. Dashboard general

La app debe tener una vista principal tipo dashboard con indicadores rápidos.

### Indicadores mínimos

- Total de herramientas/equipos registrados.
- Total de calibraciones vigentes.
- Total de calibraciones próximas a vencer.
- Total de calibraciones vencidas.
- Total de equipos en centro de calibración.
- Total de equipos sin calibración.
- Total de equipos fuera de servicio.
- Total de equipos dados de baja.

### Secciones del dashboard

- Cards KPI.
- Gráfico por estado de calibración.
- Tabla de próximos vencimientos.
- Tabla de calibraciones vencidas.
- Tabla de equipos en centro de calibración.
- Tabla de equipos sin calibración.

---

## 2. Inventario de herramientas y equipos

Debe existir una pantalla principal de inventario.

### Campos visibles en tabla

- Código interno.
- Nomenclatura.
- Categoría.
- Fabricante.
- Modelo.
- Número de serie.
- Número de parte.
- Fecha de calibración.
- Duración de calibración.
- Fecha de vencimiento.
- Días restantes.
- Estado de calibración.
- Ubicación actual.
- Estado físico.
- Acciones.

### Acciones mínimas

- Ver detalle.
- Editar.
- Registrar calibración.
- Enviar a calibración.
- Adjuntar certificado.
- Adjuntar guía de remisión.
- Ver historial.
- Cambiar ubicación.
- Dar de baja.

### Filtros mínimos

- Por estado de calibración.
- Por ubicación.
- Por fabricante.
- Por categoría.
- Por centro de calibración.
- Por rango de vencimiento.
- Por resultado de calibración.
- Por texto libre.

---

## 3. Registro de herramienta/equipo

Formulario para crear y editar registros.

### Campos requeridos

- Nomenclatura.
- Categoría.
- Fabricante.
- Modelo.
- Número de serie.
- Número de parte.
- Código interno.
- Descripción.
- Ubicación actual.
- Estado físico/disponibilidad.

### Ejemplos de nomenclatura

- Torquímetro.
- Pie de Rey.
- Manómetro.
- Cargador de batería.
- Multímetro.
- Calibrador.
- Micrómetro.
- Equipo electrónico.
- Herramienta especial.

### Ejemplos de fabricantes

- SNAP-ON.
- ALPHA.
- FLUKE.
- MITUTOYO.
- FACOM.
- TEKTRONIX.
- BOSCH.
- Otro.

---

## 4. Registro de calibración

Cada herramienta/equipo debe permitir registrar múltiples calibraciones a lo largo del tiempo.

### Campos requeridos

- Herramienta/equipo asociado.
- Fecha de calibración.
- Duración de calibración en meses.
- Fecha de vencimiento calculada.
- Centro de calibración.
- Número de certificado.
- Archivo del certificado.
- Resultado.
- Observaciones.

### Resultados posibles

- Conforme.
- No conforme.
- Condicionado.
- Pendiente.

---

## 5. Control de envío a centro de calibración

Cuando una herramienta o equipo sea enviada a calibración, la app debe registrar el movimiento.

### Campos requeridos

- Herramienta/equipo asociado.
- Centro de calibración.
- Fecha de remisión.
- Número de guía de remisión.
- Archivo de guía de remisión.
- Fecha estimada de retorno.
- Fecha real de retorno.
- Estado del envío.
- Observaciones.

### Estados del envío

- Pendiente de envío.
- Enviado.
- Recibido por proveedor.
- En proceso.
- Listo para recojo.
- Retornado.
- Observado.

### Regla importante

Cuando un equipo se registre como enviado a calibración:

- Su ubicación debe cambiar automáticamente a `Centro de calibración`.
- Su estado físico debe cambiar automáticamente a `EN_CALIBRACION`.

Cuando retorne:

- Debe poder registrar nueva calibración.
- Debe poder adjuntar certificado.
- Debe actualizarse la ubicación.
- Debe cerrarse el envío activo.

---

## 6. Ubicaciones

La app debe permitir usar ubicaciones predefinidas y eventualmente administrables.

### Ubicaciones iniciales

- Almacén.
- Taller.
- Línea de vuelo.
- Hangar.
- Centro de calibración.
- En préstamo.
- Fuera de servicio.
- Baja.
- Otro.

---

## 7. Alertas de calibración

Debe existir una pantalla llamada:

**Alertas de Calibración**

### Alertas mínimas

- Próximos 30 días.
- Próximos 15 días.
- Vencidos.
- En centro de calibración.
- Sin certificado.
- Sin calibración.
- Con resultado no conforme.
- Con retorno estimado vencido.

### Colores por alerta

- Verde: vigente.
- Amarillo: faltan 16 a 30 días.
- Naranja: faltan 1 a 15 días.
- Rojo: vencido.
- Azul: en calibración.
- Gris: sin información.

---

## 8. Historial de calibraciones

Cada herramienta/equipo debe tener historial completo.

### Datos del historial

- Fecha de calibración.
- Duración.
- Fecha de vencimiento.
- Centro de calibración.
- Número de certificado.
- Archivo del certificado.
- Resultado.
- Observaciones.
- Fecha de registro.

---

## 9. Historial de envíos

Cada herramienta/equipo debe tener historial de envíos a calibración.

### Datos del historial

- Centro de calibración.
- Fecha de remisión.
- Número de guía.
- Archivo de guía.
- Fecha estimada de retorno.
- Fecha real de retorno.
- Estado del envío.
- Observaciones.

---

## 10. Reportes

Crear pantalla de reportes con consultas básicas.

### Reportes iniciales

- Herramientas vigentes.
- Herramientas próximas a vencer.
- Herramientas vencidas.
- Herramientas en calibración.
- Herramientas sin calibración.
- Reporte por fabricante.
- Reporte por ubicación.
- Reporte por categoría.
- Reporte mensual de calibraciones.
- Historial por herramienta.

### Exportación

La exportación a Excel, PDF y CSV puede quedar preparada para una segunda fase.
