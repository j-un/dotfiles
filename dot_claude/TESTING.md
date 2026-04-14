## Unit Testing Principles

- **Test behavior, not implementation** — Verify observable outcomes (outputs, side effects, errors), not internal state or call counts.
- **Inject dependencies via interfaces** — External systems (databases, APIs, encryption, environment variables) must be abstracted behind interfaces and injected through constructors. Never call `os.Getenv` or instantiate clients inside business logic.
- **Prefer fakes over mock frameworks** — Use lightweight in-memory implementations that replicate real behavior. Reserve mock libraries for cases where fakes would be impractical.
- **Do not mock pure functions** — Pure functions (no side effects, deterministic output) should be called directly in tests. Mocking them adds maintenance burden with no benefit.
- **Minimum test coverage per endpoint** — Each public function should have tests for: success path, invalid input, authentication/authorization failure, and not-found cases where applicable.
- **Refactor for testability** — If code is hard to test, treat it as a design problem and refactor. Testable code is well-designed code.
