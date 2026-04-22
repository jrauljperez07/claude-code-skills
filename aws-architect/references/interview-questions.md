# Interview Questions

Ask these **one at a time, in order**. Skip any already answered implicitly. Use multiple-choice when possible. Always offer a sensible default.

The senior-architect lens: we care about RPO/RTO, blast radius, data gravity, operational burden, and who's on call — not just "how many users."

---

## Block A — Problem domain

### A1. Dominio del sistema
> "Describe en 2-3 líneas qué hace el sistema y quién lo usa."

**Follow-up if vague:** "¿Es user-facing, B2B, interno, batch/pipeline, real-time?"

### A2. Criticidad de negocio
> "¿Qué pasa si este sistema se cae 1 hora en horario productivo? ¿Y 24 horas?"

Opciones:
- **(a) Nada crítico** — tolerable, pérdida menor.
- **(b) Impacto moderado** — usuarios molestos, revenue parcial afectado.
- **(c) Alto impacto** — revenue directo detenido, SLA con cliente.
- **(d) Crítico** — regulatorio, contractual con penalidades, seguridad.

Esto manda en SLA, DR y presupuesto.

---

## Block B — Volumen y escala

### B1. Volumen de usuarios / requests
> "¿Qué volumen esperas?"

- **(a) MVP / eval** — < 100 usuarios activos, tráfico esporádico.
- **(b) Producción baja** — ~1K usuarios, decenas de req/s sostenidos.
- **(c) Producción media** — ~10K usuarios, cientos de req/s, picos de miles.
- **(d) Producción alta** — 100K+ usuarios, miles de req/s sostenidos, picos mayores.

### B2. Datos almacenados
> "¿Cuántos GB/TB almacenas el año 1? ¿Y crecimiento anual?"

Necesario para storage tier (S3 Standard vs IA vs Glacier), DB sizing, backups.

### B3. Transferencia
> "¿Transferencia saliente aproximada? (datos que salen de AWS — egress es caro)"

---

## Block C — Disponibilidad y DR

### C1. SLA objetivo
> "¿Qué disponibilidad objetivo?"

- **(a) Single-AZ** — ~99% (ventanas de mantenimiento ok, costo mínimo).
- **(b) Multi-AZ** — ~99.9% (default para producción).
- **(c) Multi-región activo-pasivo** — ~99.95%.
- **(d) Multi-región activo-activo** — ~99.99% (complejidad y costo altos).

### C2. RPO — Recovery Point Objective
> "Si hay un desastre, ¿cuánto dato puedes permitirte perder?"

- **(a) 0 minutos** — replicación síncrona (Aurora Multi-AZ, DynamoDB Global Tables).
- **(b) < 5 minutos** — replicación asíncrona, backups frecuentes.
- **(c) < 1 hora** — snapshots cada hora.
- **(d) < 24 horas** — backup diario.

### C3. RTO — Recovery Time Objective
> "¿Cuánto tiempo máximo puede estar caído durante una recuperación?"

- **(a) < 5 min** — warm standby / pilot light en otra región.
- **(b) < 1 hora** — backup & restore con runbook probado.
- **(c) < 4 horas** — backup & restore sin automatización.
- **(d) < 24 horas** — recuperación manual.

---

## Block D — Compliance

### D1. Requisitos regulatorios
> "¿Qué compliance aplica? (múltiple selección)"

- GDPR (datos de usuarios europeos)
- HIPAA (salud US)
- PCI-DSS (tarjetas de crédito)
- SOC2 (auditorías enterprise)
- ISO 27001
- Residencia de datos específica (ej. datos deben quedarse en México / EU)
- Ninguno

**Follow-up si aplica alguno:** "¿Ya tienen BAA / DPA firmados con AWS?"

---

## Block E — Stack técnico

### E1. Lenguaje principal
> "¿Stack principal? (default: Python)"

Afecta: Lambda runtimes disponibles, ECS base images, Lambda cold start characteristics.

### E2. Base de datos
> "¿Tienes preferencia de DB? ¿Relacional (Postgres/MySQL) o NoSQL (DynamoDB/Mongo)? ¿Ya existe?"

### E3. Integraciones externas
> "¿Qué servicios externos consume o expone? (APIs de terceros, SFTP, webhooks, colas, eventos, etc.)"

### E4. Latencia requerida
> "¿Latencia aceptable por request (p95)? ¿Usuarios globales o regionales?"

---

## Block F — Observabilidad y operaciones

### F1. Observabilidad deseada
> "¿Qué nivel de observabilidad necesitas?"

- **(a) Básico** — CloudWatch Logs + métricas default.
- **(b) Medio** — CloudWatch + alarms + dashboards + X-Ray tracing.
- **(c) Alto** — todo lo anterior + stack externa (Datadog, Grafana Cloud, New Relic).

### F2. Equipo operador
> "¿Quién va a operar esto?"

- **(a) Solo desarrolladores** — inclinar máximo hacia managed services.
- **(b) Dev + 1 persona part-time de DevOps** — managed con algo de control.
- **(c) Equipo DevOps/Platform dedicado** — ECS/EKS válidos.
- **(d) SRE maduro** — cualquier opción viable.

### F3. CI/CD existente
> "¿Ya tienen pipeline de CI/CD? ¿Dónde? (GitHub Actions, GitLab CI, CodePipeline, etc.)"

---

## Block G — Presupuesto y timeline

### G1. Presupuesto
> "¿Hay un tope de costo mensual? Si no, te presento opciones MVP / baja / alta."

### G2. Timeline
> "¿Cuándo tiene que estar en producción?"

- **(a) MVP urgente** — semanas. Privilegiar camino rápido.
- **(b) Producción estándar** — 2-3 meses. Solución pulida.
- **(c) Estratégico** — 6+ meses. Arquitectura ideal, foundational.

### G3. Crecimiento esperado
> "En 12 meses, ¿esperas 2x, 10x, 100x de lo actual?"

Decide si vale la pena over-engineer desde ahora o iterar.

---

## Reglas al hacer preguntas

- **Una por mensaje.** Siempre.
- **Multiple choice cuando aplique** — reduce fricción.
- **Saltar las ya respondidas.** Si el brief inicial mencionó "10K usuarios", no preguntar B1.
- **Defaults visibles.** "Si no tienes opinión, voy con (b) multi-AZ."
- **Follow-up solo si la respuesta fue vaga** — no por deporte.
- **Parar a confirmar cada 4-5 preguntas** con un resumen breve: "Hasta aquí entiendo X, Y, Z. ¿Correcto?"
