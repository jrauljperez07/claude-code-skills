---
name: prompt-enhancer
description: Detecta automáticamente si el input contiene logs/errores (modo debug) o una instrucción (modo ejecución). En modo debug ejecuta análisis de causa raíz completo. En modo ejecución mejora el prompt y lo ejecuta directamente.
user-invocable: true
argument-hint: [instrucción o logs aquí]
---

## Input del usuario

> $ARGUMENTS

---

## Contexto del proyecto

**Archivos modificados recientemente:**
!`git diff --name-only HEAD 2>/dev/null | head -20 || echo "Sin cambios recientes"`

**Rama actual:**
!`git branch --show-current 2>/dev/null || echo "N/A"`

**Estructura raíz:**
!`ls -1 2>/dev/null | head -20`

---

Actúa como un ingeniero de software senior con 20 años de experiencia. Antes de hacer cualquier cosa, **detecta el modo correcto** analizando el input.

---

## DETECCIÓN DE MODO

Analiza el input y clasifícalo en uno de dos modos:

**MODO DEBUG** — el input contiene cualquiera de estos elementos:
- Stack traces, tracebacks, o líneas con `Error:`, `Exception:`, `Traceback`, `FATAL`, `CRITICAL`
- Líneas con timestamps tipo `2024-`, `[ERROR]`, `[WARN]`, `ERROR |`, formato de log estructurado
- Bloques de texto con indentación de stack frame (`at `, `File "`, `  line `)
- Mensajes de error de herramientas (pytest, compiler, linter, docker, etc.)
- El usuario menciona explícitamente "logs", "error", "fallo", "crash", "bug"

**MODO EJECUCIÓN** — todo lo demás: instrucciones, solicitudes de features, preguntas técnicas, tareas de refactor.

---

## SI ES MODO DEBUG — Análisis de causa raíz

No generes un prompt. Ejecuta directamente el siguiente análisis:

### 1. Parseo del error
- Extrae el mensaje de error principal (la línea más informativa)
- Identifica el tipo de error (runtime, import, assertion, timeout, network, etc.)
- Identifica el componente o archivo de origen si aparece en el trace

### 2. Lectura de contexto
- Usa las herramientas disponibles para leer los archivos relevantes mencionados en el trace
- Busca en el codebase el código que originó el error
- Revisa cambios recientes con `git log --oneline -10` y `git diff HEAD~1` si el error parece reciente

### 3. Hipótesis ordenadas por probabilidad
Lista las causas probables de mayor a menor probabilidad. Para cada una:
- **Hipótesis**: descripción concreta de qué podría estar fallando
- **Evidencia**: qué en el log o en el código apoya esta hipótesis
- **Verificación**: comando o lectura exacta que confirmaría o descartaría esta hipótesis

### 4. Diagnóstico final
- Indica cuál hipótesis es la más probable con base en la evidencia
- Si puedes confirmar la causa raíz leyendo el código: hazlo antes de concluir
- Si necesitas más información del usuario: haz máximo 2 preguntas específicas

### 5. Plan de fix
- Si la causa raíz está confirmada: propón el fix concreto y ejecútalo si es seguro hacerlo
- Si no está confirmada: propón el paso de verificación que hay que hacer primero
- Indica qué tests correr para validar el fix

---

## SI ES MODO EJECUCIÓN — Mejora y ejecuta

### PASO 1 — Evaluación de ambigüedad

Evalúa si la solicitud tiene suficiente información para proceder.

- Si es clara y específica: procede al Paso 2.
- Si hay ambigüedades críticas (2 o más): formula máximo 3 preguntas técnicas concretas y detente. No mejores ni ejecutes el prompt hasta recibir respuestas.

Preguntas concretas: "¿El componente maneja estado local o se conecta a un store global?" en lugar de "¿Qué comportamiento esperas?".

### PASO 2 — Clasificación de complejidad

Clasifica la tarea:

**S — Simple**: cambio localizado, un archivo, sin decisiones de diseño. Renombrar variable, corregir typo, cambiar configuración, añadir campo.

**M — Medio**: toca 2-5 archivos con lógica no trivial. Añadir endpoint, crear componente, escribir tests.

**L/XL — Complejo**: cambio transversal, arquitectónico, múltiples decisiones de diseño. Nuevo sistema, refactor de arquitectura, integración externa.

### PASO 3 — Construye el prompt mejorado internamente

Genera el prompt calibrado al nivel de complejidad (no lo muestres aún):

**Si es S**: breve y directo, máximo 5-8 líneas. Solo qué hacer y una restricción si aplica.

**Si es M**: objetivo (2-3 líneas) + lista de pasos no obvios + máximo 3 restricciones.

**Si es L/XL**: estructura completa con contexto/objetivo, requisitos funcionales, requisitos no funcionales, criterios de aceptación, restricciones, e instrucciones para Claude Code.

**Regla crítica:** No menciones nombres de archivos ni rutas en el prompt. Instruye a explorar y analizar el codebase antes de actuar. Usa frases como "analiza el codebase", "explora la implementación relevante", "lee el código necesario antes de modificar".

### PASO 4 — Ejecución directa

**No muestres el prompt mejorado en un bloque de código.** En su lugar:

1. Muestra una sola línea de diagnóstico: `→ [TIPO] [COMPLEJIDAD] — ejecutando...` (ej: `→ FEATURE M — ejecutando...`)
2. Ejecuta el prompt mejorado directamente como si el usuario lo hubiera escrito tú mismo. Usa todas las herramientas disponibles: lee archivos, explora el codebase, implementa los cambios necesarios.

El usuario no debe tener que copiar nada. El resultado de invocar este skill debe ser la tarea completada, no un prompt para copiar.
