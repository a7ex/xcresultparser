# Agent guide for Swift and SwiftUI

This repository contains an Xcode project written with Swift. Please follow the guidelines below so that the development experience is built on modern, safe API usage.


## Collaboration

**Read [`.claude/skills/collaboration/SKILL.md`](.claude/skills/collaboration/SKILL.md) and follow it.** It is the authoritative description of how to work with the repository owner: when to ask instead of acting, how to make commands reviewable before requesting approval, the checkpointed rhythm for working an issue, and what to report. It is written to be tool-agnostic — do not duplicate its rules here, so the two cannot drift apart.

One project-specific instance of its "don't discard a clean solution because it is awkward for you" rule: editing `project.pbxproj` directly is undesirable for an agent, but that does *not* rule out solutions needing project changes.

### Always stop and ask first

The skill's rules ask for judgement, and judgement decays over a long session — agreeing early is not a licence to decide alone later. These triggers need none. Each one means: describe what you intend, then wait.

- **Breadth.** A change spanning more than ~10 files, or adding more than ~10 entries to any shared file.
- **New patterns at scale.** Applying an existing convention far beyond its current footprint (e.g. a technique used in 6 places, applied to 40) is a *new* decision, not the old one continued.
- **Anything irreversible or outward-facing.** Deleting or re-recording reference material, re-ordering a generated file, touching the web repository.
- **Deviating from an agreed plan**, even when the plan looks wrong. Say so and wait; do not implement the better idea and report it afterwards.

Asking once about a topic does not license every later decision in the same area. If you cannot point to the message where the owner agreed to *this* change, it has not been agreed.


## Core instructions

- Swift 6.2 or later, using modern Swift concurrency. Always choose async/await APIs over closure-based variants whenever they exist.
- Do not introduce third-party frameworks without asking first.
- Use the right comments. Triple / are for docc comments. Private interfaces are never meant to appear in Documentation


## Swift instructions

- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Avoid force unwraps and force `try` unless it is unrecoverable.
- Never use legacy `Formatter` subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter`. Always use the modern `FormatStyle` API instead. For example, to format a date, use `myDate.formatted(date: .abbreviated, time: .shortened)`. To parse a date from a string, use `Date(inputString, strategy: .iso8601)`. For numbers, use `myNumber.formatted(.number)` or custom format styles.

## Project structure

- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Write unit tests for core application logic.
- Comment with intent — neither comment-phobic nor noisy:
  - Every class, struct should have a DocC-style (`///`) doc comment at the top explaining its purpose/role.
  - DocC (`///`) is for the type and its public/internal API. **Private** methods/properties use regular (`//`) comments, not `///`.
  - Any code that is a hack, workaround, or otherwise hard to reason about should have a regular comment explaining *why*.
  - Don't pollute the code with comments that merely restate obvious code.
  - "Comments might go stale" is not an excuse to skip them — keep comments updated alongside the code they describe. Good comments help other developers and future-you.


## Codebase notes


## Xcode MCP

Xcode 26.3+ ships a built-in MCP server that exposes Xcode's project, build, test, simulator, and SwiftUI preview capabilities to external agents via `xcrun mcpbridge` (the binary lives in the active developer directory — run `xcrun --find mcpbridge` to see which, since it follows `xcode-select` and is often a beta install rather than `/Applications/Xcode.app`). No third-party server needed.

### One-time setup

1. **Enable the server in Xcode:** `Xcode → Settings → Intelligence → Model Context Protocol → toggle "Xcode Tools" on`.
2. **Register the server with Claude Code** (run once on the machine):
   ```bash
   claude mcp add --transport stdio xcode -- xcrun mcpbridge
   ```
   Use `-s user` to make it available in every project, or `-s local` to scope to this repo only.
3. **Verify:** `claude mcp list` should show `xcode` as connected.
4. **Restart Claude Code** after the first install so the tools are surfaced.

### Using it

**Read [`.claude/skills/xcode-mcp/SKILL.md`](.claude/skills/xcode-mcp/SKILL.md) before the first Xcode tool call of a session, and follow it.** It is the authoritative guide: targeting the open workspace (every call takes the `workspaceIdentifier` from `XcodeListWorkspaces`), what to do when the bridge loses Xcode, why a green `BuildProject` can mean nothing, run destinations for tests, previews, simulator interaction, string-catalog edits, and where Xcode's own skills live. Like the collaboration skill, it is not duplicated here, so the two cannot drift apart.

Xcode must be running with the project open; `mcpbridge` talks to the live Xcode process.
