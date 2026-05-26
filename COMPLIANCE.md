# Security & Compliance Standards

E5 Cloud enforces a strict, serverless-native Zero-Trust posture.

* **IAM Scoping:** Every microservice possesses a unique, granular IAM role—zero broad permissions.
* **Edge Defense:** AWS WAF provides perimeter protection at the API Gateway level.
* **Encryption:** Data-at-rest secured by AWS KMS; data-in-transit secured via TLS 1.3.
* **Hardware Auth:** YubiKey-backed authentication for all administrative control access.
* **Immutable Operations:** Infrastructure is managed exclusively via Terraform. No manual console or shell access permitted.

