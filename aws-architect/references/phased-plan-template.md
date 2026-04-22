# Phased Implementation Plan Template

Plan ejecutable con comandos `aws` CLI. El usuario los corre manualmente, fase por fase, validando cada una antes de pasar a la siguiente.

**Regla:** cada comando destructivo/creativo que el usuario va a ejecutar se muestra con (a) placeholder para variables, (b) flags críticos comentados, (c) comando de validación `describe-*` correspondiente.

---

## Estructura canónica de fases

### Fase 1 — Networking base
Crear VPC, subnets, IGW, NAT Gateway, route tables.

### Fase 2 — IAM y seguridad
Roles, KMS keys, Secrets Manager entries, security groups base.

### Fase 3 — Capa de datos
RDS / Aurora / DynamoDB / ElastiCache / S3 buckets con políticas.

### Fase 4 — Compute
Lambda functions / ECS cluster + task definitions + services / EC2.

### Fase 5 — Edge y DNS
ACM certs, ALB, CloudFront, Route 53.

### Fase 6 — Observabilidad
CloudWatch Log Groups con retención, alarms, dashboards, X-Ray.

### Fase 7 — CI/CD y automatización
ECR repos, pipelines, deploy roles con OIDC para GitHub Actions.

### Fase 8 — Hardening final
WAF rules, GuardDuty, Security Hub, Config rules, budget alerts.

---

## Plantilla por fase

```markdown
### Fase N — <Nombre>

**Objetivo:** <1 línea>.

**Prerequisitos:** Fase N-1 completa.

**Variables a exportar al inicio:**
\`\`\`bash
export REGION="us-west-2"
export PROJECT="mi-proyecto"
export ENV="prod"
\`\`\`

**Pasos:**

#### N.1 — <Acción>
\`\`\`bash
aws <service> <verb> \\
  --param1 value \\
  --param2 value \\
  --region $REGION \\
  --tag-specifications "ResourceType=<type>,Tags=[{Key=Project,Value=$PROJECT},{Key=Env,Value=$ENV}]"
\`\`\`

**Validación:**
\`\`\`bash
aws <service> describe-<resource> --region $REGION
\`\`\`
Espera: `<condición>`.

**Notas senior:**
- Por qué así y no de otra forma.
- Trampa común a evitar.

#### N.2 — <Siguiente acción>
...

**Checkpoint de fase:** [ ] todos los recursos creados, [ ] tags aplicados, [ ] validaciones pasan.

**Costo incremental después de esta fase:** ~$X/mes.
```

---

## Ejemplos concretos por fase

### Fase 1 — Networking (ejemplo completo)

```markdown
### Fase 1 — Networking base

**Objetivo:** Crear VPC con 3 AZs, subnets public/private/db, IGW, NAT Gateway.

**Variables:**
\`\`\`bash
export REGION="us-west-2"
export PROJECT="mi-app"
export ENV="prod"
export VPC_CIDR="10.20.0.0/16"
\`\`\`

#### 1.1 — Crear VPC
\`\`\`bash
aws ec2 create-vpc \\
  --cidr-block $VPC_CIDR \\
  --region $REGION \\
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$PROJECT-$ENV-vpc},{Key=Project,Value=$PROJECT}]"
# Guarda el VpcId de la salida:
export VPC_ID="vpc-xxxxx"
\`\`\`

**Validación:**
\`\`\`bash
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region $REGION
\`\`\`

#### 1.2 — Habilitar DNS hostnames
\`\`\`bash
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames --region $REGION
\`\`\`

#### 1.3 — Crear Internet Gateway y adjuntar
\`\`\`bash
aws ec2 create-internet-gateway --region $REGION \\
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$PROJECT-$ENV-igw}]"
export IGW_ID="igw-xxxxx"

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
\`\`\`

#### 1.4 — Crear subnets (3 AZs × 3 tiers = 9 subnets)
Public (para ALB, NAT): `10.20.0.0/24`, `10.20.1.0/24`, `10.20.2.0/24`.
Private (para compute): `10.20.10.0/24`, `10.20.11.0/24`, `10.20.12.0/24`.
DB (para RDS): `10.20.20.0/24`, `10.20.21.0/24`, `10.20.22.0/24`.

\`\`\`bash
for i in 0 1 2; do
  aws ec2 create-subnet \\
    --vpc-id $VPC_ID \\
    --cidr-block "10.20.$i.0/24" \\
    --availability-zone "${REGION}$([[ $i = 0 ]] && echo a || ([[ $i = 1 ]] && echo b || echo c))" \\
    --region $REGION \\
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$PROJECT-$ENV-public-$i},{Key=Tier,Value=public}]"
done
# Repetir para private (10.20.1X.0/24) y db (10.20.2X.0/24)
\`\`\`

#### 1.5 — NAT Gateway (en subnet pública de AZ-a)
\`\`\`bash
# EIP para el NAT
aws ec2 allocate-address --domain vpc --region $REGION
export EIP_ALLOC_ID="eipalloc-xxxxx"

aws ec2 create-nat-gateway \\
  --subnet-id <public-subnet-a-id> \\
  --allocation-id $EIP_ALLOC_ID \\
  --region $REGION \\
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$PROJECT-$ENV-nat}]"
\`\`\`

**Nota senior:** Un solo NAT Gateway es SPOF por AZ. Para producción crítica, crea uno por AZ ($32 × 3 = ~$96/mes base adicional). Para MVP / staging, uno basta.

#### 1.6 — Route tables
Public RT: `0.0.0.0/0 → IGW`.
Private RT: `0.0.0.0/0 → NAT GW`.
DB RT: sin rutas a internet (solo local).

\`\`\`bash
aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION ...
aws ec2 create-route --route-table-id <rt-id> --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --route-table-id <rt-id> --subnet-id <subnet-id> --region $REGION
\`\`\`

#### 1.7 — VPC Endpoints (ahorro en NAT)
Para S3 y DynamoDB (Gateway endpoints, gratis):
\`\`\`bash
aws ec2 create-vpc-endpoint \\
  --vpc-id $VPC_ID \\
  --service-name "com.amazonaws.$REGION.s3" \\
  --route-table-ids <private-rt-ids> \\
  --region $REGION
\`\`\`

**Validación final de fase:**
\`\`\`bash
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region $REGION
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --region $REGION
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION
\`\`\`

**Checkpoint:** [ ] 9 subnets en 3 AZs, [ ] IGW adjunto, [ ] NAT activo, [ ] 3 RTs con rutas correctas, [ ] VPC endpoints de S3/DDB creados.

**Costo incremental:** ~$32/mes (NAT GW base) + procesamiento por GB.
```

---

### Fase 2 — IAM y secrets (ejemplo)

```markdown
### Fase 2 — IAM y seguridad base

#### 2.1 — KMS CMK para encryption
\`\`\`bash
aws kms create-key \\
  --description "$PROJECT-$ENV CMK" \\
  --key-usage ENCRYPT_DECRYPT \\
  --region $REGION \\
  --tags "TagKey=Project,TagValue=$PROJECT"
export KMS_KEY_ID="<key-id>"

aws kms create-alias --alias-name "alias/$PROJECT-$ENV" --target-key-id $KMS_KEY_ID --region $REGION

aws kms enable-key-rotation --key-id $KMS_KEY_ID --region $REGION
\`\`\`

**Nota senior:** rotación anual gratis y obligatoria en la mayoría de compliance (PCI, HIPAA).

#### 2.2 — Role de ejecución para Lambda/Fargate
\`\`\`bash
aws iam create-role \\
  --role-name "$PROJECT-$ENV-exec-role" \\
  --assume-role-policy-document file://trust-policy.json \\
  --tags Key=Project,Value=$PROJECT
\`\`\`

(Incluir `trust-policy.json` ejemplo en el documento.)

**Principios:**
- Un role por servicio, no reusar.
- Least-privilege en policies (no `*` en Resource).
- Usar `aws:SourceArn` en trust policies cuando aplique.

#### 2.3 — Secrets en Secrets Manager
\`\`\`bash
aws secretsmanager create-secret \\
  --name "$PROJECT/$ENV/db/master" \\
  --kms-key-id $KMS_KEY_ID \\
  --secret-string '{"username":"admin","password":"CHANGE_ME"}' \\
  --region $REGION
\`\`\`
```

---

### Fase 3-8 — Estructura similar

Cada fase replica el patrón:
1. Variables a exportar.
2. Comandos `aws` con flags críticos comentados.
3. Comando de validación (`describe-*` / `list-*` / `get-*`).
4. Notas senior (por qué así, trampas, costo).
5. Checkpoint.
6. Costo incremental.

---

## Reglas al escribir el plan

1. **Placeholder `<angle-brackets>` para IDs dinámicos** que el usuario copiará de la salida anterior.
2. **`export VAR=value` al principio** de cada fase — facilita re-ejecutar fragmentos.
3. **Tags obligatorios:** `Project`, `Env`, `Owner`. Algunos clientes agregan `CostCenter`.
4. **`--region $REGION` en todos los comandos** — los usuarios saltan de región y se rompe.
5. **Ninguna fase asume estado implícito** — cada una dice qué necesita.
6. **Al final del plan, un script `destroy.sh`** comentado (opcional) para tear-down completo — con warnings claros.
7. **Cada comando mutante** debe tener su validación read-only inmediatamente después.
8. **Menciona cuotas/limits** cuando el comando puede fallar por ellas (ej. "VPC limit de 5 por región, aumentar con Service Quotas").

---

## Al final del plan

Incluir siempre:

```markdown
## Post-implementación

### Monitoreo continuo
- [ ] Budgets alerts configurados (ver Fase 8).
- [ ] GuardDuty activo.
- [ ] CloudTrail a S3 con 90 días retention mínimo.
- [ ] Access Analyzer corriendo.

### Runbooks a crear
- [ ] Failover de región/AZ.
- [ ] Rotación de secrets.
- [ ] Restore desde backup.
- [ ] Escalado manual de emergencia.

### Siguiente iteración (considerar)
- [ ] Migrar a IaC (Terraform/CDK) cuando el stack se estabilice.
- [ ] Savings Plans después de 30 días de baseline.
- [ ] Multi-región DR si el SLA lo requiere.
```
