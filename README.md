# remn

remn is a focused, free and open-source flashcard app for iPhone, iPad and Mac. It does one thing:

> create knowledge → review knowledge → remember knowledge

There is no account, subscription, advertising, analytics, tracking, or backend. Study data lives in a local SwiftData store and syncs between your devices through your own private iCloud database; remn itself never talks to any server.

## Requirements

- Xcode 26 or newer
- iOS 18 or newer, macOS 15 or newer
- Swift 6

## Build

1. Open `remn.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve the pinned dependencies.
3. Select the `remn` scheme and an iOS 18+ iPhone or iPad, or My Mac.
4. Build and run.

remn is one multiplatform target: the same SwiftUI code runs natively on iOS and macOS.

The project file is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen). The checked-in project is ready to open; regenerating it is optional.

From the command line:

```sh
xcodegen generate
xcodebuild -project remn.xcodeproj -scheme remn \
  -destination 'platform=iOS Simulator,name=<installed iPhone>' test
```

## Sync

Cards, decks, subjects, review history and study sessions sync through CloudKit via SwiftData. The schema is versioned: `RemnSchemaV1` is the original local-only schema, kept frozen so existing libraries migrate, and `RemnSchemaV2` is the CloudKit-compatible one (no unique constraints, defaults everywhere, optional relationships). Sync follows the system iCloud settings for the app.

## Scheduling

remn uses FSRS-6 through the Open Spaced Repetition project's `swift-fsrs` package. It intentionally uses the canonical FSRS-6 default parameter vector, 90% desired retention, a 100-year maximum interval, 1-minute and 10-minute learning steps, and a 10-minute relearning step.

Every rating creates a persistent review log. The log stores the full schedule before and after the review so Undo can restore state exactly and future optimizers can use the complete history. Changing desired retention affects subsequent schedules without rewriting history.

## Card syntax

Cards are stored as plain Markdown. Supported content includes:

- paragraphs, headings, emphasis, and lists
- inline code and fenced code blocks with syntax highlighting
- inline math: `$x^2 + y^2 = z^2$`
- display math:

  ```text
  $$
  \nabla_\theta \mathcal{L}(\theta)
  $$
  ```

- fenced code:

  ````text
  ```swift
  actor Cache {
      private var values: [String: Data] = [:]
  }
  ```
  ````

Rendering is native SwiftUI via Textual. The editor keeps Markdown as the source of truth and includes insertion controls for the most useful syntax.

## Backups

Settings → Data can export and import a portable JSON backup. The current schema identifier is `remn-backup-v1`.

A backup preserves subjects, decks, Markdown source, complete FSRS scheduling state, immutable review logs, desired retention, and appearance. Import validates the entire archive before changing the store, then merges objects by UUID. Invalid archives leave the existing library untouched.

Card detail can also render a dedicated high-resolution card layout and save it to Photos.

## Privacy

remn has no remote data layer of its own. The card library is mirrored to the signed-in user's private CloudKit database (container `iCloud.com.chemical-pink.remn`), which only that user can read; without an iCloud account everything stays on the device. Content otherwise leaves the device only when the user explicitly exports a backup or saves a card image.

## License

remn is available under the [MIT License](LICENSE). Dependency acknowledgements are in [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md).

