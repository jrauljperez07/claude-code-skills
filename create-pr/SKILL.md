---
name: create-pr
description: Crea un Pull Request en GitHub via API REST usando curl, con token explícito por invocación para soportar múltiples cuentas/clientes en la misma máquina
user-invocable: true
argument-hint: [/path/to/repo] [base-branch] [github-token]
---

## Contexto del repositorio

**Rama actual (head):**
!`git branch --show-current`

**Remote origin:**
!`git remote get-url origin`

**Commits recientes:**
!`git log --oneline -10`

**Diff stat:**
!`git diff HEAD --stat`

**Argumentos recibidos:**
$ARGUMENTS

---

Eres un ingeniero de software senior. Tu tarea es crear un Pull Request en GitHub usando la API REST via curl.

## Paso 0 — Recolección de argumentos

`$ARGUMENTS` puede venir en dos formatos — interprétalos con flexibilidad:

**Formato posicional**: `[/path/to/repo] [base-branch] [github-token]`
- Si el primer token es una ruta existente: es el path del repo; segundo = rama base; tercero = token.
- Si el primer token no es una ruta: primer = rama base; segundo = token.

**Formato lenguaje natural**: el usuario puede escribir cosas como:
- `"Crea el PR de la rama que acabas de crear a dev"`
- `"de feat/add-auth a dev con token ghp_xxx"`
- `"a staging"`

En este caso, extrae semánticamente:
- **rama head**: si la menciona explícitamente úsala; si dice "la rama que acabas de crear" o similar, usa la rama actual del contexto de la conversación o corre `git branch --show-current`
- **rama base**: detecta menciones de `main`, `dev`, `develop`, `staging`, `production` u otras ramas
- **token**: cualquier string que empiece con `ghp_`, `github_pat_` u otro formato de token

Si se proporcionó un path de repo, usa el Bash tool para correr `git -C <path> branch --show-current`, `git -C <path> remote get-url origin` y `git -C <path> log --oneline -10` para reemplazar el contexto capturado arriba.

**Para cualquier dato que falte**, pregunta de forma conversacional antes de continuar:

> Claro, voy a crear el PR. Solo me falta:
> 1. ¿Tu GitHub personal access token? (no lo mostraré en ningún output)

Si ya tienes todos los datos, procede directamente sin preguntar.

## Paso 1 — Validación

1. Si la rama actual es `main`, `master`, o `develop`: avisa que probablemente no quiere abrir un PR desde esa rama y pregunta si desea continuar.
2. Si no hay commits nuevos respecto a la base: detente y avisa que no hay cambios para abrir un PR.

## Paso 2 — Extracción de owner/repo

A partir de la URL del remote origin, extrae `owner` y `repo`:
- HTTPS: `https://github.com/owner/repo.git` → owner=`owner`, repo=`repo`
- SSH: `git@github.com:owner/repo.git` → owner=`owner`, repo=`repo`

## Paso 3 — Generación del PR

Antes de escribir la descripción, analiza el diff completo con `git diff <base>...HEAD` (o `git -C <path> diff <base>...HEAD`) para tener el detalle exacto de cada cambio.

**Título**: `tipo(scope opcional): descripción` siguiendo Conventional Commits. Máximo 72 caracteres. En inglés.

**Descripción** en markdown — debe ser detallada y específica, no genérica:

---

## What & Why
[2-4 frases explicando qué problema resuelve este PR y por qué se hizo este cambio. No copies el título.]

## Changes

### New files
[Lista cada archivo nuevo con una línea explicando qué hace y por qué existe. Omite esta sección si no hay archivos nuevos.]
- `ruta/del/archivo.ts` — [qué hace este archivo]

### Modified files
[Lista cada archivo modificado con una descripción específica del cambio, no solo "modified". Incluye el impacto del cambio.]
- `ruta/del/archivo.ts` — [qué cambió exactamente y por qué]

### Deleted files
[Solo si aplica.]
- `ruta/del/archivo.ts` — [por qué se eliminó]

## Behavior changes
[Describe cómo cambia el comportamiento observable para el usuario o para otros sistemas. Si no hay cambio de comportamiento visible (ej: refactor interno), escribe "No user-facing behavior changes".]

## How to test
[Pasos concretos y reproducibles para verificar que funciona correctamente. No escribas pasos genéricos como "run the app".]
1. [Paso específico]
2. [Paso específico]
3. Expected result: [qué debe verse]

## Breaking changes
[Si hay cambios que rompen compatibilidad hacia atrás, descríbelos aquí con el impacto y la migración necesaria. Si no los hay, omite esta sección.]

## Notes
[Decisiones de diseño no obvias, deuda técnica introducida intencionalmente, o contexto que el reviewer necesita saber. Omite si no aplica.]

---

## Paso 4 — Ejecución via curl

Construye y ejecuta el siguiente comando. Los saltos de línea en el body deben escaparse como `\n`:

```bash
curl -s -X POST \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/<OWNER>/<REPO>/pulls \
  -d '{
    "title": "<título generado>",
    "body": "<descripción generada con \\n en lugar de saltos de línea>",
    "head": "<rama-actual>",
    "base": "<rama-base>"
  }'
```

Sustituye `<TOKEN>`, `<OWNER>`, `<REPO>`, `<rama-actual>`, y `<rama-base>` con los valores reales antes de ejecutar.

## Paso 5 — Resultado

Parsea la respuesta JSON del curl:
- Si contiene `"html_url"`: muestra la URL del PR creado. Éxito.
- Si contiene `"message"` con un error: muestra el mensaje de error de GitHub y la causa probable (token inválido, rama ya tiene PR abierto, permisos insuficientes, etc.).

---

Reglas:
- NO imprimas el token en ningún output visible al usuario
- NO pidas confirmación antes de ejecutar
- Si el body de la descripción contiene comillas dobles, escápalas como `\"`
