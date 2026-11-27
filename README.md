# Contrarreloj for iOS

Native iPhone and iPad app of [Contrarreloj](https://contrarreloj-quiz.com), the timed Spanish quiz
game. It has the same rules, questions and ranking as the web (repository `gonzaga8200/quiz-game`)
and uses the same Firebase project (`contrarreloj-quiz`). The app UI and all content are in Spanish.

- **Status:** under construction. Design: [`docs/superpowers/specs`](docs/superpowers/specs);
  plan: [`docs/superpowers/plans`](docs/superpowers/plans).

## Requirements

- Xcode 26 or newer (iOS 26 SDK); the app runs on iOS 17 and later, iPhone and iPad.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to regenerate the
  project after editing `project.yml`. The generated `Contrarreloj.xcodeproj` is committed.

## Getting started

```bash
scripts/generate.sh             # only after editing project.yml
open Contrarreloj.xcodeproj     # or use the scripts below
```

Without Firebase configuration the app still runs: arcade mode with the questions bundled in the
app, and no competitive mode or ranking (like the web without its environment variables).

## Firebase

`Config/GoogleService-Info.plist` is **not** in the repository. To use the real project, download
the configuration of the iOS app "Contrarreloj iOS" (Firebase console > Project settings > Your
apps, or `firebase apps:sdkconfig IOS <app id> --project contrarreloj-quiz`) into `Config/`, then
run `scripts/make-secrets.sh` to write `Config/Secrets.xcconfig` (the Google sign-in URL scheme).
Both files are git-ignored. See `Config/*.example.*` for their shape.

## Scripts

| Script | What it does |
| --- | --- |
| `scripts/generate.sh` | Regenerate the Xcode project from `project.yml` |
| `scripts/test-core.sh` | Tests of the `ContrarrelojCore` package on the Mac (rules and parity with the web) |
| `scripts/test-app.sh [tests…]` | App unit tests on the iPhone simulator |
| `scripts/test-ui.sh iphone\|ipad [tests…]` | UI tests on a simulator |
| `scripts/make-secrets.sh` | Write `Config/Secrets.xcconfig` from the Firebase plist |

The scripts use Xcode through `DEVELOPER_DIR`, so `xcode-select` may keep pointing at the Command
Line Tools.

## License

Copyright (c) 2026 Gonzalo Moreno Minguito. All rights reserved: see [LICENSE](LICENSE).
