#!/usr/bin/env bash
# AWS account inventory — READ-ONLY
# Takes optional region argument; defaults to configured region.

set -u

REGION="${1:-$(aws configure get region 2>/dev/null || echo us-east-1)}"
export AWS_PAGER=""

section() { echo ""; echo "### $1"; echo "---"; }

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: aws CLI not configured"
  exit 1
fi

echo "# AWS Account Inventory — region: $REGION"
echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ─────────────── Networking ───────────────
section "VPCs"
aws ec2 describe-vpcs --region "$REGION" \
  --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,IsDefault:IsDefault,Tags:Tags}' \
  --output json 2>/dev/null || echo "none-or-no-access"

section "Subnets"
aws ec2 describe-subnets --region "$REGION" \
  --query 'Subnets[].{SubnetId:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,VpcId:VpcId,Public:MapPublicIpOnLaunch,Tags:Tags}' \
  --output json 2>/dev/null || echo "none"

section "Internet Gateways"
aws ec2 describe-internet-gateways --region "$REGION" \
  --query 'InternetGateways[].{IgwId:InternetGatewayId,Attachments:Attachments,Tags:Tags}' \
  --output json 2>/dev/null || echo "none"

section "NAT Gateways"
aws ec2 describe-nat-gateways --region "$REGION" \
  --query 'NatGateways[?State==`available`].{NatId:NatGatewayId,State:State,VpcId:VpcId,SubnetId:SubnetId,Tags:Tags}' \
  --output json 2>/dev/null || echo "none"

section "Route Tables (IDs only)"
aws ec2 describe-route-tables --region "$REGION" \
  --query 'RouteTables[].{RtbId:RouteTableId,VpcId:VpcId,Associations:Associations[].SubnetId}' \
  --output json 2>/dev/null || echo "none"

section "Security Groups (non-default)"
aws ec2 describe-security-groups --region "$REGION" \
  --query 'SecurityGroups[?GroupName!=`default`].{SgId:GroupId,Name:GroupName,VpcId:VpcId}' \
  --output json 2>/dev/null || echo "none"

section "VPC Endpoints"
aws ec2 describe-vpc-endpoints --region "$REGION" \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,VpcId:VpcId}' \
  --output json 2>/dev/null || echo "none"

# ─────────────── Compute ───────────────
section "EC2 Instances"
aws ec2 describe-instances --region "$REGION" \
  --query 'Reservations[].Instances[?State.Name!=`terminated`].{Id:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone,Tags:Tags}' \
  --output json 2>/dev/null || echo "none"

section "Lambda Functions"
aws lambda list-functions --region "$REGION" \
  --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize,Timeout:Timeout,LastModified:LastModified}' \
  --output json 2>/dev/null || echo "none"

section "ECS Clusters"
aws ecs list-clusters --region "$REGION" --output json 2>/dev/null || echo "none"

section "ECS Services (per cluster)"
for CLUSTER in $(aws ecs list-clusters --region "$REGION" --query 'clusterArns[]' --output text 2>/dev/null); do
  echo "  Cluster: $CLUSTER"
  aws ecs list-services --cluster "$CLUSTER" --region "$REGION" --output json 2>/dev/null
done

section "EKS Clusters"
aws eks list-clusters --region "$REGION" --output json 2>/dev/null || echo "none"

# ─────────────── Databases ───────────────
section "RDS Instances"
aws rds describe-db-instances --region "$REGION" \
  --query 'DBInstances[].{Id:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,MultiAZ:MultiAZ,Storage:AllocatedStorage,Status:DBInstanceStatus}' \
  --output json 2>/dev/null || echo "none"

section "RDS Clusters (Aurora)"
aws rds describe-db-clusters --region "$REGION" \
  --query 'DBClusters[].{Id:DBClusterIdentifier,Engine:Engine,MultiAZ:MultiAZ,Members:DBClusterMembers[].DBInstanceIdentifier}' \
  --output json 2>/dev/null || echo "none"

section "DynamoDB Tables"
aws dynamodb list-tables --region "$REGION" --output json 2>/dev/null || echo "none"

section "ElastiCache Clusters"
aws elasticache describe-cache-clusters --region "$REGION" \
  --query 'CacheClusters[].{Id:CacheClusterId,Engine:Engine,NodeType:CacheNodeType,Nodes:NumCacheNodes,Status:CacheClusterStatus}' \
  --output json 2>/dev/null || echo "none"

# ─────────────── Storage ───────────────
section "S3 Buckets (global)"
aws s3api list-buckets --query 'Buckets[].Name' --output json 2>/dev/null || echo "none"

# ─────────────── Edge ───────────────
section "Load Balancers (ALB/NLB)"
aws elbv2 describe-load-balancers --region "$REGION" \
  --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,VpcId:VpcId,DnsName:DNSName}' \
  --output json 2>/dev/null || echo "none"

section "CloudFront Distributions (global)"
aws cloudfront list-distributions \
  --query 'DistributionList.Items[].{Id:Id,Domain:DomainName,Status:Status,Origins:Origins.Items[].DomainName}' \
  --output json 2>/dev/null || echo "none-or-no-distributions"

section "Route 53 Hosted Zones (global)"
aws route53 list-hosted-zones --query 'HostedZones[].{Id:Id,Name:Name,RecordCount:ResourceRecordSetCount}' --output json 2>/dev/null || echo "none"

section "API Gateways (REST)"
aws apigateway get-rest-apis --region "$REGION" --query 'items[].{Id:id,Name:name,CreatedDate:createdDate}' --output json 2>/dev/null || echo "none"

section "API Gateways (HTTP/v2)"
aws apigatewayv2 get-apis --region "$REGION" --query 'Items[].{Id:ApiId,Name:Name,Protocol:ProtocolType}' --output json 2>/dev/null || echo "none"

# ─────────────── Messaging ───────────────
section "SQS Queues"
aws sqs list-queues --region "$REGION" --output json 2>/dev/null || echo "none"

section "SNS Topics"
aws sns list-topics --region "$REGION" --output json 2>/dev/null || echo "none"

section "EventBridge Buses"
aws events list-event-buses --region "$REGION" --query 'EventBuses[].{Name:Name,Arn:Arn}' --output json 2>/dev/null || echo "none"

section "Kinesis Streams"
aws kinesis list-streams --region "$REGION" --output json 2>/dev/null || echo "none"

# ─────────────── Security ───────────────
section "IAM Roles (count only)"
aws iam list-roles --query 'length(Roles)' --output json 2>/dev/null || echo "no-access"

section "KMS Keys (customer-managed)"
aws kms list-keys --region "$REGION" --query 'length(Keys)' --output json 2>/dev/null || echo "none"

section "Secrets Manager (secret count)"
aws secretsmanager list-secrets --region "$REGION" --query 'length(SecretList)' --output json 2>/dev/null || echo "none"

section "GuardDuty Detectors"
aws guardduty list-detectors --region "$REGION" --output json 2>/dev/null || echo "not-enabled"

# ─────────────── Observability ───────────────
section "CloudWatch Log Groups (count)"
aws logs describe-log-groups --region "$REGION" --query 'length(logGroups)' --output json 2>/dev/null || echo "none"

section "CloudWatch Alarms (ALARM state)"
aws cloudwatch describe-alarms --region "$REGION" --state-value ALARM \
  --query 'MetricAlarms[].{Name:AlarmName,Metric:MetricName,State:StateValue}' \
  --output json 2>/dev/null || echo "none"

# ─────────────── Cost (last 30 days) ───────────────
section "Cost last 30 days (Cost Explorer — may fail without permission)"
aws ce get-cost-and-usage \
  --time-period "Start=$(date -u -v-30d +%Y-%m-%d 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d)" \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json 2>/dev/null || echo "no-access-or-not-enabled"

echo ""
echo "### Inventory complete."
