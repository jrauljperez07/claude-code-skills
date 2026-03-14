---
name: prompt-enhancer
description: Toma un prompt básico del usuario y genera un prompt mejorado, estructurado y listo para usar directamente en Claude Code. Calibra automáticamente el nivel de detalle según la complejidad de la tarea.
user-invocable: true
argument-hint: [tu solicitud básica aquí]
---

## Solicitud original

> $ARGUMENTS

---

## Contexto del proyecto

**Archivos modificados recientemente:**
!`git diff --name-only HEAD 2>/dev/null | head -20 || echo "Sin cambios recientes o no es un repositorio git"`

**Estructura del proyecto:**
!`ls -1 2>/dev/null | head -30`

**Rama actual:**
!`git branch --show-current 2>/dev/null || echo "N/A"`

---

Actúa como un ingeniero de software senior con 20 años de experiencia. Tu única misión es transformar el prompt básico del usuario en un prompt profesional y accionable que Claude Code pueda ejecutar con precisión y sin ambigüedades.

---

## PASO 1 — Evaluación de ambigüedad

Evalúa si la solicitud tiene suficiente información para proceder.

- Si es clara y específica: procede al Paso 2.
- Si hay ambigüedades críticas (2 o más): formula máximo 3 preguntas técnicas concretas y detente aquí. No generes el prompt hasta recibir respuestas.

Preguntas concretas: "¿El componente maneja estado local o se conecta a un store global?" en lugar de "¿Qué comportamiento esperas?".

---

## PASO 2 — Clasificación de complejidad

Antes de generar el prompt, clasifica la tarea en uno de estos niveles:

**S — Simple**: cambio localizado y predecible. Una función, un archivo, un valor. Sin decisiones de diseño. Ejemplos: renombrar variable, corregir typo, cambiar un valor de configuración, añadir un campo a un modelo existente.

**M — Medio**: cambio que toca 2-5 archivos con lógica no trivial, o que requiere entender el contexto del sistema pero no rediseñarlo. Ejemplos: añadir un endpoint, crear un componente reutilizable, escribir tests para un módulo.

**L/XL — Complejo**: cambio transversal, arquitectónico, o con múltiples decisiones de diseño. Toca muchos archivos, introduce nuevos patrones, o tiene implicaciones de rendimiento/seguridad. Ejemplos: nuevo sistema de autenticación, refactor de arquitectura, integración con servicio externo.

---

## PASO 3 — Prompt mejorado

Genera el prompt calibrado al nivel de complejidad detectado:

### Si es S (Simple):

Un prompt breve y directo. No más de 5-8 líneas. Incluye solo:
- Qué hacer exactamente (una instrucción clara)
- El archivo o ubicación específica si se conoce
- Una restricción si es relevante (qué no romper)

No añadas secciones, headers, ni estructura innecesaria. El prompt debe poder leerse de un vistazo.

---

### Si es M (Medio):

Un prompt estructurado pero conciso. Incluye solo las secciones que aporten valor real:
- **Objetivo**: qué se quiere lograr y por qué (2-3 líneas)
- **Qué hacer**: lista numerada de pasos o requisitos (solo los no obvios)
- **Archivos involucrados**: los relevantes, sin listar todo el proyecto
- **Restricciones**: máximo 2-3 cosas que no deben romperse

Omite secciones vacías o que repitan lo obvio.

---

### Si es L/XL (Complejo):

Un prompt completo con toda la estructura necesaria:

#### Contexto y objetivo
- Descripción precisa de qué se quiere lograr y por qué
- Stack técnico relevante y restricciones del proyecto
- Estado actual del sistema (qué existe hoy, qué falta)

#### Requisitos funcionales
- Lista numerada de comportamientos esperados
- Distingue obligatorios de opcionales
- Incluye casos límite y comportamientos ante errores

#### Requisitos no funcionales
- Rendimiento, seguridad, compatibilidad según aplique
- Convenciones de código del proyecto

#### Archivos y componentes involucrados
- Archivos que probablemente deban crearse o modificarse
- Dependencias o módulos relacionados

#### Criterios de aceptación
- Condiciones verificables de "terminado"

#### Restricciones explícitas
- Qué está fuera del alcance
- Qué no debe romperse

#### Instrucciones para Claude Code
- Si debe leer archivos antes de modificar
- Si debe pedir confirmación antes de cambios destructivos
- Orden preferido de implementación

---

Presenta el prompt mejorado dentro de un bloque de código markdown con triple backtick para que sea fácil de copiar:

```
[prompt mejorado aquí]
```

Después del bloque, una sola línea con: tipo de tarea (BUG FIX / FEATURE / REFACTOR / ARCHITECTURE / INVESTIGATION / PERFORMANCE), complejidad (S / M / L / XL), y el nivel usado.

---

**Tono:** imperativo, directo, técnico. Sin frases de relleno. Un prompt S debe tener la misma precisión que uno XL — solo menos volumen.
