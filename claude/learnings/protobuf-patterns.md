Proto3 schema evolution and compatibility patterns.
- **Keywords:** proto3, optional, backward-compatible, wire format, schema evolution, field addition, Protobuf
- **Related:** ~/.claude/learnings/java/integration.md

---

### Proto3 `optional` field addition is non-breaking

Adding an `optional` field to a proto3 message is backward-compatible at the wire level. Existing callers that omit the new field produce identical wire bytes to what they produced before. Only callers that want to use the new field need updating. This means new optional fields can be deployed to consumers before producers, or vice versa, without coordination.
