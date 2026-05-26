# Reliability & Disaster Recovery: Enterprise Engineering Standard

## Service Level Agreement (SLA)
- **Target Uptime**: 99.99% availability via multi-region active-passive failover.
- **RTO/RPO**: RTO < 15m; RPO < 5m via asynchronous replication.

## Engineering Mechanisms
- **S3 Cross-Region Replication (CRR)**: All critical assets and backups are replicated across us-west-2 and us-east-1 to guarantee data durability against regional outages.
- **DynamoDB Global Tables**: Enabled for multi-region writes to eliminate data silos and provide sub-10ms latency for global clients.
- **Automated Circuit Breakers**: Custom Lambda logic implemented to prevent cascading failures during traffic spikes.
- **Infrastructure as Code (IaC) Integrity**: Terraform state is locked and versioned, ensuring deterministic, repeatable deployments.

## Skillsets Applied
- **Cloud Engineering**: Expert-level proficiency in AWS networking, VPC design, and multi-region synchronization.
- **DevOps Engineering**: Implementation of automated failover triggers and health monitoring via AWS CloudWatch.
