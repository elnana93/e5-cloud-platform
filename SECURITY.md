# Security Posture & Defense-in-Depth

## 1. Identity & Access Management (IAM)
- **Principle of Least Privilege**: Every service (Lambda, DynamoDB) operates under its own granular IAM policy. No wildcards (*) used for action or resource levels.
- **Hardware-Enforced Auth**: Administrative access to the AWS Management Console and CLI requires FIDO2-compliant physical hardware keys (e.g., YubiKey).
- **Just-In-Time (JIT) Access**: Production environments are restricted; access is only granted via temporary, audited sessions.

## 2. Infrastructure Security (Network & Edge)
- **Zero-Trust Network**: Compute resources reside in private subnets with no public internet ingress. Communication is gated through an API Gateway configured with WAF (Web Application Firewall).
- **Edge Protection**: AWS WAF is deployed with managed rule sets to block SQL injection, cross-site scripting (XSS), and malicious bot traffic at the edge.
- **Encryption Standards**: 
    - **In-Transit**: TLS 1.3 enforced for all internal and external communication.
    - **At-Rest**: AES-256 encryption via AWS Key Management Service (KMS) with Customer Managed Keys (CMK) for absolute control.

## 3. Data Governance & Observability
- **Immutable Auditing**: AWS CloudTrail logs are enabled, replicated to a hardened, write-once-read-many (WORM) S3 bucket.
- **Threat Detection**: GuardDuty is active to monitor for anomalies, unauthorized API calls, and malicious behavior patterns.
- **Automated Compliance**: Infrastructure configurations are checked against CIS AWS Foundations Benchmarks via automated drift detection.

## 4. Development Security (DevSecOps)
- **Secrets Management**: No hardcoded secrets. All credentials are injected at runtime via AWS Systems Manager Parameter Store or Secrets Manager.
- **Supply Chain Integrity**: Every Lambda layer and dependency is scanned for vulnerabilities during the CI/CD pipeline build process.

## Skillsets Applied
- **DevOps Engineering**: Implementing automated security gating and policy-as-code (PaC).
- **Cloud Engineering**: Hardening VPCs, securing API ingress, and managing KMS/IAM lifecycle.
- **Solutions Architecture**: Designing resilient, compliant systems that adhere to Zero-Trust principles.
