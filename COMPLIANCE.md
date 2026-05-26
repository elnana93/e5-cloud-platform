# Compliance & Security Standards: Zero-Trust Posture

## The Zero-Trust Framework
- **Hardware-Backed Identity**: All administrative ingress is secured via YubiKey-enforced Multi-Factor Authentication (MFA).
- **Least Privilege Access**: Granular IAM roles strictly bound to individual Lambda functions and DynamoDB tables. No wildcard permissions allowed.

## Security Infrastructure
- **WAF & Shield**: Enterprise-grade protection against Layer 7 attacks, including SQL injection and XSS, with automated blocking.
- **Encryption**: TLS 1.3 in transit; AES-256 at rest with customer-managed keys (CMK) via AWS KMS.
- **Data Governance**: Full audit trail of all infrastructure changes recorded via AWS CloudTrail and ingested into Athena for forensic analysis.

## Skillsets Applied
- **DevOps Engineering**: Implementation of hard-coded security policies (Policy as Code).
- **Cloud Engineering**: Hardening of VPCs, private subnets, and API gateway security boundaries.
