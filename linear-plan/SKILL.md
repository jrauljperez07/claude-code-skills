---
name: linear-plan
description: Toma el contenido de una tarjeta de Linear, analiza el repositorio actual, delimita el alcance real de la tarea y genera un plan de implementación detallado por fases
user-invocable: true
argument-hint: <contenido de la tarjeta Linear>
---

## Tarjeta Linear

> $ARGUMENTS

---

## Contexto del repositorio

**Estructura del proyecto:**
!`ls -1 2>/dev/null | head -40`

**Rama actual:**
!`git branch --show-current 2>/dev/null || echo "N/A"`

**Archivos modificados recientemente:**
!`git log --oneline -5 2>/dev/null || true`

**Estructura de directorios (2 niveles):**
!`find . -maxdepth 2 -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*" -not -path "*/venv/*" 2>/dev/null | head -40`

---

Eres un ingeniero de software senior con experiencia en planificación de tareas técnicas. Tu misión es tomar la tarjeta de Linear y convertirla en un plan de implementación concreto y ejecutable, adaptado al repositorio actual.

---

## PASO 1 — Extracción del contexto

Identifica en la tarjeta:
- **Título** de la tarea
- **Tipo** de trabajo: feature / bug / refactor / investigación / infra
- **Descripción** y contexto de negocio
- **Criterios de aceptación** si los hay (explícitos o implícitos)
- **Dependencias** mencionadas (otras tareas, servicios, equipos)

Si la tarjeta no tiene criterios de aceptación claros, infiere los mínimos necesarios para considerar la tarea terminada.

---

## PASO 2 — Delimitación del alcance

Define con precisión:

**Qué está DENTRO del alcance**
Lista de lo que se debe implementar para cumplir la tarjeta, sin más ni menos.

**Qué está FUERA del alcance**
Lo que podría parecer relacionado pero no es parte de esta tarjeta. Esto previene scope creep.

**Supuestos**
Decisiones que se asumen como verdaderas para poder planificar. Si algún supuesto es incorrecto, el plan puede cambiar.

**Riesgos e incógnitas**
Qué podría bloquear la implementación o requerir decisiones antes de empezar.

---

## PASO 3 — Plan de implementación

Descompón la implementación en fases ordenadas. Cada fase debe ser:
- Completable de forma independiente
- Verificable antes de pasar a la siguiente
- Estimada en S / M / L (horas de trabajo, no de espera)

Formato de cada fase:

### Fase N: [Nombre descriptivo] — [S/M/L]
**Objetivo**: qué se logra al completar esta fase
**Archivos a crear o modificar**: lista con el cambio esperado en cada uno
**Pasos**:
1. Paso concreto y ejecutable
2. ...
**Verificación**: cómo confirmar que esta fase está correcta antes de continuar

---

## PASO 4 — Criterios de aceptación técnicos

Traduce los criterios de negocio de la tarjeta a condiciones técnicas verificables:

- [ ] Criterio 1 (formulado como: dado X, cuando Y, entonces Z)
- [ ] Criterio 2
- [ ] ...

Añade criterios técnicos implícitos que la tarjeta no menciona pero son necesarios (tests, manejo de errores, logging).

---

## PASO 5 — Estimación total

| Fase | Estimación | Dependencias |
|------|-----------|--------------|
| Fase 1 | S/M/L | - |
| Fase 2 | S/M/L | Fase 1 |
| ... | | |
| **Total** | | |

Indica el camino crítico si hay fases que pueden ir en paralelo.

---

**Tono**: técnico y directo. El plan debe poder entregarse a otro ingeniero y que lo ejecute sin preguntas. No incluyas frases de relleno ni justificaciones obvias.
