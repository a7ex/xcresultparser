---
name: xcode-mcp
description: How to drive Xcode through its MCP server (`xcrun mcpbridge`, tools named `mcp__xcode__*`) in this project — resolving the workspace, navigating, reading, searching and editing project files, string catalogs, schemes and build settings, building the right scheme, running tests, rendering previews, running and debugging the app, reading tool artifacts, and interacting with the simulator. Load before the first Xcode MCP call of a session, before any work on the Xcode project's files, and whenever an Xcode tool reports "No workspaces are currently open", "Unknown workspace identifier" or "Connection closed".
---

# Using Xcode's MCP server

Xcode ships an MCP server; `xcrun mcpbridge` is only a STDIO relay between the agent and the
running Xcode process. It is registered in Claude Code as the `xcode` server. `xcrun mcpbridge
--help` documents the relay alone (env vars `MCP_XCODE_PID`, `MCP_XCODE_SESSION_ID`, and
`run-agent`), so use it only to diagnose the bridge; each tool's own description is the only
reference for the tools themselves.

Use the bridge as the primary interface for everything inside the Xcode project, for the whole
task — not just the first call.

## 1. Loading the tools

The `mcp__xcode__*` tools are deferred. Load the schemas you need with `ToolSearch`
(`select:mcp__xcode__XcodeListWorkspaces,mcp__xcode__BuildProject`) before calling them —
several per call is fine. Never guess parameter names from memory.

The tool set changes with Xcode releases, so do not trust tool names from memory or older docs
either — including the map in section 2. `XcodeListWindows`, `XcodeListNavigatorIssues`,
`ExecuteSnippet` and `DocumentationSearch` do not exist here (checked 2026-10-10, iOS 27.1 SDK,
53 tools; snippets are `RunCodeSnippet`). Other projects' notes that rely on
`DocumentationSearch` describe a different Xcode. The list of deferred tools in the session is
authoritative.

## 2. What the tools cover

Check each name against the deferred list before relying on it.

| Area | Tools |
|---|---|
| Workspaces | `XcodeListWorkspaces`, `XcodeOpenWorkspace`, `XcodeCloseWorkspace` |
| Navigation | `XcodeLS`, `XcodeGlob`, `XcodeGrep`, `XcodeRead` |
| Editing | `XcodeUpdate`, `XcodeWrite`, `XcodeMakeDir`, `XcodeMV`, `XcodeRM` |
| New projects and targets | `XcodeListTemplates`, `XcodeNewProject`, `XcodeNewTarget` |
| Code experiments | `RunCodeSnippet` |
| Configuration | `XcodeListSchemes` / `XcodeSwitchScheme`, `XcodeListTargets`, `XcodeListRunDestinations` / `XcodeSwitchRunDestination`, `XcodeListTestPlans` / `XcodeSwitchTestPlan`, `GetTargetBuildSettings` / `UpdateTargetBuildSetting`, `GetFileCompilerFlags` / `UpdateFileCompilerFlags`, `AddInfoPlist`, `AddEntitlement` |
| Build and diagnostics | `BuildProject`, `GetBuildLog`, `XcodeRefreshCodeIssuesInFile` |
| Tests | `GetTestList`, `RunSomeTests`, `RunAllTests` |
| Previews | `RenderPreview` |
| Running and debugging | `RunProject`, `StopProject`, `GetConsoleOutput`, `InvokeDebuggerCommand` |
| Simulator and device | `DeviceInteractionStartWorkspaceSession`, `DeviceInteractionStartSession`, `DeviceInteractionInstallAndRun`, `DeviceInteractionSynthesize`, `DeviceInteractionEndSession` |
| Localization | `StringCatalogRead`, `StringCatalogContext`, `StringCatalogEdit`, `LocalizationPlanner` |
| Field diagnostics | `GetTopCrashIssues` / `GetCrashIssueLogs`, `GetTopFieldPerformanceIssues` / `GetFieldPerformanceIssueLogs` |

The default loop is small: inspect (`XcodeLS`, `XcodeGrep`, `XcodeRead`) → edit (`XcodeUpdate`)
→ validate with the smallest meaningful step (build, a targeted test, a preview) → on failure
read `GetBuildLog`, fix the cause, and rerun that same step rather than rerunning blindly.

## 3. Every call names its workspace

1. Call `XcodeListWorkspaces` first. It returns each open workspace as
   `workspaceIdentifier: windowtab-…` (or `workspace-…`), `workspacePath:
   …/CarambolCounter.xcodeproj`.
2. Match `workspacePath` to this checkout, and pass that `workspaceIdentifier` to **every**
   other Xcode tool.

- Pass the generated identifier, not the path. The current tool descriptions say an absolute
  path is accepted too, but older servers answered it with *"Unknown workspace identifier"*.
- Omitting the identifier fails with *"workspaceIdentifier is required … No workspaces are
  currently open"* — even when a workspace is open. That message is about your call, not about
  Xcode. Only believe it when `XcodeListWorkspaces` itself comes back empty.
- When the list is empty (for example after Xcode was updated or restarted),
  `XcodeOpenWorkspace` with the absolute path of `CarambolCounter.xcodeproj` opens it. It also
  works when the project is already open: it grants the session's approval.
- **The `workspace-…` id `XcodeOpenWorkspace` returns is not the owner's window.** It names a
  separate background instance of the same project. Scheme and test-plan switches there never
  reach the owner's window (they report success, then revert), builds there use that instance's
  scheme, and with it open, test runs have crashed Xcode. So straight after opening: call
  `XcodeListWorkspaces` again, use the `windowtab-…` id from then on, and close the
  `workspace-…` instance with `XcodeCloseWorkspace` on that exact id — never the `windowtab-…`
  one.
- The identifier belongs to a window tab and changes when the bridge reconnects, Xcode
  restarts or the project is reopened. Re-list then; never reuse one from an earlier session or
  another checkout.

## 4. When the bridge cannot see Xcode

| Symptom | Cause | What to do |
|---|---|---|
| `XcodeListWorkspaces` is empty | Xcode has no project open | `XcodeOpenWorkspace` on `CarambolCounter.xcodeproj` (section 3) |
| `Connection closed`, or tools fail after Xcode restarted | The bridge lost its XPC connection | Ask the owner to run `/mcp` and reconnect `xcode` — no session restart needed |
| Tools work but act on the wrong Xcode | Several Xcodes running | The bridge follows `xcode-select`; `xcrun --find mcpbridge` shows which one |
| A tool is missing | Not loaded, or not in this Xcode version | Load it with `ToolSearch`; if it is not in the deferred list, it does not exist here |

Ask; do not work around it with `xcodebuild` or `simctl` (collaboration skill, one-click rule).

## 5. Files and project structure

Use `XcodeRead` / `XcodeWrite` / `XcodeUpdate` and `XcodeMakeDir` / `XcodeMV` / `XcodeRM` for
every file in the project, and `XcodeGrep` / `XcodeGlob` to search it. They keep the project's
group structure in sync. Prefer them even where the generic file tools feel more familiar.

- Paths are navigator paths, which can differ from filesystem paths. Start with `XcodeLS /`
  when unsure.
- `XcodeUpdate` for surgical edits: read first, match a unique block. `XcodeWrite` only for a
  new file or a deliberate full replacement.
- Never `replaceAll` when `newString` contains `oldString` (renaming `Foo` to `MyFoo`): the
  tool re-matches its own output and loops — "Replaced 1000 occurrences", one 4,000-character
  name. Edit each occurrence on its own instead.
- Before `XcodeRM`, inspect the exact item. Never remove a broad or unresolved path.
- Target membership for a new file in `CarambolCounterAppShared` (watch, TV) is a one-click job
  for the owner — ask rather than editing `project.pbxproj`. The same goes for build settings,
  entitlements and Info.plist keys: list first, and say what you intend to change before using
  `UpdateTargetBuildSetting`, `AddEntitlement` or `AddInfoPlist`.
- **Swift package sources** are in the navigator under `packageDependencies` (`XcodeLS /`).
  Browse, grep and read them there; do not dig through DerivedData for checkout paths.

Generic tools stay right for git, repository scripts with no Xcode tool, files outside the
project (`IssueBacklog.md`, `docs/`, the Android repo, memory), and processing command output.
Falling back for anything else needs a concrete reason — a tool that is missing or failed —
and you say what it was.

## 6. Apple APIs

When an API's signature, availability, deprecation or concurrency behaviour is uncertain, check
it before using it. The bridge has no documentation search; read Xcode's
`swiftui-whats-new-27` and related skills (section 11), or check with `RunCodeSnippet`.
`RunCodeSnippet` compiles and runs a focused snippet in the context of a source file; it does
not replace a build or a test.

## 7. Building

`BuildProject` is the one tool whose result does **not** name the scheme it built. The project
has aggregate schemes (`Run swiftformat`, `CreateSnapShots`) that "succeed" in under two
seconds having compiled nothing.

- **Before:** `XcodeListSchemes` — its first field is `activeSchemeName`. Switch with
  `XcodeSwitchScheme` only after telling the owner.
- **After:** `grep -o "in target '[A-Za-z]*'" <fullLogPath> | sort | uniq -c` lists what was
  actually compiled.
- The iOS scheme also builds the watch app. `CarambolCounterTV` needs its own scheme — a clean
  iOS build says nothing about tvOS.
- After editing test files (including the generated `SwiftPreviewTests.swift`), build with the
  test targets so they compile too.
- SourceKit "Cannot find X in scope" diagnostics are usually stale-index noise.
  `XcodeRefreshCodeIssuesInFile` may clear them; when it does not, trust `BuildProject` and
  `GetBuildLog`.

## 8. Tests

- `RunAllTests` / `RunSomeTests` report `schemeName` and `activeTestPlanName` in every result,
  so a wrong scheme fails loudly. Prefer `RunSomeTests` for focused changes.
- **Check the run destination first** (`XcodeListRunDestinations`, active one is listed
  first). On a physical device every snapshot test fails with a bogus permissions error. Ask
  before switching with `XcodeSwitchRunDestination`.
- `RunSomeTests` answering *"Test '…' not found"* while `GetTestList` shows almost nothing means
  the test index is not populated yet (typically right after a reconnect) — not that the test
  is missing.
- Snapshot tests are skipped in the unit plan on purpose; they run in the AllTests / TV plans.
  Re-record through the `RecordFailedSnapshotTests` configuration — never delete reference PNGs.
- Switching test plans (`XcodeSwitchTestPlan`) changes the owner's Xcode state: say so first.

## 9. Previews, running and debugging

- `RenderPreview` renders a `#Preview` from a source file and returns an image path. It can drop
  the connection or time out on a slow first render, and views that open the camera
  (`QRCodeScannerView`) time out. If it fails, see section 4 rather than retrying in a loop. A
  rendered preview does not replace a build or a test.
- `RunProject` / `StopProject` run the active scheme; confirm the app launched before
  interacting, read `GetConsoleOutput` for its log, and stop it when done.
  `InvokeDebuggerCommand` is for investigating behaviour, never for patching over a bug.
- Crash and field-performance reports are evidence, not proof of a cause: match them to the
  checked-out revision before changing code.

## 10. Tool artifacts

Screenshots, hierarchies, logs and full listings land under
`$TMPDIR/ActionArtifacts/…`. The `Read` tool cannot open that folder: `cp` the file into the
scratchpad first, then read it.

## 11. Driving the simulator

Xcode's own `device-interaction` skill is the manual for `DeviceInteraction*` tools. It is not
installed as a Claude Code skill; export Xcode's skills and read it:

```bash
xcrun agent skills export "<scratchpad>/xcode-skills"   # absolute path — a relative one resolves against / and fails
```

Key points from it:

- Lifecycle: `DeviceInteractionStartWorkspaceSession` (bound to the workspace, needed for
  `DeviceInteractionInstallAndRun`) → `DeviceInteractionInstallAndRun` after each change →
  `DeviceInteractionSynthesize` to interact → `DeviceInteractionEndSession` when done
  (sessions are expensive; always end them).
- It wants the interaction done in a subagent that gets the session identifier.
- Use `commandLineArguments` / `environmentVariables` on `InstallAndRun` (with `$(inherited)`)
  instead of editing the scheme.
- Tap the `hitPoint` from the returned hierarchy, not a position estimated from the screenshot.

`DeviceInteractionSynthesize` commands (verified on the iPhone 18 Pro simulator):

- `t x y` tap · `d x y` double tap
- `t x1 y1 f x2 y2 [duration]` swipe (`t 360 255 f 80 255 0.3` swipes a row left)
- `drag x1 y1 x2 y2 [hold] [move]` press-and-hold drag
- `w seconds` wait — also a no-op way to capture a fresh screenshot and hierarchy
- `b <button>` hardware button · `orientation <value>`

The same export contains `swiftui-specialist`, `swiftui-whats-new-27` and `modernize-tests`,
which are worth reading for SwiftUI and testing work on the 27 SDKs.

`skills export` is not the whole set. The complete plugin — including `translation`,
`translation-coordinator` and the accessibility specialists — is materialized by:

```bash
xcrun agent plugin path --plugin-format claude   # prints …/ExportedPlugins/<build>/claude
```

Read the skills from `<that path>/skills/<name>/SKILL.md`.

## 12. String Catalog

`Localizable.xcstrings` is edited through `StringCatalogContext` → `StringCatalogEdit`, not by
writing the JSON (`StringCatalogRead` to inspect it). Both editing tools demand Xcode's
`translation` skill first (section 11 says where it is); it requires reading
`references/styleguide_<locale>.md` for quote and punctuation rules.

- A changed English text is a new key. Build first: the build extracts the new key and marks
  the old one `extractionState: stale`. There is no delete tool — leave stale entries to the
  owner.
- Translations already in the catalog beat the style guide where they disagree (straight
  apostrophes in fr/it/tr, German "du"): match what is there.
- Pass curly quotes as `„…“` escapes, as the tool asks; they are stored as the real
  characters. Non-breaking spaces (French « ») go in as ` `.
- Several `StringCatalogEdit` calls for different locales of one key can run in parallel
  without overwriting each other.
- Still respect the project rules: the catalog is a shared resource, so say what you will add
  before adding it. Match the app's own terms (see the German-terminology memory).

## 13. Before calling an Xcode task done

- The workspace identifier came from `XcodeListWorkspaces` or `XcodeOpenWorkspace` in this
  session.
- Project files were read and changed through the Xcode tools.
- The scheme, destination and test plan you relied on were confirmed, not assumed.
- The smallest meaningful validation passed — and the report says which one, and what was not
  checked.
- No run or device-interaction session is left open.
