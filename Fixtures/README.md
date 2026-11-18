# Test fixtures

The `.xcresult` bundles that the tests read live in `Tests/XcresultparserTests/TestAssets`.
This folder keeps the sources used to record them, so a fixture can be recorded again
when a new Xcode version can no longer read it.

The folders here are not part of the xcresultparser package. SwiftPM ignores them.

## Rules for `.xcresult` fixtures

- **Commit the complete bundle.** Don't remove anything from `Data/`: every `data.*` item
  needs its `refs.*` file. xcresulttool migrates bundles written by an older Xcode in place
  and rebuilds `database.sqlite3` from these items. A bundle that only has its database
  works with the Xcode that wrote it and breaks with the next one.
- **Record without test diagnostics.** If a test fails, `xcodebuild` adds diagnostics of
  around 100 MB unless you pass `-collect-test-diagnostics never`.
- **Include the database.** Xcode 27 no longer writes `database.sqlite3` when it records a
  bundle; xcresulttool creates it the first time it reads the bundle. Run any xcresulttool
  command once before copying the bundle, so the database is part of the fixture.
- **Register the bundle** as a resource of the test target in `Package.swift`. Each resource
  is listed there explicitly, so don't put other files into `TestAssets`.
- **Load it with `TestFixtures.xcresult("name")`** in tests, not with
  `Bundle.module.url(forResource:withExtension:)`. Tests run in parallel, and several tests
  opening the same bundle while xcresulttool migrates it make the migration fail.
  `TestFixtures` gives each test its own copy.

## SessionLevelFailureRepro

Records `session_level_failure.xcresult`, used by `testJunitXMLSessionLevelFailure` and
`testSonarXMLOmitsSessionLevelFailures`. The expected JUnit output is
`TestAssets/junit_session_level_failure.xml`.

The package has one suite with two tests. `passingTest()` passes.
`triggerSessionLevelFailure()` records an issue that belongs to no test or suite.
xcresulttool lists such issues under "Issues recorded without an associated test or suite",
and xcresultparser reports them in a "Session-level issues" test suite.

Producing such an issue takes some care. Since Xcode 27, Swift Testing attributes an issue
to the test whose source contains the `Issue.record` call, even when the issue is recorded
on another thread or after the test returned. `Task.detached` inside a test is no longer
enough. The repro therefore calls `Issue.record` in a function outside any test and runs it
on a plain `Thread`.

### Recording the fixture

```sh
cd Fixtures/SessionLevelFailureRepro
rm -rf session_level_failure.xcresult
xcodebuild test -scheme SessionLevelFailureRepro -destination "platform=macOS" \
  -collect-test-diagnostics never -resultBundlePath session_level_failure.xcresult

# Creates database.sqlite3 in the bundle.
xcrun xcresulttool get test-results summary --path session_level_failure.xcresult > /dev/null

ASSETS=../../Tests/XcresultparserTests/TestAssets
rm -rf "$ASSETS/session_level_failure.xcresult"
mv session_level_failure.xcresult "$ASSETS/"
```

The folder's `.gitignore` keeps `.swiftpm`, `.build` and result bundles out of git.

`xcodebuild` reports `** TEST SUCCEEDED **`, because the session-level issue doesn't fail a
test. The console output should show `Test «unknown» recorded an issue`. If it names
`triggerSessionLevelFailure()` instead, Swift Testing attributed the issue to the test,
and the bundle has no session-level issue.

Then update the expectations:

1. From the repository root, run `swift run xcresultparser -o junit Tests/XcresultparserTests/TestAssets/session_level_failure.xcresult`
   and compare the result with `junit_session_level_failure.xml`. The total `time` and
   the test order change with each recording.
2. `testSonarXMLOmitsSessionLevelFailures` expects each test's duration in milliseconds, as
   recorded in the bundle. Take the new values from
   `swift run xcresultparser -o xml Tests/XcresultparserTests/TestAssets/session_level_failure.xcresult`.
   Tests shorter than 1 ms are reported as `1`.
3. Run `swift test`.

The current fixture was recorded on 2026-11-18 with Xcode 27.2. The GitHub runner uses
Xcode 26.7, so check the CI run after recording the fixture again.
