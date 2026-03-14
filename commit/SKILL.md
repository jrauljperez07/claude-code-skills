---
name: commit
description: Genera un mensaje de commit semántico leyendo el staged diff y ejecuta git commit automáticamente
user-invocable: true
argument-hint: [contexto adicional opcional]
---

## Contexto

**Cambios staged:**
!`git diff --cached 2>/dev/null`

**Archivos staged:**
!`git diff --cached --stat 2>/dev/null`

**Historial reciente (para detectar convención del repo):**
!`git log --oneline -10 2>/dev/null`

**Contexto adicional del usuario:**
!`echo "${ARGUMENTS:-Sin contexto adicional}"`

---

Eres un ingeniero de software senior. Tu tarea es generar un mensaje de commit semántico y ejecutarlo.

## Paso 1 — Validación

Verifica:
1. Si no hay cambios staged (`git diff --cached` está vacío): detente y avisa al usuario que ejecute `git add <archivos>` primero.
2. Si los cambios staged mezclan concerns no relacionados (ej: un bugfix + un refactor + un feature nuevo): avisa al usuario que considera separarlo en commits atómicos, pero procede igualmente con un mensaje que cubra el cambio principal.

## Paso 2 — Detección de convención

Analiza el historial reciente para detectar si el repo usa:
- **Conventional Commits**: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, `perf:`, `ci:` — usa este formato si se detecta
- **Convención propia**: imita el patrón existente
- **Sin convención clara**: usa Conventional Commits por defecto

## Paso 3 — Generación del mensaje

Genera el mensaje de commit con esta estructura:

**Subject line**: `tipo(scope opcional): descripción en imperativo` — máximo 72 caracteres
**Body (opcional)**: Solo si el cambio necesita explicar el *por qué* (no el qué, eso está en el diff). Separado por una línea en blanco. Máximo 3-4 líneas.

Reglas del subject:
- Usa imperativo: "add", "fix", "remove" — no "added", "fixes", "removed"
- No termines con punto
- El scope es el módulo o área afectada (ej: `auth`, `api`, `ui`) — omítelo si el cambio es transversal
- Sé específico: "fix null pointer in user session expiry" > "fix bug"

## Paso 4 — Ejecución

Ejecuta el commit con las herramientas disponibles:

```
git commit -m "<subject>" -m "<body si aplica>"
```

Después:
- Si fue exitoso: muestra el hash corto del commit y el subject.
- Si falló (ej: pre-commit hook): muestra el error completo y explica qué lo causó.

---

Reglas:
- Escribe el mensaje en inglés
- NO pidas confirmación — el usuario ya tiene los archivos staged y llamó a la skill con intención de commitear
- Si `$ARGUMENTS` tiene contexto adicional, úsalo para enriquecer el mensaje pero no lo copies literalmente
