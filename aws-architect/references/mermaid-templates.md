# Mermaid Templates

Diagramas base por patrón. Cópialos y ajústalos con los servicios reales del diseño. Convenciones:

- Subgraph por zona lógica (Internet, Edge, VPC, AZs, subnets).
- Servicios con prefijo de ícono textual (AWS no tiene íconos nativos en Mermaid — usamos labels claros).
- Flechas con protocolo cuando aplique: `-->|HTTPS|`, `-->|SQL|`, `-->|TLS|`.

**Validar siempre:** Mermaid v10+ es estricto con syntax. Probar con ```mermaid block en VSCode o mermaid.live.

---

## Template 1 — Serverless API

```mermaid
graph TD
  User[Usuario] -->|HTTPS| CF[CloudFront + WAF]
  CF -->|API| APIGW[API Gateway HTTP API]
  CF -->|Static| S3Web[S3: frontend]

  APIGW -->|Cognito authorizer| Cognito[Cognito User Pool]
  APIGW --> Lambda[Lambda: Python 3.12]

  Lambda -->|GetItem/PutItem| DDB[(DynamoDB)]
  Lambda -->|S3 SDK| S3Data[(S3: user files)]
  Lambda -->|Publish| EB[EventBridge]

  EB --> LambdaNotif[Lambda: Notifier]
  LambdaNotif -->|Publish| SNS[SNS Topic]

  subgraph Observability
    Lambda -.->|Logs| CW[CloudWatch Logs]
    Lambda -.->|Traces| XRay[X-Ray]
  end
```

---

## Template 2 — 3-Tier Containers

```mermaid
graph TD
  User[Usuario] -->|HTTPS 443| CF[CloudFront + WAF]
  CF -->|HTTPS| ALB[Application Load Balancer]

  subgraph VPC
    subgraph PublicSubnets
      ALB
      NAT[NAT Gateway]
    end

    subgraph PrivateSubnets
      ALB --> ECS1[Fargate Service: API<br/>2 tasks min, 10 max]
      ECS1 --> Cache[(ElastiCache Redis<br/>Multi-AZ)]
      ECS1 --> NAT
    end

    subgraph DBSubnets
      ECS1 -->|Postgres| Aurora[(Aurora Postgres<br/>Multi-AZ: 1 writer + 1 reader)]
    end
  end

  NAT --> Internet[Internet]
  ECS1 -.->|Logs| CW[CloudWatch Logs]
  ECS1 -.->|Metrics| CWM[CloudWatch Metrics]
  Aurora -.->|Backups| S3B[(S3: snapshots)]
```

---

## Template 3 — Event-Driven

```mermaid
graph LR
  Producer1[API Gateway + Lambda] --> EB[EventBridge Bus]
  Producer2[S3 Event] --> EB
  Producer3[External Webhook] --> EB

  EB -->|rule: order.created| Q1[SQS: Orders]
  EB -->|rule: user.signup| Q2[SQS: Emails]
  EB -->|rule: audit.*| Firehose[Kinesis Firehose]

  Q1 --> Lambda1[Lambda: Order Processor]
  Q2 --> Lambda2[Lambda: Email Sender]
  Firehose --> S3Audit[(S3: audit lake)]

  Q1 -.->|failures| DLQ1[SQS DLQ: Orders]
  Q2 -.->|failures| DLQ2[SQS DLQ: Emails]

  Lambda1 --> DDB[(DynamoDB Orders)]
  Lambda2 -->|SES| Email[Email]
```

---

## Template 4 — Data Lake

```mermaid
graph TD
  Sources[Fuentes: RDS, APIs, Files] -->|DMS / Glue| Raw[(S3: raw zone)]
  Raw -->|Glue ETL| Curated[(S3: curated zone<br/>Parquet + partitioned)]
  Curated -->|Glue Catalog| Catalog[Glue Data Catalog]

  Catalog --> Athena[Athena]
  Catalog --> Redshift[Redshift Serverless<br/>optional]

  Athena --> QS[QuickSight]
  Redshift --> QS

  LF[Lake Formation] -.->|governance| Catalog
  LF -.->|permissions| Athena
```

---

## Template 5 — Real-Time Streaming

```mermaid
graph LR
  IoT[IoT Devices / Apps] -->|PutRecord| KDS[Kinesis Data Streams<br/>10 shards]
  KDS --> Lambda1[Lambda: Enrichment]
  KDS --> Flink[Kinesis Analytics<br/>Flink app]

  Lambda1 --> DDB[(DynamoDB: hot state)]
  Flink --> OS[(OpenSearch: real-time dashboards)]

  KDS --> KFH[Kinesis Firehose]
  KFH -->|batched + compressed| S3[(S3: historical)]

  S3 --> Glue[Glue ETL]
  Glue --> Athena[Athena]
```

---

## Template 6 — Static Site + API

```mermaid
graph TD
  User[Usuario] -->|HTTPS| CF[CloudFront]
  CF -->|/| S3[(S3: SPA build)]
  CF -->|/api| APIGW[API Gateway HTTP]

  APIGW -->|JWT validate| Cognito[Cognito]
  APIGW --> Lambda[Lambda: Python]
  Lambda --> DDB[(DynamoDB)]

  ACM[ACM Cert] -.-> CF
  R53[Route 53] -.-> CF
  WAF[AWS WAF] -.-> CF
```

---

## Template 7 — Microservicios Fargate

```mermaid
graph TD
  User[Usuario] --> ALBE[ALB externo]
  ALBE --> SvcGW[Fargate: API Gateway Service]

  subgraph VPC
    subgraph ServiceMesh
      SvcGW --> SvcUsers[Fargate: Users Service]
      SvcGW --> SvcOrders[Fargate: Orders Service]
      SvcGW --> SvcBilling[Fargate: Billing Service]

      SvcOrders --> SvcUsers
      SvcBilling --> SvcOrders
    end

    SvcUsers --> DBUsers[(RDS Users)]
    SvcOrders --> DBOrders[(RDS Orders)]
    SvcBilling --> DBBilling[(RDS Billing)]
  end

  CM[Cloud Map<br/>service discovery] -.-> SvcGW
  ECR[(ECR repos)] -.-> SvcUsers
  ECR -.-> SvcOrders
  ECR -.-> SvcBilling
```

---

## Template 8 — Batch Processing

```mermaid
graph LR
  S3In[(S3: input)] -->|S3 event| EB[EventBridge]
  EB --> SF[Step Functions<br/>workflow]

  SF --> Batch1[AWS Batch job 1<br/>Fargate]
  SF --> Batch2[AWS Batch job 2<br/>Fargate]
  SF --> Lambda[Lambda: aggregator]

  Batch1 --> S3Tmp[(S3: tmp)]
  Batch2 --> S3Tmp
  Lambda --> S3Out[(S3: output)]

  SF -->|on failure| SNS[SNS: alerts]
  SF -.->|logs| CW[CloudWatch]
```

---

## Convenciones comunes

- **Cajas con `[ ]`:** servicios de compute o gateway.
- **Cajas con `[( )]`:** stores (DB, S3, cache).
- **Flechas sólidas `-->`:** flujo de datos primario.
- **Flechas punteadas `-.->`:** observabilidad, logs, metadata.
- **Subgraphs:** agrupar por VPC, AZ, zona lógica.
- **Labels en flechas `-->|texto|`:** protocolo o acción.

## Checklist antes de pegar en el doc

- [ ] `graph TD` o `graph LR` correcto según lectura.
- [ ] Sin caracteres especiales no escapados en labels (`<br/>` es válido; `()` en labels hay que escapar o usar comillas).
- [ ] Cada nodo se define una sola vez (Mermaid falla si redefines con diferente label).
- [ ] Subgraphs cierran con `end`.
- [ ] Probar en mermaid.live si hay duda.
