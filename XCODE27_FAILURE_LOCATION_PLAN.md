# Plan: Restore failure source locations under Xcode 27

Status: **waiting for Xcode 27 final** (analysis done 2026-07-18 against Xcode 27 beta,
xcresulttool version 25094, schema 0.4.0). If Xcode 27 final still omits the location
prefix (see "Root cause"), implement the steps below. If Apple reverts to the old
format, close this plan; the test normalization (see "Cleanup") is harmless to keep.

## Symptom

On Xcode 27 beta, JUnit/Sonar failure texts lose their trailing source location.

- Xcode ≤ 26.5: `failed - Unable to create ... test.xcresult (XcresultparserTests.swift:109)`
- Xcode 27 beta: `failed - Unable to create ... test.xcresult`

The 7 `testJunitXML*` fixture tests only pass on Xcode 27 because
`assertXmlTestReportsAreEqual` currently strips the suffix from both sides
(`normalizedFailureText` in `Tests/XcresultparserTests/XcresultparserTests.swift`).

## Root cause

The ` (file:line)` suffix is appended by xcresultparser itself, in
`JunitFailureSummary.failureXML(projectRoot:)` (`Sources/xcresultparser/JunitXML.swift`,
~line 538), whenever `documentLocation` is non-nil. `documentLocation` comes from
`FailureMessageDetail(from:)` (`Sources/xcresultparser/SharedTypes/FailureMessageDetail.swift`),
which parses the *name* of "Failure Message" nodes in `xcresulttool get test-results tests`:

- Xcode ≤ 26.5 node name: `"XcresultparserTests.swift:109: failed - <message>"`
  → parsed into `message` + `documentLocation` (`"<basename>:<line>"`).
- Xcode 27 beta node name: `"failed - <message>"` (no `file:line:` prefix)
  → `FailureMessageDetail.init?` returns nil → `documentLocation` is nil → no suffix.

The `tests` subcommand on Xcode 27 carries **no** location information anywhere.
The location moved to `xcresulttool get test-results test-details --test-id <id>`:

```json
{
  "name": "failed - Unable to create CoverageConverter from ...",
  "nodeType": "Test Case Run",
  "result": "Failed",
  "sourceLocation": {
    "filePath": "/Users/fhaeser/code/xcresultparser/Tests/XcresultparserTests/XcresultparserTests.swift",
    "lineNumber": 109
  },
  "children": [
    { "nodeType": "Source Code Reference", "sourceLocation": { ... } },
    ...
  ]
}
```

Note `filePath` is absolute (build machine path) and `lineNumber` is an Int, whereas
the old prefix gave only the basename. Also note the sonar path-rewriting tests
(`sonarTestExecutionWithProjectRoot*.xml`) rewrite the path *inside* the suffix — that
happens in `resolvedDocumentLocation`/class-map code operating on `documentLocation`,
which expects a **basename**.

## What already exists (no new plumbing needed)

- `XCResultToolProviding.getTestDetails(path:testId:)` — already implemented in
  `Sources/xcresultparser/SharedTypes/Services/XCResultToolClient.swift`.
- `XCTestDetails.testRuns` already decodes as `[XCTestNode]`
  (`Sources/xcresultparser/Models/XCResultToolModels/XCTestDetails.swift`).
- `XCTestNodeType` already has `.testCaseRun` and `.sourceCodeReference` cases.

Only missing piece: `XCTestNode` does not decode `sourceLocation`.

## Implementation steps

1. **Model**: Add `struct XCSourceLocation: Codable { let filePath: String; let lineNumber: Int }`
   and an optional `let sourceLocation: XCSourceLocation?` to `XCTestNode`
   (`Sources/xcresultparser/Models/XCResultToolModels/XCTestNode.swift`) — decode with
   `try?` in the custom `init(from:)` like the other optionals.

2. **Fallback in the JUnit data provider**
   (`Sources/xcresultparser/DataProviders/JunitXML/XCResultToolJunitXMLDataProvider.swift`):
   In `failureSummaries` construction (~line 36), when
   `bestFailureMessage(...)?.documentLocation` is nil, call
   `getTestDetails(path:testId: failure.testIdentifierString)` and walk `testRuns`
   depth-first for the first node with a non-nil `sourceLocation` (prefer
   `nodeType == .testCaseRun` whose `name` matches `failure.failureText`, else any
   `.sourceCodeReference`). Build
   `documentLocation = "\((filePath as NSString).lastPathComponent):\(lineNumber)"` —
   **basename**, to reproduce the Xcode ≤ 26 format byte-for-byte and keep the sonar
   class-map path resolution working unchanged.
   - Only invoke `test-details` for failures (one extra xcresulttool process per
     failing test — acceptable, failures are few).
   - Session-level failures (`sessionLevelFailures`, ~line 321): keep the existing
     `extractLocation(from: failure.testIdentifierURL)` as last resort; synthetic
     test ids may not resolve via `test-details`. Try the same fallback first, guarded.

3. **Parity in other formatters** (optional, decide then):
   `XCResultFormatter.swift` has a parallel `failureMessageDetailsByTestIdentifier`
   (~line 675) feeding text/HTML/xml output. Same fallback applies if location info
   is missing there on Xcode 27. Check its output on the fixtures before deciding.

4. **Cleanup — revert test tolerance**: Remove `normalizedFailureText` from
   `assertXmlTestReportsAreEqual` in `Tests/XcresultparserTests/XcresultparserTests.swift`
   so fixture comparison is strict again. The existing fixtures already contain the
   suffix and need no changes.

5. **New unit test**: Stub the data provider (see `MockedShell` pattern) with a canned
   Xcode-27-style `tests` JSON (Failure Message node without prefix) plus a canned
   `test-details` JSON with `sourceLocation`, and assert the failure element ends in
   ` (File.swift:109)`. This keeps the fallback covered even when CI runs an Xcode
   whose xcresulttool still emits the old format.

## Verification

- `swift test` must pass on **both** Xcode 26.5 (CI, macos-latest) and Xcode 27.
- Manual: `swift run xcresultparser -o junit Tests/XcresultparserTests/TestAssets/test.xcresult`
  and diff against `Tests/XcresultparserTests/TestAssets/junit.xml` — identical modulo
  indentation. Expected suffix present: `... test.xcresult (XcresultparserTests.swift:109)`.
- Fixtures covering the suffix: `junit.xml`, `junit_merged.xml`, `junit_repeated.xml`,
  `junit_session_level_failure.xml`, `sonarTestExecution.xml`,
  `sonarTestExecutionWithProjectRootAbsolute.xml`, `sonarTestExecutionWithProjectRootRelative.xml`.

## Quick re-check when Xcode 27 final ships

```sh
xcrun xcresulttool version
xcrun xcresulttool get test-results tests --path Tests/XcresultparserTests/TestAssets/test.xcresult \
  | grep -o '"name" : "[^"]*failed[^"]*"' | head -3
```

If the failure-message names start with `<file>.swift:<line>:` again → format reverted,
close this plan. If they are bare messages → implement the steps above.
