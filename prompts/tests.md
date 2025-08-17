## Unit Test Guidelines

### Test Naming

* concicsely describe the desired behaviour verified by the test as a requirement. e.g. `provides a tile for a given identity` or `invokes the tile provider asynchronously`. Do not include implementation or technical details like `returns false` or `throws an exception`. Instead, describe the business requirement.
* DO NOT use words "expected", "handles" or "correct". Describe what the correct behaviour is.
* DO NOT use redundant words like "should", "check", or "verify"

### Test Implementation

* Include an assertion or expect that matches what the test name claims to verify
* Tests MUST include an assertion. Assertions in a helper method are acceptable.
* Do not duplicate test code, instead extract common code to helper functions but only when necessary
* Group related tests in a common describe section
* Perfer to initialize fields inline rather than in a `setUp` method.
* Do not add tests for the constructor, unless it has non-trivial logic
* Test files should be placed in folders that match the implementation files. e.g. the `lib/` folder maps to `test/`, `lib/src` maps to `test/src`
* If a mock is required, extract it to a separate file so that it can be used by other tests. DO NOT duplicate mocks
* DO NOT extend production code in tests, unless necessary
* DO NOT add comments. Instead, write readable code

To run tests, use the command `flutter test`

Ensure that all tests pass. If there are tests that are failing due to an implementation bug, leave those tests failing and explain the bug.