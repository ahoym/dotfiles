# AWS Messaging (SQS / SNS / EventBridge)

## SQS Queue Selection

### Standard vs FIFO
- **Standard**: higher throughput, at-least-once delivery, best-effort ordering. Default choice unless ordering or exactly-once matters.
- **FIFO**: exactly-once processing, strict ordering within message groups. Use for financial operations, state machines, or anything where duplicate processing causes real harm.
- FIFO throughput limit: 300 msg/s without batching, 3000 msg/s with high-throughput mode. If you need more, partition across message groups.

### Deduplication Strategies
- **Content-based**: SQS hashes the body — free but only works if identical body = identical intent.
- **MessageDeduplicationId**: explicit control — use for operations where the same logical action may produce different payloads (e.g., retry with updated timestamp).
- Deduplication window: 5 minutes. Operations that retry beyond that window need application-level idempotency.

## Consumer Design

### At-Least-Once Delivery
- **Design every consumer to be idempotent.** SQS guarantees at-least-once, not exactly-once (even FIFO can redeliver after visibility timeout).
- Track processed message IDs or use natural idempotency keys (transaction ID, event ID) to detect duplicates.
- Prefer upsert/conditional-write patterns over blind inserts.

### Visibility Timeout
- Set to: expected processing time + 50% buffer.
- Too short → message redelivered while still processing → duplicate work.
- Too long → failed messages stuck invisible → processing delay.
- Can extend dynamically via `ChangeMessageVisibility` for long-running tasks.

### Poison Message Handling
- Never let one bad message block the queue. Catch and log per-message, don't let exceptions propagate to the listener framework.
- Configure `maxReceiveCount` on the redrive policy (typically 3-5 attempts before DLQ).
- Include original message metadata in DLQ messages for debugging.

### Batch Processing & Long Polling
- Use `WaitTimeSeconds=20` (max long poll) to reduce empty receives and cost.
- Batch up to 10 messages per receive for throughput.
- Process batches in parallel where message ordering doesn't matter.

## Dead Letter Queues (DLQ)

- **Every queue must have a DLQ.** No exceptions.
- DLQ retention period should be longer than the source queue (14 days recommended) to allow investigation.
- Monitor DLQ depth — alert on any messages arriving. DLQ messages mean something is broken.
- Build a replay mechanism: ability to move DLQ messages back to the source queue after fixing the consumer.

## SNS Fan-Out

- Use SNS → multiple SQS subscriptions when one event needs to trigger multiple independent consumers.
- Each subscriber gets its own queue with its own DLQ and retry policy.
- Filter policies on subscriptions reduce noise — don't push everything to every subscriber.
- Raw message delivery (`RawMessageDelivery=true`) avoids double-wrapping JSON.

## EventBridge

- Prefer EventBridge over SNS when: you need content-based routing rules, schema registry, archive/replay, or cross-account event buses.
- Event patterns match on structure — design events with consistent top-level fields for easy routing.
- Archive events for replay during debugging or disaster recovery.

## Spring Cloud AWS Integration

- `@SqsListener` handles polling, deserialization, and acknowledgment.
- Configure `maxConcurrentMessages` and `maxMessagesPerPoll` to control throughput and backpressure.
- Use `Acknowledgement` parameter for manual ack when processing may fail after deserialization succeeds.
- Backpressure: if consumers can't keep up, reduce `maxConcurrentMessages` or add more consumer instances — don't increase visibility timeout as a band-aid.

## Correlation & Observability

- Include a correlation ID (trace ID) in every message — propagate it from the originating request through all async boundaries.
- Use SQS message attributes (not body) for routing metadata, correlation IDs, and version info.
- Metrics to track per queue:
  - `messages.sent` / `messages.received` / `messages.failed` (counters)
  - `messages.processing.duration` (timer)
  - DLQ depth (gauge or periodic check)
  - Consumer lag: `ApproximateNumberOfMessagesVisible` via CloudWatch

## Backpressure & Rate Limiting

- If downstream can't absorb the message rate, use a combination of:
  - Reduced `maxConcurrentMessages` on the consumer
  - Circuit breaker on the downstream call (fail fast, let visibility timeout redeliver)
  - Separate "slow lane" queue for degraded-mode processing
- Don't use `Thread.sleep()` or delays in consumers to throttle — it wastes threads and hides the real problem.

## Cross-Refs

- `claude/learnings/resilience-patterns.md` — idempotency, dedup-before-process, and retry patterns that complement SQS consumer design
- `claude/learnings/aws-patterns.md` — EventBridge scheduling limits, ECS Fargate cost-aware defaults
