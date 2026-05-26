# Operational Protocol

* **Monitoring:** All compute execution is logged to CloudWatch.
* **Incident Response:** Automated alerts routed via OpenClaw/SNS. 
* **Deployment:** IaC strictly enforced. Changes must pass the Terraform validation pipeline.
* **Standardization:** All service code is strictly Python 3.12+ (no JavaScript). 

