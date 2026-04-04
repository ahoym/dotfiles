Messaging patterns: broker-level routing as validation, AMQP routing keys.
- **Keywords:** AMQP, routing key, message broker, validation, over-engineering
- **Related:** none

---

### Broker-level routing as sufficient validation for message context

AMQP routing keys provide exact-match filtering at the broker level. When a consumer binds to a specific routing key, re-validating the same fields (e.g., event type, venue name) at the application level adds no safety and is over-engineering. The broker guarantees only matching messages reach the consumer. Reserve application-level validation for fields that aren't part of the routing key or for cross-field business rules.
