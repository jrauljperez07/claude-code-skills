---
name: scaffold
description: Lee las convenciones del proyecto actual y genera todos los archivos base para una nueva feature, módulo, o componente — listos para implementar, sin boilerplate manual
user-invocable: true
argument-hint: <descripción de la feature o módulo a crear>
---

## Feature a crear

> $ARGUMENTS

---

## Contexto del proyecto

**Estructura raíz:**
!`ls -1 2>/dev/null`

**Estructura de directorios (3 niveles, sin deps):**
!`find . -maxdepth 3 -type d -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/__pycache__/*" -not -path "*/venv/*" -not -path "*/.venv/*" -not -path "*/dist/*" -not -path "*/.next/*" -not -path "*/build/*" 2>/dev/null | sort | head -60`

**Stack detectado:**
!`ls package.json pyproject.toml requirements.txt go.mod Cargo.toml 2>/dev/null`

**Archivos de configuración relevantes:**
!`cat package.json 2>/dev/null | head -20 || cat pyproject.toml 2>/dev/null | head -20`

**Ejemplos de archivos existentes (para extraer convenciones):**
!`find . -maxdepth 4 -name "*.ts" -o -name "*.tsx" -o -name "*.py" 2>/dev/null | grep -v node_modules | grep -v __pycache__ | grep -v ".next" | head -15`

**Muestra de un módulo existente (convenciones de naming y estructura):**
!`find . -maxdepth 4 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" \) | grep -v node_modules | grep -v __pycache__ | grep -v ".next" | grep -v "test" | grep -v "spec" | head -3 | xargs head -30 2>/dev/null`

---

Eres un ingeniero de software senior. Tu misión es generar el scaffold completo para la feature descrita, respetando exactamente las convenciones del proyecto — no las tuyas propias.

---

## PASO 1 — Análisis de convenciones

Antes de crear nada, extrae del código existente:

- **Naming**: camelCase, snake_case, PascalCase — para archivos, carpetas, funciones, clases
- **Estructura de módulos**: cómo se organizan los archivos de un feature existente (ej: router/controller/service/repository, o components/hooks/types, etc.)
- **Patrones de imports**: rutas absolutas o relativas, alias configurados
- **Patrones de exports**: named exports, default exports, barrel files (index.ts)
- **Estructura de un archivo típico**: orden de imports, tipos, función principal, exports

Si no hay suficientes ejemplos para inferir las convenciones con certeza, usa las convenciones más comunes del stack detectado.

---

## PASO 2 — Definición del scaffold

Basándote en la feature descrita y las convenciones detectadas, define:

1. **Qué archivos crear** y en qué rutas exactas
2. **Qué contiene cada archivo**: solo el esqueleto — imports necesarios, tipos/interfaces, firma de funciones con `pass` o `// TODO: implement`, y exports. Sin lógica de negocio.
3. **Qué archivos existentes modificar** para registrar la nueva feature (ej: router principal, index de exports, configuración)

---

## PASO 3 — Creación

Crea todos los archivos usando las herramientas disponibles (Write/Edit). Para cada archivo:

- Respeta exactamente el naming y estructura detectados
- Incluye los imports reales que va a necesitar (no placeholders genéricos)
- Añade un comentario `// TODO: implement` o `# TODO: implement` en el cuerpo de cada función
- Si el archivo es un barrel (index.ts / __init__.py), expórtalo correctamente

Modifica los archivos existentes que necesiten registrar la nueva feature (agregar la ruta al router, exportar desde el index, etc.).

---

## PASO 4 — Resumen

Al terminar, muestra:

```
Archivos creados:
  + ruta/del/archivo.ts
  + ruta/del/otro.ts
  ...

Archivos modificados:
  ~ ruta/existente.ts  (línea añadida: ...)
  ...

Siguiente paso:
  /prompt-enhancer <descripción de la primera función a implementar>
```

---

**Reglas:**
- Crea archivos reales en el repo — no muestres código en el chat para que el usuario copie
- Nunca sobreescribas archivos existentes con contenido diferente al que tenían, solo modifícalos para registrar la nueva feature
- Si la feature es ambigua en su estructura, elige el patrón más simple que resuelva el caso
- El scaffold debe estar listo para que el siguiente comando sea implementar lógica, no reorganizar archivos
