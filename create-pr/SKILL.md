---
name: create-pr
description: Crea un Pull Request en GitHub via API REST usando curl, con token explícito por invocación para soportar múltiples cuentas/clientes en la misma máquina
user-invocable: true
argument-hint: <base-branch> <github-token>
---

## Contexto del repositorio

**Rama actual (head):**
!`git branch --show-current 2>/dev/null`

**Remote origin:**
!`git remote get-url origin 2>/dev/null`

**Commits de esta rama vs base:**
!`ARGS=($ARGUMENTS); BASE=${ARGS[0]:-main}; git log $BASE...HEAD --oneline 2>/dev/null || git log --oneline -10`

**Archivos modificados:**
!`ARGS=($ARGUMENTS); BASE=${ARGS[0]:-main}; git diff $BASE...HEAD --stat 2>/dev/null || git diff HEAD --stat`

**Diff:**
!`ARGS=($ARGUMENTS); BASE=${ARGS[0]:-main}; git diff $BASE...HEAD 2>/dev/null || git diff HEAD`

---

Eres un ingeniero de software senior. Tu tarea es crear un Pull Request en GitHub usando la API REST via curl.

Los argumentos recibidos son posicionales separados por espacio:
- **Argumento 1**: rama base (destino del PR, ej: `main`, `develop`)
- **Argumento 2**: GitHub personal access token

## Paso 1 — Validación

1. Si no se proporcionaron exactamente 2 argumentos: detente y muestra este mensaje:
   ```
   Uso: /create-pr <base-branch> <github-token>
   Ejemplo: /create-pr main ghp_xxxxxxxxxxxx
   ```
2. Si la rama actual es `main`, `master`, o `develop`: detente y avisa que probablemente no quiere abrir un PR desde esa rama.
3. Si no hay commits nuevos respecto a la base: detente y avisa que no hay cambios para abrir un PR.

## Paso 2 — Extracción de owner/repo

A partir de la URL del remote origin, extrae `owner` y `repo`:
- HTTPS: `https://github.com/owner/repo.git` → owner=`owner`, repo=`repo`
- SSH: `git@github.com:owner/repo.git` → owner=`owner`, repo=`repo`

## Paso 3 — Generación del PR

Genera:

**Título**: `tipo(scope opcional): descripción` siguiendo Conventional Commits. Máximo 72 caracteres. En inglés.

**Descripción** en markdown:

## Summary
[2-4 frases: qué cambia y por qué.]

## Changes
[Bullet points con los cambios significativos. Máximo 8 items.]

## Testing
[Pasos concretos para verificar que funciona.]

## Notes
[Solo si hay breaking changes o decisiones no obvias. Omitir si no aplica.]

## Checklist
- [ ] Tests añadidos o actualizados
- [ ] Documentación actualizada (si aplica)
- [ ] Sin breaking changes (o documentados arriba)

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
