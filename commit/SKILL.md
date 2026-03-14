---
name: commit
description: Genera un mensaje de commit semántico, stagea todos los cambios automáticamente y ejecuta git commit
user-invocable: true
argument-hint: [/path/to/repo] [contexto adicional opcional]
---

## Contexto

**Cambios sin stagear:**
!`git status --short 2>/dev/null || true`

**Historial reciente (para detectar convención del repo):**
!`git log --oneline -10 2>/dev/null || true`

**Argumentos recibidos:**
$ARGUMENTS

---

Eres un ingeniero de software senior. Tu tarea es stagear todos los cambios, generar un mensaje de commit semántico y ejecutarlo.

## Paso 0 — Parseo de argumentos

Analiza `$ARGUMENTS`:
- Si el **primer token** es una ruta (empieza con `/`, `./`, `~/` o es un nombre de directorio que existe), úsala como el directorio del repo. Usa el Bash tool para correr `git -C <path> status --short` y `git -C <path> log --oneline -10` para obtener el contexto real de ese repo.
- El resto de tokens (o todo si no hay ruta) es el **contexto adicional** del usuario.

## Paso 1 — Staging automático

Ejecuta `git add -A` (o `git -C <path> add -A` si se proporcionó un path) para stagear todos los cambios antes de hacer el diff.

Luego obtén el diff completo con `git diff --cached` (o `git -C <path> diff --cached`).

Si después del `git add -A` no hay nada staged (repo limpio): informa al usuario que no hay cambios y detente.

## Paso 1.5 — Protección de ramas base

Obtén la rama actual con `git branch --show-current` (o `git -C <path> branch --show-current`).

Si la rama actual es `main`, `master`, `dev`, `develop`, `staging` o `production`:
1. **No hagas el commit en esa rama.**
2. Genera un nombre de rama basado en el tipo y descripción del commit que vas a generar. Formato: `tipo/descripcion-en-kebab-case`. Ejemplos: `feat/add-forgot-password-flow`, `fix/sidebar-user-profile-crash`.
3. Crea y posiciónate en la nueva rama: `git checkout -b <nombre-rama>` (o `git -C <path> checkout -b <nombre-rama>`).
4. Informa al usuario: "Estabas en `<rama-protegida>`. Creé la rama `<nombre-rama>` y haré el commit ahí."

Si la rama actual ya es una rama de feature, procede normalmente.

## Paso 2 — Detección de scope

Determina el scope basándote en el nombre o contenido del repo:
- Si el repo contiene `package.json`, `tsconfig.json`, componentes React, Next.js, o su nombre incluye palabras como `frontend`, `web`, `app`, `ui` → scope: **`frontend`**
- Si el repo contiene `requirements.txt`, `pyproject.toml`, `FastAPI`, `app/routers`, o su nombre incluye `backend`, `api`, `service`, `inference`, `management` → scope: **`backend`**
- Si es ambiguo, usa el área más afectada por los cambios (ej: `auth`, `chat`, `billing`)

## Paso 3 — Detección de convención

Analiza el historial reciente para detectar si el repo usa Conventional Commits u otra convención. Si no hay convención clara, usa Conventional Commits por defecto.

## Paso 4 — Generación del mensaje

Genera el mensaje con esta estructura:

**Subject line**: `tipo(scope): descripción en imperativo` — máximo 72 caracteres
**Body (opcional)**: Solo si el cambio necesita explicar el *por qué*. Separado por línea en blanco. Máximo 3-4 líneas.

Reglas:
- Usa imperativo: "add", "fix", "remove" — no "added", "fixes", "removed"
- No termines con punto
- Sé específico: "add forgot-password flow with Cognito OTP" > "add auth feature"

## Paso 5 — Ejecución

Ejecuta el commit:
```
git [-C <path>] commit -m "<subject>" [-m "<body>"]
```

Después:
- Si fue exitoso: muestra el hash corto del commit y el subject. Si se creó una rama nueva, recuérdale al usuario que puede abrir el PR con `/create-pr`.
- Si falló (ej: pre-commit hook): muestra el error completo y explica qué lo causó.

---

Reglas:
- Escribe el mensaje en inglés
- NO pidas confirmación — el usuario llamó a la skill con intención de commitear todo
- Si hay contexto adicional en los argumentos, úsalo para enriquecer el mensaje pero no lo copies literalmente
- NUNCA añadas `Co-Authored-By`, trailers de autoría, ni ninguna referencia a Claude o Anthropic en el mensaje del commit
