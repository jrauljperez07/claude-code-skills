# Well-Architected Checks

Aplicar los **6 pilares** a cada diseño. Esta sección es obligatoria como §8 del entregable.

Para cada pilar, responder:
1. ¿Qué hace el diseño por este pilar? (específico)
2. ¿Qué trade-off se aceptó? (honesto)
3. ¿Qué quedó fuera de scope v1 y por qué?

---

## 1. Operational Excellence

**Preguntas clave:**
- ¿Cómo se despliega? ¿Hay pipeline? ¿Hay rollback?
- ¿Runbooks existen para incidentes típicos? (failover, restore, rotación)
- ¿Infrastructure-as-Code? Si no, ¿por qué y cuándo migramos?
- ¿Cómo se detectan fallos en producción? (alarms → pager)
- ¿Hay game-days planeados?

**Outputs esperados en el diseño:**
- Mención explícita de método de deploy (CodeDeploy blue/green, GitHub Actions OIDC, etc.).
- Alarmas críticas enumeradas (alta latencia p99, error rate > X%, DLQ messages > 0).
- Plan de runbooks a escribir.

---

## 2. Security

**Preguntas clave:**
- ¿Least-privilege en IAM? ¿Un role por servicio?
- ¿Encryption at-rest en todo stateful? (S3, RDS, EBS, DynamoDB)
- ¿Encryption in-transit? (TLS en ALB, TLS en conexiones a DB)
- ¿Secrets en Secrets Manager / Parameter Store? ¿NADA hardcoded?
- ¿VPC Flow Logs encendidos?
- ¿GuardDuty activo?
- ¿CloudTrail con 90+ días retention?
- ¿MFA obligatorio para humanos?
- ¿KMS con rotación automática?
- ¿Network segmentation? (public/private/db subnets con SG estrictos)
- ¿WAF frente a endpoints públicos?
- ¿Data classification? ¿Dónde está la data sensible?

**Outputs esperados:**
- Tabla: recurso sensible → encryption (at-rest + in-transit) + acceso.
- Lista de roles IAM con propósito.
- Política de secrets (dónde viven, cómo rotan).

---

## 3. Reliability

**Preguntas clave:**
- ¿Multi-AZ en todos los stateful? (RDS Multi-AZ, ElastiCache replication group, DynamoDB global tables si aplica)
- ¿Auto-scaling configurado? (target tracking en ECS, concurrent execution limits en Lambda)
- ¿Health checks en ALB / ECS tasks?
- ¿Backups automáticos? ¿Probados?
- ¿RPO / RTO documentado y alineado con los requisitos?
- ¿DLQs en todas las colas?
- ¿Circuit breakers / retries con exponential backoff donde importe?
- ¿Chaos testing planeado?
- ¿Quotas revisadas? (Lambda concurrent, VPC, ENIs)

**Outputs esperados:**
- Matriz: componente → estrategia de alta disponibilidad → RPO/RTO.
- Política de backups (frecuencia, retention, test de restore).

---

## 4. Performance Efficiency

**Preguntas clave:**
- ¿Tipo de instancia correcto? (¿Graviton ARM si la carga lo soporta?)
- ¿Caching strategy? (CloudFront, ElastiCache, DAX para DynamoDB)
- ¿Connection pooling a DB? (RDS Proxy para Lambda → RDS)
- ¿Async donde sea apropiado? (no hacer síncrono lo que puede ser cola)
- ¿Particionado correcto? (DynamoDB partition key, S3 Parquet + particiones, Kinesis shards)
- ¿CDN para assets estáticos?
- ¿Compresión habilitada? (gzip/brotli en ALB y CloudFront)

**Outputs esperados:**
- Justificación de tipo de instancia elegido.
- Estrategia de caché documentada.
- SLO (service level objective) de latencia si aplica.

---

## 5. Cost Optimization

**Preguntas clave:**
- ¿Servicios managed o self-hosted? (managed suele ganar en TCO).
- ¿Savings Plans / RIs después de estabilizar?
- ¿Spot Instances para fault-tolerant workloads?
- ¿Lifecycle policies en S3?
- ¿TTL en DynamoDB?
- ¿CloudWatch Logs retention finita?
- ¿VPC Endpoints para reducir costo de NAT Gateway?
- ¿Budget alerts configurados?
- ¿Auto-stop en entornos de dev?
- ¿Review mensual de Cost Explorer y Trusted Advisor?

**Outputs esperados:**
- Budget alerts propuestos (ej. 80%, 100%, 120% de target).
- Lifecycle policies de S3 definidas.
- Retention de logs definida.
- Nota sobre Savings Plans después de N días de baseline.

---

## 6. Sustainability

**Preguntas clave:**
- ¿Graviton ARM donde aplique? (mejor performance/watt).
- ¿Serverless cuando la carga es variable? (escala a 0).
- ¿Lifecycle a storage tiers más fríos?
- ¿Región con energía renovable alta? (AWS publica el Customer Carbon Footprint Tool).
- ¿Auto-stop de recursos no productivos?

**Outputs esperados:**
- Mención de uso de Graviton si aplica.
- Decisión de región considerando sustainability si es criterio relevante.

---

## Checklist final aplicable a cualquier diseño

Antes de cerrar el documento, revisar:

- [ ] Cada stateful tiene Multi-AZ o justificación.
- [ ] Cada recurso tiene encryption at-rest.
- [ ] Cada endpoint público tiene HTTPS + WAF (o justificación).
- [ ] Cada cola tiene DLQ.
- [ ] Cada servicio tiene al menos 1 alarm crítica.
- [ ] Secrets en Secrets Manager / Parameter Store — no en env vars en texto plano.
- [ ] CloudTrail activo.
- [ ] GuardDuty activo en producción.
- [ ] Budget alerts configurados.
- [ ] Tags consistentes (Project, Env, Owner).
- [ ] Log retention finita.
- [ ] S3 lifecycle policies donde aplique.
- [ ] Runbooks enumerados.

---

## Formato de la sección Well-Architected en el entregable

```markdown
## 8. Cumplimiento Well-Architected

### Operational Excellence
- Deploy: <método>.
- Alarmas críticas: <lista>.
- Runbooks a escribir: <lista>.
- Pendiente v1: <qué queda>.

### Security
- Encryption at-rest: <servicios cubiertos + CMK>.
- Encryption in-transit: <descripción>.
- IAM: <N> roles con least-privilege.
- Secrets: <dónde viven>.
- Network: <segmentación>.
- Monitoring: CloudTrail, GuardDuty.
- Pendiente v1: <qué queda>.

### Reliability
- Multi-AZ: <componentes cubiertos>.
- Auto-scaling: <política por servicio>.
- RPO: <valor> / RTO: <valor>.
- Backups: <política>.
- DLQs: <sí/no y razón>.

### Performance Efficiency
- Tipo de compute: <justificación>.
- Caching: <estrategia>.
- Particionado: <descripción>.

### Cost Optimization
- Budget alerts: <thresholds>.
- Savings Plans: <después de cuándo>.
- Lifecycle S3: <policy>.
- Retention logs: <días>.

### Sustainability
- Graviton: <sí/no>.
- Serverless / escala-a-0: <dónde>.
- Región: <y razón>.
```
