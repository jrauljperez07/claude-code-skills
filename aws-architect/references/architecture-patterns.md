# Architecture Patterns

Canonical patterns. Present **2-3** to the user before committing. Each pattern includes: trade-offs, when to choose, when to avoid, and typical cost shape.

---

## Pattern 1 — Serverless API (Request-Response)

**Services:** API Gateway HTTP API + Lambda + DynamoDB + S3 + CloudFront + Cognito

**Use when:**
- Tráfico irregular o bursty.
- MVP con time-to-market corto.
- Equipo sin ops dedicados.
- Lógica de negocio stateless y rápida (< 15 min por request).

**Avoid when:**
- Tráfico sostenido alto (> 300 req/s constantes) → Fargate sale más barato.
- Latencia p99 crítica (cold starts).
- Workloads que requieren conexiones persistentes (WebSockets mejor, pero considerar).

**Trade-offs:**
- ✅ Cero servers que manejar, escala a 0.
- ✅ Pago por uso real.
- ❌ Vendor lock-in alto (DynamoDB, Lambda).
- ❌ Debugging distribuido requiere X-Ray.
- ❌ Límite de 15 min por invocación.

**Cost shape:** Muy barato en MVP, escala razonable hasta ~1M req/día; después evaluar migración.

---

## Pattern 2 — 3-Tier Containers (Request-Response sostenido)

**Services:** CloudFront + ALB + ECS Fargate + RDS Aurora (Multi-AZ) + ElastiCache Redis + S3

**Use when:**
- Tráfico sostenido alto.
- Stack con dependencias pesadas que no containeriza bien en Lambda.
- Equipo con experiencia en Docker.
- Necesitas conexiones persistentes, pooling de DB, long-running.

**Avoid when:**
- MVP con muy bajo tráfico (over-engineered).
- Equipo sin experiencia en contenedores.

**Trade-offs:**
- ✅ Predictible en costo a tráfico sostenido.
- ✅ Portable — Docker corre donde sea.
- ✅ Latencia consistente, sin cold starts.
- ❌ Hay que gestionar task definitions, desplegar imágenes, patching base image.
- ❌ Costo fijo por tener tareas corriendo aunque no haya tráfico.

**Cost shape:** Floor de ~$100-200/mes (ALB + Fargate mínimo + RDS Multi-AZ). Escala lineal con vCPU/mem.

---

## Pattern 3 — Event-Driven

**Services:** EventBridge + Lambda + SQS (DLQ) + DynamoDB Streams + S3 events + Step Functions

**Use when:**
- Lógica desacoplada por dominio.
- Integraciones con SaaS (Stripe, Segment, GitHub).
- Procesamiento asíncrono (webhooks, notificaciones, pipelines).
- Fan-out de un evento a múltiples consumers.

**Avoid when:**
- Necesitas respuesta síncrona al cliente.
- Equipo sin experiencia en patrones asíncronos (debugging puede ser duro).

**Trade-offs:**
- ✅ Desacoplamiento total, evolución independiente de productores y consumidores.
- ✅ Retries y DLQ built-in.
- ❌ Eventual consistency — hay que diseñar para idempotencia.
- ❌ Observabilidad requiere pensamiento extra (correlation IDs, distributed tracing).

**Cost shape:** Muy eficiente — pagas solo por eventos procesados.

---

## Pattern 4 — Data Lake / Analytics

**Services:** S3 + Glue (crawlers + catalog + ETL) + Athena + QuickSight + Lake Formation (governance)

**Use when:**
- Analytics sobre grandes volúmenes históricos.
- Queries ad-hoc de data scientists.
- Pipelines ETL batch.
- Múltiples fuentes heterogéneas.

**Avoid when:**
- OLTP (usa RDS/DynamoDB).
- Latencia de dashboards < 1s (usa Redshift o pre-agregados).

**Trade-offs:**
- ✅ Storage barato en S3.
- ✅ Athena escala automáticamente.
- ❌ Query performance depende mucho de particionado y formato (Parquet obligatorio).
- ❌ Athena cobra $5/TB scanned — malos queries salen caros.

---

## Pattern 5 — Real-Time Streaming

**Services:** Kinesis Data Streams + Lambda o Flink (on KDA) + DynamoDB / OpenSearch + Kinesis Firehose → S3

**Use when:**
- IoT, telemetría, clickstream, fraud detection en tiempo real.
- Necesitas replay o múltiples consumers del mismo stream.
- Latencia de procesamiento < 1 min.

**Avoid when:**
- Volumen bajo o irregular → SQS basta.
- Equipo sin experiencia en streaming.

**Trade-offs:**
- ✅ Escala masivamente.
- ✅ Replay histórico hasta 365 días.
- ❌ Complejidad operativa real.
- ❌ Particionado (shards) requiere diseño cuidadoso.

---

## Pattern 6 — Static Site + API

**Services:** S3 + CloudFront + ACM + Route 53 + API Gateway + Lambda + Cognito

**Use when:**
- Frontend SPA (React/Vue/Next static export) + backend API.
- Marketing sites, docs, portales.
- Time-to-market ultra-rápido.

**Trade-offs:**
- ✅ Muy barato, muy rápido.
- ❌ Sin SSR (considerar Amplify Hosting o CloudFront Functions para edge SSR).

---

## Pattern 7 — Microservicios en Fargate

**Services:** ALB interno + ECS Fargate + Service Discovery (Cloud Map) + App Mesh (opcional) + RDS/Dynamo + ECR + CodeDeploy

**Use when:**
- 5+ servicios con ownership diferente.
- Necesitas comunicación service-to-service dentro de VPC.
- Deploy independiente por servicio.

**Avoid when:**
- < 4 servicios — monolito o 2-tier basta.
- Equipo pequeño sin capacidad de operar.

---

## Pattern 8 — Batch processing

**Services:** S3 (input) + AWS Batch o Step Functions + ECS/Fargate o Lambda + S3 (output) + SNS (notif)

**Use when:**
- Jobs programados (cron en EventBridge Scheduler).
- Procesamiento largo que no cabe en Lambda.
- Pipelines científicos / ML training.

---

## Cómo elegir entre patrones

Matriz rápida:

| Señal | Patrón probable |
|---|---|
| Tráfico bursty, MVP | Serverless (1) |
| Tráfico sostenido > 300 req/s | Containers (2) |
| Múltiples dominios, async | Event-driven (3) |
| "Quiero hacer queries sobre logs/eventos" | Data Lake (4) |
| IoT / telemetría | Streaming (5) |
| Landing page + formulario | Static + API (6) |
| 5+ servicios con ownership distinto | Microservicios (7) |
| Jobs batch / ML | Batch (8) |

**Combinaciones comunes:**
- (1) + (3): app serverless con eventos desacoplados.
- (2) + (4): producción Fargate + analytics side.
- (6) + (1): frontend estático + backend serverless.
- (3) + (5): eventos + stream para analytics real-time.

---

## Presentación al usuario

Para cada propuesta usa este formato:

```
### Opción X — <nombre>

**Qué es:** 1 línea.
**Servicios:** lista corta.
**Por qué encaja aquí:** 2-3 líneas conectando al requisito del usuario.
**Trade-offs:**
- ✅ ventaja concreta
- ✅ ventaja concreta
- ❌ desventaja concreta
- ❌ desventaja concreta
**Costo aproximado mensual:** rango.
**Quién lo opera bien:** perfil de equipo.
```

Termina con: "**Mi recomendación: X porque Y.** ¿Qué te late?"
