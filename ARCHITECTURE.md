# System Architecture: E5 Cloud

E5 Cloud operates on a fully decoupled, serverless microservices stack. We utilize event-driven triggers to execute business logic without any server-side management or networking overhead.

* **Intake Layer:** API Gateway entry points integrated with AWS WAF for edge filtering.
* **Logic Layer:** Pure Python Lambda functions (strictly no JavaScript) triggered by API events.
* **Persistence Layer:** DynamoDB with provisioned RUs/WUs configured for sub-millisecond response.
* **Orchestration:** Managed via Terraform modules. No manual provisioning. 
* **Telemetry:** Real-time observability via CloudWatch Logs and OpenClaw alerting.

