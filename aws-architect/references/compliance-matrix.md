# Compliance Matrix

Mapeo: requisito regulatorio → controles AWS requeridos. Incluir en §9 del entregable **solo si aplica compliance**.

⚠️ Este archivo es una guía, no asesoría legal. Siempre validar con el equipo de compliance del cliente.

---

## GDPR (Reglamento General de Protección de Datos — UE)

**Aplica cuando:** hay usuarios en la UE o datos de residentes europeos.

| Requisito | Control AWS |
|---|---|
| Residencia de datos en UE | Usar regiones `eu-west-1`, `eu-central-1`, etc. |
| Encryption at-rest | KMS + S3 SSE-KMS + RDS encryption |
| Encryption in-transit | ACM + ALB HTTPS + TLS en conexiones DB |
| Derecho al olvido (Art. 17) | DynamoDB TTL / S3 lifecycle / job de purge documentado |
| Portabilidad (Art. 20) | Export API / S3 export capability |
| Audit trail | CloudTrail + 7 años retention en S3 Glacier |
| DPA con AWS | Firmado (AWS ya lo ofrece) |
| Breach notification < 72h | GuardDuty + SNS → on-call |
| Data Processing records | Tag consistente `DataClassification`, Config rules |

**Servicios AWS a considerar:** AWS Artifact (descargar DPA), AWS Audit Manager, Macie (detección de PII en S3).

---

## HIPAA (EE.UU. — datos de salud)

**Aplica cuando:** se manejan PHI (Protected Health Information).

**Pre-requisito:** Firmar **BAA (Business Associate Agreement)** con AWS (via AWS Artifact).

| Requisito | Control AWS |
|---|---|
| Usar solo servicios HIPAA-eligible | Lista oficial AWS — validar cada servicio antes de usarlo |
| Encryption at-rest de PHI | KMS CMK obligatorio (no AWS-managed) |
| Encryption in-transit | TLS 1.2+ en todo endpoint |
| Audit logging | CloudTrail + detailed logs por servicio de datos |
| Access control | IAM least-privilege, MFA obligatorio, session logging |
| Backup y disaster recovery | RDS automated backups + cross-region copy |
| Physical security | AWS lo cubre (responsabilidad compartida) |
| Breach detection | GuardDuty + Macie para PII |

**Servicios HIPAA-eligible típicos:** RDS, DynamoDB, S3, Lambda, ECS, API Gateway, CloudFront, KMS, Secrets Manager, CloudTrail, SNS, SQS, EventBridge, Cognito, WAF.

**NO HIPAA-eligible (a marzo 2026 — validar):** algunos servicios nuevos. **Siempre validar en lista oficial antes de incluir.**

---

## PCI-DSS (datos de tarjetas de crédito)

**Aplica cuando:** se almacenan, procesan o transmiten datos de tarjetas.

**Recomendación:** reducir scope usando **Stripe / Adyen** y evitar tocar PAN directamente.

| Requisito | Control AWS |
|---|---|
| Req 1: Firewall | Security Groups + NACLs + WAF |
| Req 2: No defaults | Hardening de AMIs, sin passwords default |
| Req 3: Encryption at-rest de PAN | KMS CMK obligatorio + rotación anual |
| Req 4: Encryption in-transit | TLS 1.2+, certificados ACM |
| Req 5: Anti-malware | Inspector, GuardDuty |
| Req 6: Secure development | CodeGuru, pipelines con tests de seguridad |
| Req 7: Access control | IAM least-privilege + separation of duties |
| Req 8: Authentication | MFA obligatorio, contraseñas fuertes (Cognito) |
| Req 9: Physical access | AWS lo cubre |
| Req 10: Logging y monitoring | CloudTrail + CloudWatch + SIEM (OpenSearch o externo) |
| Req 11: Testing | Inspector + penetration testing aprobado |
| Req 12: Security policy | Documentación externa |

**Separación de red crítica:** CDE (Cardholder Data Environment) en VPC separada o al menos subnets aisladas, flujo estricto.

---

## SOC 2 (Type I / II — controles de seguridad para SaaS)

**Aplica cuando:** cliente enterprise lo pide, o se busca vender a enterprise.

**Pilares (Trust Services Criteria):**
1. Security
2. Availability
3. Processing Integrity
4. Confidentiality
5. Privacy

| Requisito | Control AWS |
|---|---|
| Security baseline | GuardDuty, Security Hub, Inspector |
| Change management | CloudTrail + IaC obligatorio + approval gates |
| Access review trimestral | IAM Access Analyzer + reportes |
| Incident response | Runbooks + GuardDuty → SNS → on-call |
| Backup y recovery | RDS backups + cross-region + test de restore |
| Vendor management | AWS Artifact reports (SOC1/2/3 de AWS) |
| Logging | CloudTrail + CloudWatch + retention ≥ 1 año |
| Monitoring | CloudWatch alarms + dashboards |
| Encryption | Ya cubierto arriba |

**Servicios AWS diseñados para SOC 2 reporting:**
- AWS Audit Manager (genera evidencia automáticamente).
- AWS Config (rules para compliance checks continuos).
- AWS Security Hub (scoring vs estándares).

---

## ISO 27001

**Aplica cuando:** cliente con mercados internacionales lo exige.

Se solapa bastante con SOC 2. Controles adicionales:
- Risk assessment formal y documentado.
- Asset inventory (usar AWS Config + tags obligatorios).
- Business continuity plan probado.
- Supplier security assessment (incluye AWS — disponible en Artifact).

---

## Data Residency (México, Brasil, etc.)

**Aplica cuando:** regulación local exige que los datos no salgan del país.

| País | Región AWS local | Consideraciones |
|---|---|---|
| México | No hay región AWS en México (a 2026) | Usar `us-west-2` o `us-east-2` con acuerdo explícito con cliente |
| Brasil | `sa-east-1` (São Paulo) | Tiene algunos servicios con latencia o sin disponibilidad |
| UE | `eu-west-1`, `eu-central-1`, etc. | GDPR implícito |
| Canadá | `ca-central-1` | PIPEDA |

**Trampa común:** servicios globales (CloudFront, Route 53, IAM) almacenan metadata en us-east-1. Validar si el requisito aplica solo a data de clientes o también a metadata.

---

## Cómo presentar compliance en el entregable

```markdown
## 9. Compliance

**Aplica:** <lista de regulaciones>.

### <Regulación 1>
| Requisito | Cómo lo cubre este diseño | Pendientes |
|---|---|---|
| ... | ... | ... |

### Pendientes transversales
- [ ] Firmar BAA/DPA con AWS (via AWS Artifact).
- [ ] Validar que todos los servicios usados son <regulación>-eligible.
- [ ] Ejecutar AWS Audit Manager assessment después de Fase 8.
- [ ] Documentar Data Processing Record.
- [ ] Programar penetration testing (si PCI).
```

---

## Servicios AWS dedicados a compliance

- **AWS Artifact:** descargar BAA, DPA, SOC reports, ISO certificates.
- **AWS Audit Manager:** evidencia automática para auditorías.
- **AWS Config:** rules de compliance continuo (ej. "todos los buckets cifrados").
- **AWS Security Hub:** scoring vs CIS, PCI-DSS, AWS Foundational Best Practices.
- **Amazon Macie:** detección automática de PII en S3.
- **AWS Control Tower:** landing zone multi-cuenta con guardrails.
- **AWS Organizations + SCPs:** enforcement a nivel org (ej. "prohibir crear recursos fuera de `eu-*`").
