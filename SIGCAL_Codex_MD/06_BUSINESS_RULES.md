# 06 — Reglas de Negocio

## 1. Fecha de vencimiento

La fecha de vencimiento debe calcularse automáticamente.

```txt
expiration_date = calibration_date + validity_months
```

Ejemplo:

```txt
Fecha de calibración: 10/04/2026
Duración: 12 meses
Fecha de vencimiento: 10/04/2027
```

## 2. Días restantes

Los días restantes deben calcularse contra la fecha actual.

```txt
days_remaining = expiration_date - current_date
```

## 3. Estado de calibración

El estado debe calcularse automáticamente.

```txt
Si no tiene fecha de vencimiento:
  SIN_CALIBRACION

Si tiene envío activo a centro de calibración:
  EN_CALIBRACION

Si current_date > expiration_date:
  VENCIDO

Si faltan entre 1 y 15 días:
  ALERTA_NARANJA

Si faltan entre 16 y 30 días:
  ALERTA_AMARILLA

Si faltan más de 30 días:
  VIGENTE
```

## 4. Estados de calibración permitidos

```txt
VIGENTE
ALERTA_AMARILLA
ALERTA_NARANJA
VENCIDO
SIN_CALIBRACION
EN_CALIBRACION
```

## 5. Estados físicos permitidos

```txt
DISPONIBLE
EN_USO
EN_CALIBRACION
FUERA_DE_SERVICIO
BAJA
EXTRAVIADO
```

## 6. Estados de envío permitidos

```txt
PENDIENTE_ENVIO
ENVIADO
RECIBIDO_POR_PROVEEDOR
EN_PROCESO
LISTO_PARA_RECOJO
RETORNADO
OBSERVADO
```

## 7. Alerta desde 30 días antes

La app debe empezar a alertar desde 30 días antes del vencimiento.

### Rango amarillo

```txt
16 a 30 días restantes
```

### Rango naranja

```txt
1 a 15 días restantes
```

### Rango rojo

```txt
Fecha actual mayor a fecha de vencimiento
```

## 8. Envío a centro de calibración

Cuando se registre un envío activo:

- La ubicación actual debe cambiar a `Centro de calibración`.
- El estado físico debe cambiar a `EN_CALIBRACION`.
- El equipo debe aparecer en la vista de envíos.
- El equipo debe aparecer en alertas de `EN_CALIBRACION`.

## 9. Retorno de centro de calibración

Cuando el equipo retorne:

- Se debe registrar `actual_return_date`.
- El estado del envío debe cambiar a `RETORNADO`.
- Debe poder registrarse una nueva calibración.
- Debe poder adjuntarse el nuevo certificado.
- Debe actualizarse la ubicación física.
- Debe recalcularse el nuevo vencimiento.

## 10. Certificado de calibración

Un certificado debe estar asociado a una calibración específica.

Formatos permitidos:

- PDF.
- JPG.
- JPEG.
- PNG.

## 11. Guía de remisión

Una guía de remisión debe estar asociada a un envío específico.

Formatos permitidos:

- PDF.
- JPG.
- JPEG.
- PNG.

## 12. Herramienta sin calibración

Una herramienta se considera `SIN_CALIBRACION` cuando:

- No tiene calibraciones registradas.
- O la última calibración no tiene fecha de vencimiento válida.

## 13. Última calibración

Para mostrar el estado actual, se debe considerar la última calibración registrada por fecha de calibración o fecha de creación.

## 14. Baja

Una herramienta dada de baja no debe eliminarse físicamente de la base de datos.

Debe cambiarse su estado físico a:

```txt
BAJA
```

## 15. Eliminación

Evitar eliminación definitiva salvo que sea una función administrativa protegida.

Preferir baja lógica.
