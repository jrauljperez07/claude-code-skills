# AWS Service Catalog

Mapping from requirement → candidate AWS services. Each entry: **when to choose**, **when NOT to**, **common alternatives**.

Precios que aparecen aquí son "orden de magnitud" — confirmar con WebFetch a `aws.amazon.com/*/pricing/` antes de ponerlos en el entregable.

---

## 1. Compute

### Lambda
- **Choose:** bursts irregulares, event-driven, < 15 min por invocación, bajo uso sostenido, stacks Python/Node/Go, cuando quieres olvidarte del servidor.
- **Avoid:** carga sostenida alta (sale más caro que Fargate desde ~300 req/s constantes), cold start crítico (latencia p99), workloads con GPU, long-running.
- **Alternatives:** Fargate, App Runner.
- **Cost shape:** $0.20 / 1M requests + $0.0000166667 / GB-s. SnapStart para Java, provisioned concurrency para cold starts.

### ECS Fargate
- **Choose:** contenedores, carga sostenida, microservicios, cuando quieres abstracción sobre EC2 sin pagar Lambda por invocación, stacks con dependencias pesadas.
- **Avoid:** batch puntual (usa AWS Batch), cuando necesitas control de kernel/daemons (usa EC2), equipos sin experiencia en Docker.
- **Alternatives:** EKS Fargate (si ya usan Kubernetes), App Runner (más simple), Lambda (si bursts), EC2 (si necesitas tuning).
- **Cost shape:** $0.04048/vCPU-hora + $0.004445/GB-hora (us-east-1). Savings Plans reducen 20-50%.

### EKS
- **Choose:** equipo ya opera Kubernetes, necesidad de portabilidad multi-cloud, ecosistema K8s (Helm, operators), workloads complejos con service mesh.
- **Avoid:** equipo sin experiencia K8s (el overhead operativo es real), caso simple de 3-4 servicios.
- **Alternatives:** ECS (más simple en AWS), Fargate con ECS.

### EC2
- **Choose:** control total, GPU, licencias específicas (Oracle, SAP), software legacy que no containeriza, HPC.
- **Avoid:** casi todo lo nuevo — el costo operativo (patching, scaling, monitoring) es real.
- **Alternatives:** casi siempre preferir Fargate o Lambda.

### App Runner
- **Choose:** MVP ultra-rápido, push-to-deploy desde ECR o GitHub, no quieres pensar en nada.
- **Avoid:** necesitas VPC endpoints custom, autoscaling granular, workloads complejos.

### Batch
- **Choose:** jobs batch que corren horas, procesamiento paralelo de muchas tareas, pipelines científicos.

---

## 2. Storage

### S3
- **Choose:** prácticamente cualquier blob storage. 99.999999999% durabilidad. Lifecycle a IA/Glacier.
- **Classes:**
  - Standard: $0.023/GB/mes, hot data.
  - Standard-IA: $0.0125/GB/mes, acceso infrecuente, retrieval fee.
  - Intelligent-Tiering: automático, buen default si no sabes el patrón.
  - Glacier Instant: $0.004/GB/mes, archivo con acceso ms.
  - Glacier Deep Archive: $0.00099/GB/mes, backup a largo plazo.
- **Gotchas:** requests cuestan ($0.005/1K PUTs), cross-region replication es costosa, egress.

### EBS
- **Choose:** volumen de bloque para EC2/Fargate persistent.
- **Types:** gp3 (default moderno, más barato que gp2), io2 (IOPS garantizados).

### EFS
- **Choose:** NFS compartido entre múltiples instancias/containers, workloads con file-system traditional, Lambda que necesita > 512MB temp.
- **Avoid:** alta performance (usa FSx), casos donde S3 basta.

### FSx
- **Variants:** for Lustre (HPC), for Windows File Server, for NetApp ONTAP, for OpenZFS. Casos específicos.

---

## 3. Databases

### RDS (Postgres / MySQL / MariaDB / Oracle / SQL Server)
- **Choose:** DB relacional managed, default para cualquier app CRUD estándar.
- **Avoid:** escala write > 1 instancia (→ Aurora), workloads con latencia sub-ms (→ DynamoDB o cache).
- **Key configs:** Multi-AZ (duplica costo, da failover automático), read replicas, backups automáticos.

### Aurora (Postgres / MySQL compatible)
- **Choose:** alta disponibilidad (storage replicated across 3 AZs), alta performance, lecturas escalables con readers.
- **Avoid:** MVP con presupuesto mínimo (sale más caro que RDS vanilla), cuando hay vendor lock-in concern.
- **Variants:** Aurora Serverless v2 (escala CPU/mem en segundos, bueno para dev/stg y workloads variables), provisioned.

### DynamoDB
- **Choose:** escala masiva, sub-ms latencia, single-digit-ms p99, patrón de acceso conocido, event-driven con Streams.
- **Avoid:** queries ad-hoc complejos, joins, cuando el modelo de acceso va a cambiar mucho.
- **Modes:** On-demand (paga por request, $1.25/1M writes) vs Provisioned (capacity units, ideal si tráfico predecible).
- **Features:** Global Tables (multi-región), TTL, Streams (→ Lambda).

### ElastiCache (Redis / Memcached)
- **Choose:** caché, sesiones, rate limiting, leaderboards, pub/sub.
- **Redis:** más features (persistence, pub/sub, sorted sets). Default.
- **Memcached:** más simple, multi-threaded.
- **Serverless option:** ElastiCache Serverless (nueva), vale la pena para workloads variables.

### DocumentDB
- **Choose:** MongoDB-compatible managed. Solo si ya viene una app con Mongo.
- **Avoid:** greenfield — considera DynamoDB o Aurora + JSONB.

### Neptune
- **Choose:** grafos (knowledge graph, fraud detection, recomendaciones).

### OpenSearch
- **Choose:** búsqueda full-text, analytics, logs centralizados, dashboards tipo Kibana.
- **Gotcha:** caro a escala. Considera serverless variant.

### Timestream
- **Choose:** time-series (IoT, métricas custom, telemetría).
- **Avoid:** serverless variant aún madurando.

### Redshift
- **Choose:** data warehouse petabyte-scale, SQL analytics.
- **Avoid:** OLTP, bajo volumen (usa Athena + S3).

### Athena
- **Choose:** queries SQL sobre S3, data lake pattern, bajo volumen o irregular.
- **Cost:** $5/TB scanned — Parquet + particiones son críticos.

---

## 4. Networking

### VPC
- **Choose:** siempre.
- **Pattern:** public subnets (ALB, NAT GW) + private subnets (compute) + db subnets (RDS).

### ALB (Application Load Balancer)
- **Choose:** HTTP/HTTPS layer 7, WebSockets, gRPC, path-based routing, host-based routing.
- **Cost:** $0.0225/hora + LCU.

### NLB (Network Load Balancer)
- **Choose:** TCP/UDP, ultra-high throughput, preservar IP origen, latencia mínima.
- **Avoid:** si ALB sirve.

### CloudFront
- **Choose:** CDN global, static assets, API caching, WAF frontend, DDoS mitigation.
- **Gotcha:** invalidations cuestan después de 1000/mes.

### Route 53
- **Choose:** DNS autoritativo, health checks, failover DNS, latency-based routing.

### API Gateway
- **REST API:** features completos, más caro ($3.50/1M).
- **HTTP API:** 70% más barato ($1.00/1M), menos features, suficiente para la mayoría.
- **WebSocket API:** conexiones persistentes.
- **Private API:** solo VPC.

### NAT Gateway
- **Gotcha:** $0.045/hora + $0.045/GB procesado. Trampa de costo común. Considera:
  - VPC Endpoints (S3, DynamoDB son gratis; los demás cuestan pero procesan gratis).
  - NAT Instance (self-managed, barato pero operable).
  - Fargate con IP pública (para tareas sin VPC privada necesaria).

### PrivateLink / VPC Endpoints
- **Choose:** acceso a servicios AWS sin salir por internet. Reduce costo de NAT GW y mejora seguridad.

### Transit Gateway
- **Choose:** conectar múltiples VPCs y on-prem. Reemplazo moderno de VPC peering en topologías complejas.

### Direct Connect
- **Choose:** on-prem ↔ AWS con latencia predecible, compliance, alto throughput.

---

## 5. Messaging / Events

### SQS
- **Choose:** colas simples, decoupling producer/consumer, retry y DLQ built-in.
- **Variants:** Standard (at-least-once, unordered) vs FIFO (exactly-once, ordered, menor throughput).

### SNS
- **Choose:** pub/sub fan-out, notificaciones (email/SMS/push), SQS subscription pattern.

### EventBridge
- **Choose:** routing de eventos con reglas, integración con SaaS (Stripe, Segment), schema registry.
- **Prefer over SNS when:** necesitas filtering rico o múltiples destinos heterogéneos.

### Kinesis Data Streams
- **Choose:** streaming real-time, múltiples consumers del mismo stream, replay, retention hasta 365 días.
- **Avoid:** si SQS basta.

### Kinesis Data Firehose
- **Choose:** ingesta → S3/Redshift/OpenSearch con batching y compresión automáticos.

### MSK (Managed Kafka)
- **Choose:** equipo ya usa Kafka, necesita características específicas de Kafka, ecosistema existente.
- **Avoid:** greenfield sin razón — Kinesis/EventBridge suelen bastar.

---

## 6. Security / Identity

### IAM
- **Patterns:** roles > users, least-privilege, MFA obligatorio para humanos, IAM Identity Center para multi-cuenta.

### KMS
- **Choose:** encryption keys managed, rotación automática, audit via CloudTrail.
- **Cost:** $1/mes por CMK + $0.03/10K requests. Considera AWS-managed keys (gratis) si no necesitas CMK.

### Secrets Manager
- **Choose:** credenciales de DB/APIs con rotación automática.
- **Cost:** $0.40/mes por secret.
- **Alternative:** Parameter Store (SecureString) — gratis para la mayoría, sin rotación automática.

### WAF
- **Choose:** frente a ALB, API GW o CloudFront. Protección OWASP top 10, rate limiting, geo-blocking.

### Shield
- **Standard:** gratis, protección DDoS L3/L4 automática.
- **Advanced:** $3K/mes, SLA, respuesta, cobertura de costos por ataques.

### GuardDuty
- **Choose:** threat detection, siempre encender en producción.

### Security Hub
- **Choose:** single-pane-of-glass para findings de GuardDuty, Inspector, Config, etc.

### Inspector
- **Choose:** vulnerability scanning de EC2, Lambda, ECR images.

### Cognito
- **Choose:** auth para apps B2C o B2B, OAuth/OIDC/SAML, social logins, MFA.
- **Avoid:** si ya tienen Auth0/Okta maduro.

---

## 7. Observability

### CloudWatch Logs
- **Cost trap:** $0.50/GB ingestion + $0.03/GB stored. A escala (>100GB/día) considera filtrar antes de ingest o mover a S3.

### CloudWatch Metrics / Alarms / Dashboards
- **Default.** Custom metrics $0.30/métrica/mes.

### X-Ray
- **Choose:** distributed tracing, debugging de latencia en microservicios.
- **Alternative:** OpenTelemetry + ADOT.

### CloudTrail
- **Siempre encender** management events (gratis). Data events cuestan.

### Managed Grafana / Prometheus
- **Choose:** si el equipo ya vive en Grafana o necesita multi-source dashboards.

---

## 8. CI/CD

### ECR
- **Choose:** registry de imágenes Docker, necesario para ECS/EKS/Lambda container images.

### CodePipeline + CodeBuild + CodeDeploy
- **Choose:** integración nativa con AWS, approval gates, deploy blue/green a ECS/Lambda.
- **Alternative común:** GitHub Actions con OIDC → AWS (sin access keys).

---

## 9. Data / Analytics

### Glue
- **Choose:** ETL serverless, data catalog, crawlers, jobs Spark/Python.

### Lake Formation
- **Choose:** governance y fine-grained access control sobre data lake en S3.

### QuickSight
- **Choose:** BI con permisos por usuario, embedded analytics, bajo costo por usuario lector.

### EMR
- **Choose:** Spark/Hadoop/Presto managed a gran escala.
- **Avoid:** si Glue o Athena bastan.

---

## 10. Patrones de selección rápida

| Requisito | Default senior |
|---|---|
| API REST simple, tráfico variable | API Gateway HTTP + Lambda |
| API con tráfico sostenido > 300 req/s | ALB + Fargate |
| DB transaccional relacional | RDS Postgres Multi-AZ |
| DB a escala masiva key-value | DynamoDB on-demand |
| Archivos de usuario | S3 + CloudFront |
| Colas | SQS + DLQ |
| Eventos complejos | EventBridge |
| Cache | ElastiCache Redis |
| Auth de usuarios | Cognito (o Auth0 si ya existe) |
| Logs | CloudWatch → S3 (lifecycle) |
| Secrets | Parameter Store (simple) / Secrets Manager (con rotación) |
| CDN | CloudFront |
| CI/CD | GitHub Actions con OIDC |
| Observabilidad básica | CloudWatch + X-Ray |
| WAF | AWS WAF sobre ALB o CloudFront |
