# Cost Estimation Guide

Metodología para los **3 escenarios obligatorios** de costo: MVP / producción baja / producción alta.

**Regla de oro:** nunca inventar precios. Para números finales, **WebFetch** la página oficial de pricing del servicio. Precios aquí son "orden de magnitud" para razonar, no para el entregable final.

---

## Definición de los 3 escenarios

### MVP (evaluación / early access)
- Usuarios: < 100 activos.
- Tráfico: esporádico, 1-10 req/min promedio.
- Datos: < 10 GB.
- Objetivo: validar producto con mínimo costo posible.
- Servicios preferidos: serverless, tiers gratuitos, single-AZ aceptable en dev.

### Producción baja (real pero contenido)
- Usuarios: ~1,000-5,000 activos.
- Tráfico: decenas de req/s sostenidos.
- Datos: 100 GB – 1 TB.
- Multi-AZ obligatorio.
- Backups automáticos.
- Monitoreo completo.

### Producción alta (escalado)
- Usuarios: ~50,000+ activos.
- Tráfico: cientos a miles de req/s sostenidos, picos de 10x.
- Datos: 1 TB – 100 TB.
- Multi-AZ o multi-región según SLA.
- Auto-scaling agresivo.
- CDN + WAF obligatorios.

---

## Factores siempre a incluir (trampas comunes)

1. **NAT Gateway** — $0.045/hora ≈ $32/mes + $0.045/GB procesado. Si Lambda/Fargate en subnet privada hablan con internet, esto aparece.
2. **Cross-AZ transfer** — $0.01/GB entre AZs dentro de la misma región. En microservicios chatty suma.
3. **Data transfer out (egress)** — $0.09/GB a internet (primeros 10 TB/mes us-east-1). Gratis con CloudFront en ciertas cantidades.
4. **CloudWatch Logs ingestion** — $0.50/GB ingestado + $0.03/GB almacenado. A 50 GB/día son ~$750/mes solo en logs.
5. **S3 requests** — $0.005/1K PUTs, $0.0004/1K GETs. A millones/día suma.
6. **Secrets Manager** — $0.40/mes por secret. 50 secrets = $20/mes.
7. **KMS** — $1/mes por CMK + $0.03/10K requests.
8. **Route 53** — $0.50/hosted zone + $0.40/1M queries.
9. **Certificate (ACM)** — gratis para uso con AWS services.
10. **Multi-AZ RDS** — duplica el costo del instance.
11. **CloudWatch metrics custom** — $0.30/métrica/mes. Tratar con cuidado.

---

## Tablas de precios de referencia (us-east-1, on-demand, marzo 2026)

⚠️ **Siempre validar con WebFetch antes de publicar.**

### Compute

| Servicio | Unidad | Precio referencial |
|---|---|---|
| Lambda | 1M requests | $0.20 |
| Lambda | 1 GB-s | $0.0000166667 |
| Fargate | vCPU-hora | $0.04048 |
| Fargate | GB-hora | $0.004445 |
| EC2 t3.medium | hora | $0.0416 |
| EC2 m5.large | hora | $0.096 |

### Databases

| Servicio | Unidad | Precio referencial |
|---|---|---|
| RDS Postgres db.t3.medium Single-AZ | mes | ~$60 |
| RDS Postgres db.t3.medium Multi-AZ | mes | ~$120 |
| Aurora Postgres r6g.large Multi-AZ | mes | ~$350 |
| Aurora Serverless v2 | ACU-hora | $0.12 |
| DynamoDB on-demand | 1M writes | $1.25 |
| DynamoDB on-demand | 1M reads | $0.25 |
| DynamoDB storage | GB-mes | $0.25 |
| ElastiCache Redis cache.t3.medium | mes | ~$35 |

### Networking

| Servicio | Unidad | Precio referencial |
|---|---|---|
| ALB | hora | $0.0225 |
| ALB | LCU-hora | $0.008 |
| NLB | hora | $0.0225 |
| NAT Gateway | hora | $0.045 |
| NAT Gateway | GB procesado | $0.045 |
| CloudFront | GB servido (primeros 10 TB) | $0.085 |
| API Gateway REST | 1M requests | $3.50 |
| API Gateway HTTP | 1M requests | $1.00 |
| Data transfer out internet | GB (primeros 10 TB) | $0.09 |

### Storage

| Servicio | Unidad | Precio referencial |
|---|---|---|
| S3 Standard | GB-mes | $0.023 |
| S3 Standard-IA | GB-mes | $0.0125 |
| S3 Glacier Instant | GB-mes | $0.004 |
| S3 Glacier Deep Archive | GB-mes | $0.00099 |
| EBS gp3 | GB-mes | $0.08 |
| EFS Standard | GB-mes | $0.30 |

### Messaging

| Servicio | Unidad | Precio referencial |
|---|---|---|
| SQS Standard | 1M requests | $0.40 |
| SNS | 1M publishes | $0.50 |
| EventBridge custom events | 1M events | $1.00 |
| Kinesis Data Streams | shard-hora | $0.015 |
| Kinesis Data Streams | PUT payload (1M, 25KB) | $0.014 |

### Security / Other

| Servicio | Unidad | Precio referencial |
|---|---|---|
| KMS CMK | mes | $1 |
| Secrets Manager | secret-mes | $0.40 |
| CloudWatch Logs ingestion | GB | $0.50 |
| CloudWatch Logs storage | GB-mes | $0.03 |
| CloudTrail management events | — | gratis |
| GuardDuty | por evento analizado | varía |
| WAF | web ACL-mes | $5 |
| WAF | rule-mes | $1 |
| WAF | 1M requests | $0.60 |

---

## Proceso de estimación

1. **Para cada escenario** construye una tabla:

| Servicio | Config | Supuestos de uso | Cálculo | Costo mensual |
|---|---|---|---|---|
| Lambda | 128MB, 500ms | 10M req/mes | `10M × $0.20/M + 10M × 0.5 × 0.128 × $0.0000166667` | $12.67 |

2. **Suma total mensual y anual** por escenario.

3. **Nota final obligatoria:**
   > Precios on-demand en `<región>`. No incluye Savings Plans ni Reserved Instances (aplicar reduce 20-50% en compute).
   > No incluye soporte AWS (Business: 10% del gasto, mínimo $100/mes; Enterprise: 10% mínimo $15K/mes).
   > No incluye costo de transferencia entre regiones si no aplica.

4. **Detalla supuestos clave arriba de la tabla.** Ejemplos:
   - 10M requests/mes.
   - Request promedio: 500ms, 128MB memoria.
   - DB: 100 GB, 1000 IOPS pico.
   - Tráfico saliente: 500 GB/mes.
   - Logs generados: 5 GB/día.
   - Retención logs: 30 días hot, después S3.

---

## Cómo usar WebFetch para validar

Antes de pegar cualquier número en el entregable final:

```
WebFetch: https://aws.amazon.com/<service>/pricing/
WebSearch: "site:aws.amazon.com/<service>/pricing/ <región>"
```

Para calculadora oficial: `https://calculator.aws`.

Si el WebFetch falla o el precio no está claro, **marcar explícitamente en el entregable**:
> "Precio aproximado basado en conocimiento al momento del diseño. Confirmar en https://aws.amazon.com/<service>/pricing/ antes de presupuestar."

---

## Savings opportunities a mencionar

Siempre incluir al final de la sección de costos:

- **Savings Plans / Reserved Instances:** Compute Savings Plans (1 año, no upfront) reducen ~27% en Fargate/Lambda/EC2.
- **Spot Instances:** para workloads fault-tolerant, -70% en EC2.
- **S3 Intelligent-Tiering:** si no conoces el patrón de acceso.
- **VPC Endpoints:** reducen tráfico por NAT GW para servicios AWS.
- **CloudFront:** gratis egress desde S3/ALB hacia CloudFront, luego cobra por distribución (pero más barato que egress directo).
- **Graviton (ARM):** -20% en RDS, Fargate, EC2 con misma performance.
- **Data retention policies:** lifecycle a Glacier, TTL en DynamoDB, CloudWatch Logs expiration.
