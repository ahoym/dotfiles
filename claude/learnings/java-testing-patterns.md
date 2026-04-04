### Remove duplicate assertions that recheck already-asserted fields

Duplicate assertions add noise and create false confidence — a field asserted twice looks more thoroughly tested but provides no additional signal. Assert each field exactly once. If a second assertion seems necessary, it usually means the test is validating two distinct behaviours and should be split.

### TestNG @AfterClass vs @AfterMethod lifecycle mismatch with AutoCloseable

When `@BeforeMethod` opens a resource (connection, stream, temporary file), cleanup must use `@AfterMethod`, not `@AfterClass`. `@AfterClass` runs once after all test methods complete — any resource opened in the second `@BeforeMethod` invocation stays open for the duration of the remaining tests. This causes resource leaks that are invisible until the test suite grows.

### Test method names must describe what is being tested, not the input value

A method named `getItemsTestOnFilterAsNull` that actually exercises a wildcard `"*"` path is actively misleading — it hides bugs by pointing reviewers at the wrong scenario. Name tests after the behaviour under test: `getItemsWithWildcardFilter`. When a test name references an input value, verify the name still matches after any refactor that changes that value.
