# Observability

Charmed OAI RAN integrates with Canonical’s Observability Stack (COS) to provide a comprehensive view of the 5G network's operations. Through this integration, operators can effectively monitor logs and diagnose potential issues.

- **Logging**: Both the CU and DU charms implement the [loki_push_api](https://charmhub.io/integrations/loki_push_api) charm relation interface, which allows them to send logs to Loki, the COS logging service. This enables operators to collect, centralize, and query logs from the Charmed OAI RAN deployment.

For more information about COS, read its [official documentation](https://charmhub.io/topics/canonical-observability-stack).
