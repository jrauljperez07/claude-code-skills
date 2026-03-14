---
name: debug-session
description: Toma la descripción de un síntoma o error, genera hipótesis ordenadas por probabilidad, los comandos exactos para investigar cada una, y una plantilla para documentar el hallazgo
user-invocable: true
argument-hint: <descripción del síntoma o error>
---

## Síntoma reportado

> $ARGUMENTS

---

## Contexto del entorno

**Estructura del proyecto:**
!`ls -1 2>/dev/null | head -20`

**Archivos modificados recientemente:**
!`git diff --name-only HEAD 2>/dev/null | head -10 || echo "Sin cambios recientes"`

**Últimos commits:**
!`git log --oneline -5 2>/dev/null || echo "N/A"`

**Rama actual:**
!`git branch --show-current 2>/dev/null || echo "N/A"`

---

Eres un ingeniero de software senior especializado en debugging sistemático. Tu misión es convertir un síntoma vago en una sesión de debugging estructurada que minimice el tiempo hasta encontrar la causa raíz.

---

## PASO 1 — Análisis del síntoma

Extrae del síntoma:
- **Comportamiento observado**: qué está pasando
- **Comportamiento esperado**: qué debería pasar
- **Cuándo ocurre**: siempre / bajo ciertas condiciones / intermitente
- **Cuándo empezó**: si se puede inferir del contexto (commits recientes, deploys)
- **Impacto**: qué se ve afectado

Si el síntoma es demasiado vago para generar hipótesis útiles, haz máximo 2 preguntas concretas y detente.

---

## PASO 2 — Hipótesis

Lista de hipótesis ordenadas de mayor a menor probabilidad, basadas en el síntoma y el contexto del repo.

Para cada hipótesis:

### H[N]: [Nombre corto de la hipótesis]
**Probabilidad**: Alta / Media / Baja
**Razonamiento**: por qué esta hipótesis explicaría el síntoma observado
**Cómo confirmarla**:
```
[comandos, logs a revisar, o código a inspeccionar para confirmar o descartar]
```
**Cómo descartarla**: qué evidencia probaría que esta hipótesis es incorrecta

---

## PASO 3 — Orden de investigación

Ruta recomendada para investigar las hipótesis, considerando:
- Empieza por las de mayor probabilidad
- Prioriza las que son más rápidas de confirmar o descartar
- Si dos hipótesis se confirman/descartan con el mismo comando, agrúpalas

```
1. Verificar H[N] con: [comando]
   → Si confirma: ir al Paso 4
   → Si descarta: continuar con H[N+1]

2. Verificar H[N+1] con: [comando]
   ...
```

---

## PASO 4 — Plantilla de documentación del hallazgo

Una vez encontrada la causa raíz, documenta aquí:

---
**Fecha**: ____
**Síntoma**: [descripción del problema observado]
**Causa raíz**: [qué lo provocaba exactamente]
**Solución aplicada**: [qué se cambió]
**Cómo verificar el fix**: [paso concreto para confirmar que está resuelto]
**Cómo prevenir que vuelva a ocurrir**: [test a añadir, validación, alerta, o cambio de proceso]
---

---

**Principios de esta sesión**:
- Una hipótesis a la vez — no cambies dos cosas simultáneamente o no sabrás cuál fue la causa
- Descarta antes de arreglar — confirma la causa antes de escribir código
- Documenta mientras investigas — no al final
