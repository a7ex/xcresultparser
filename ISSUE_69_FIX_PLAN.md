# Issue 69 Fix Plan

Issue: [XML output produces invalid SonarQube test execution reports since 2.0.0](https://github.com/a7ex/xcresultparser/issues/69)

## Objective

Restore valid SonarQube generic test execution output for Xcode 26 result bundles by ensuring that:

- every `<file path="...">` identifies the test source file containing the reported tests;
- Swift Testing suite display names are not treated as source-file identifiers;
- production source files are not selected when a test container has a different canonical type name;
- every `<testCase>` has the required integer `duration` attribute in milliseconds; and
- existing JUnit output remains compatible.

Sonar test-file resolution continues to require `--project-root`, because an `.xcresult` bundle generally identifies test containers rather than providing their source-file paths directly.

## Confirmed causes

### Test suite display names are used as identifiers

`XCResultToolJunitXMLDataProvider.mapGroup` currently uses the mapped group name as the current test class name. For test-suite nodes, `mappedGroupIdentifier` also returns `node.name`.

With Swift Testing, `node.name` can be a user-facing suite display name or a name resembling the production subject. The child test node can still carry the canonical identifier, for example:

```text
SessionLevelFailureTests/passingTest()
```

Discarding that identifier causes the project-root lookup either to return the display name unchanged or to resolve a production class with the same name.

### Missing durations are preserved as `nil`

Xcode 26 can omit `durationInSeconds` from the compact `xcresulttool get test-results tests` payload. The model correctly decodes the field as optional, but the provider passes `nil` into `JunitTest` and the XML serializer only emits a duration when the value exists.

SonarQube requires `duration` on every test case.

### Existing coverage does not validate the Sonar contract

The session-level Xcode 26 fixture reproduces a display-name path and missing durations, but its Sonar test currently checks only that synthetic session-level failures are omitted. It does not validate file paths or required attributes.

## Implementation steps

### 1. Add failing regression tests

Add focused provider and serialization tests before modifying production code.

Cover at least:

- a suite whose display name differs from its canonical Swift type;
- a suite display name matching a production type while its canonical test type ends in `Tests`;
- test nodes without `durationInSeconds`;
- parameterized tests under a display-named suite;
- a failed test under a display-named suite, ensuring its failure summary still matches; and
- the existing Xcode 26 session-level fixture.

Primary files:

- `Tests/XcresultparserTests/XCResultToolJunitXMLDataProviderTests.swift`
- `Tests/XcresultparserTests/XcresultparserTests.swift`

### 2. Resolve the canonical test-container identifier

Add a small resolver in `XCResultToolJunitXMLDataProvider` that keeps the human-readable suite name separate from the identifier used for matching and file lookup.

For a test-suite node, resolve the identifier in this order:

1. a usable suite `nodeIdentifier`;
2. the container prefix from a descendant test case's `nodeIdentifier`;
3. the corresponding component from `nodeIdentifierURL`; and
4. the suite name as a compatibility fallback.

For example, resolve `SomeClassTests/testSomeBehavior()` to `SomeClassTests` even when the suite display name is `SomeClass` or `MyFeature Tests`.

Avoid treating numeric node identifiers and complete test-method identifiers as container names.

Primary file:

- `Sources/xcresultparser/DataProviders/JunitXML/XCResultToolJunitXMLDataProvider.swift`

### 3. Use canonical identifiers consistently

Use the resolved container identifier for:

- `JunitTestGroup.identifier`, which feeds Sonar file lookup;
- constructed test identifiers;
- parameterized-test identifiers; and
- failure-summary matching.

Continue using the suite display name for human-readable JUnit suite and class names where doing so does not affect matching.

Prefer a test node's own canonical `nodeIdentifier` over reconstructing an identifier from display names.

Primary files:

- `Sources/xcresultparser/DataProviders/JunitXML/XCResultToolJunitXMLDataProvider.swift`
- `Sources/xcresultparser/Models/XCResultToolModels/XCTestNode+Extensions.swift`

### 4. Always serialize a Sonar duration

Change `JunitTest.xmlNode` so that Sonar output always includes `duration`:

- convert known seconds to integer milliseconds;
- emit `0` when Xcode does not provide a duration; and
- keep the existing optional `time` behavior for regular JUnit output.

Do not fetch `test-details` once per test solely to obtain a zero duration; that would add substantial process overhead and Xcode already reports zero for these cases in the detailed payload.

Primary file:

- `Sources/xcresultparser/JunitXML.swift`

### 5. Validate the complete Sonar contract

Strengthen tests to parse the generated XML and assert that:

- every `<testCase>` has a `duration` attribute;
- every duration is a non-negative integer;
- no suite or test-plan display name is emitted as a file path;
- project-root lookup selects the test file in a source/test naming collision;
- relative and absolute path modes return the expected test paths; and
- failed, skipped, expected-failure, repeated, and parameterized tests retain their existing behavior.

Where practical, centralize these checks in a test helper so future fixtures cannot silently produce invalid Sonar XML.

### 6. Run verification through Xcode MCP

Use `xcrun mcpbridge` and Xcode's `RunAllTests` tool.

Verification sequence:

1. run the focused provider tests;
2. run the focused Sonar serialization tests;
3. generate Sonar XML from `session_level_failure.xcresult` and inspect it directly;
4. run the complete test suite; and
5. classify any failures against the pre-change baseline.

At investigation time, Xcode reported 74 tests: 67 passed and 7 failed. The seven failures were existing XML fixture comparisons involving failure-location suffixes under the active Xcode toolchain; they were not caused by issue 69. The fix should introduce no additional failures and should make all new issue-69 regressions pass.

### 7. Document the compatibility fix

Add a changelog entry describing:

- corrected Swift Testing suite-to-file resolution for Xcode 26;
- guaranteed Sonar test-case durations; and
- the continuing `--project-root` requirement for resolving test types to files.

Primary file:

- `CHANGELOG.md`

## Acceptance criteria

The implementation is complete when:

- the issue's source-file misresolution case maps to the corresponding test file;
- suite and test-plan display names never appear as Sonar file paths when a canonical test container can be derived;
- every Sonar `<testCase>` contains an integer `duration` attribute, including tests whose duration is omitted by Xcode;
- parameterized tests and failure summaries still match correctly;
- relative and absolute project-root modes both work;
- regular JUnit output is unchanged except where canonical identifiers correct an existing mismatch;
- all new regression tests pass; and
- the full Xcode test run has no regressions relative to the recorded baseline.

## Expected scope

This should be a contained change across the data-provider mapping, Sonar serialization, tests, fixtures or synthetic payloads, and changelog. No public command-line API change should be necessary.
