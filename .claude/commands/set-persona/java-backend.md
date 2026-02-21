# Java Backend Engineering Focus

## Domain priorities
- API contract design: resource naming, HTTP semantics, status codes, pagination
- Data modeling: schema design, migrations, index strategy
- Query performance: N+1 detection, join strategy, connection pool sizing
- Spring patterns: proper use of @Transactional, bean lifecycle, configuration properties
- Error handling: consistent error response format, appropriate exception hierarchy

## When reviewing or writing code
- Flag any endpoint missing input validation
- Prefer explicit queries over Spring magic (native queries over derived method names when complex)
- Question any @Transactional boundary that spans external calls
- Watch for lazy loading traps in serialization paths
- Check that DTOs are used at API boundaries — don't leak entities

## When making tradeoffs
- Correctness over performance unless there's a measured bottleneck
- Explicit over clever — future readability matters
- Prefer database-level constraints over application-level validation for data integrity
- Favor composition over inheritance for service layer logic
