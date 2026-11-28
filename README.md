# Contrarreloj for iOS

Native iPhone and iPad app of [Contrarreloj](https://contrarreloj-quiz.com), the timed Spanish quiz
game. It has the same rules, questions and ranking as the web (repository `gonzaga8200/quiz-game`)
and uses the same Firebase project (`contrarreloj-quiz`). The app UI and all content are in Spanish.

Swift 6 and SwiftUI only: no web views, no cross-platform frameworks. Design:
[`docs/superpowers/specs`](docs/superpowers/specs); plan:
[`docs/superpowers/plans`](docs/superpowers/plans); App Store texts: [`docs/app-store`](docs/app-store).

## Requirements

- Xcode 26 or newer (iOS 26 SDK); the app runs on iOS 17 and later, iPhone and iPad.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) **2.49.0**, the version in `.xcodegen-version`
  (`brew install xcodegen`, or its GitHub release), to regenerate the project after editing
  `project.yml` or adding files. The generated `Contrarreloj.xcodeproj` is committed, and CI checks
  it is up to date with that same version.
- Only for the parity fixtures and emulator tests: a checkout of the web repository next to this
  one (`../quiz-game`, with `npm install`), the Firebase CLI and Java 21.

## Getting started

```bash
scripts/generate.sh             # after editing project.yml or adding files
open Contrarreloj.xcodeproj     # or use the scripts below
```

Without Firebase configuration the app still runs: arcade mode with the questions bundled in the
app, and no competitive mode or ranking (like the web without its environment variables).

## Firebase

The app uses the same Firebase project as the web. Its configuration is **not** in the repository:

1. In the Firebase console of `contrarreloj-quiz` › Project settings › Your apps, open the iOS app
   "Contrarreloj iOS" (bundle ID `com.contrarrelojquiz.app`) and download `GoogleService-Info.plist`
   (or run `firebase apps:sdkconfig IOS <app id> --project contrarreloj-quiz > Config/GoogleService-Info.plist`).
2. Put it at `Config/GoogleService-Info.plist`. A build phase copies it into the app when it exists.
3. Run `scripts/make-secrets.sh`: it writes `Config/Secrets.xcconfig` with the reversed client ID
   that Google sign-in needs as a URL scheme.

Both files are git-ignored; `Config/*.example.*` show their shape. The API key in the plist is not a
secret in the strict sense (it identifies the project, like the web's), but it stays out of the
public repository anyway; what protects the data are the Firestore security rules, which live in
the web repository and are shared by both apps.

**Sign in with Apple** needs the Apple Developer Program (paid). With a free team, set
`ENABLE_APPLE_SIGN_IN = NO` in `Config/Secrets.xcconfig` to build for a device without that
capability; the simulator works either way. To revoke Apple tokens when an account is deleted, fill
"OAuth code flow configuration" of the Apple provider in Firebase Authentication.

## Architecture

```
Packages/ContrarrelojCore   rules of the game, ported 1:1 from the web's core/ (no UI, no Firebase)
App/Support                 formatting, sharing, mail, sounds, haptics, launch options
App/Design                  colours, fonts, buttons, the pocket watch
App/Data                    question bank (Firestore → 24 h cache → bundled copy), ranking,
                            auth (Apple, Google, account deletion), analytics, local preferences
App/Features                one folder per screen: Home, Setup, Play, Game, Report, Ranking,
                            Categories, Settings, SignIn, Consent
App/Content                 texts generated from the web (category pages) and legal texts
Tools                       parity fixtures, question and copy sync, icon rendering
```

- **Same logic as the web.** `ContrarrelojCore` is a direct port of the web's `core/` (random
  generator, question selection, scoring, combos, report, showcase). `Tools/parity` runs the web's
  TypeScript and writes JSON fixtures; the Swift tests must reproduce them exactly.
- **Same data.** Questions come from Firestore (`questions` where `status == "active"`), are cached
  for 24 hours and fall back to `App/Resources/questions.json` (`Tools/sync-questions.sh` refreshes
  it from the web repository). The ranking is `rankings/{board}/entries/{uid}`, one entry per player
  and board, written with the same fields and checks the rules expect.
- **Privacy.** Analytics (Firebase Analytics, linked to the web's Google Analytics property) is off
  until the player accepts it; there is no IDFA and no tracking (`App/Resources/PrivacyInfo.xcprivacy`).
- **Concurrency.** Swift 6 language mode with complete checking, main-actor default isolation and
  warnings as errors. Values that SwiftUI may compare off the main thread are `nonisolated`.

## Tests

| Script | What it does |
| --- | --- |
| `scripts/test-core.sh` | `ContrarrelojCore` tests on the Mac: rules and exact parity with the web |
| `scripts/test-app.sh [tests…]` | App unit tests on the iPhone simulator (data, auth, analytics, game session, texts, privacy manifest) |
| `scripts/test-ui.sh iphone\|ipad [tests…]` | UI tests of the main flows, with fakes (no network) |
| `scripts/test-integration.sh` | Ranking writes, rules and account deletion against the Firebase emulators running the web's security rules (`scripts/emulators.sh` starts them) |
| `scripts/cross-check-web.sh` | The web from `origin/main`, on the same emulators, to check it shows what the iOS app wrote |

UI tests launch the app with `-uiTesting` and fakes for the question bank, the ranking, sign-in and
mail (see `App/Support/LaunchOptions.swift`). Pass test names as `Target/Suite[/test]`.

A few checks run only on demand, against the real services: `ProductionBankCheck` (the production
question bank read through the app's code, `TEST_RUNNER_PRODUCTION_BANK_CHECK=<output.json>`) and
`LiveAnalyticsCheck` (a real game with Firebase Analytics in debug mode, `TEST_RUNNER_ANALYTICS_CHECK=1`).
Results and the parity table with the web: [`docs/verification/parity.md`](docs/verification/parity.md).

## Other scripts

| Script | What it does |
| --- | --- |
| `scripts/generate.sh` | Regenerate the Xcode project from `project.yml` |
| `scripts/make-secrets.sh` | Write `Config/Secrets.xcconfig` from the Firebase plist |
| `Tools/parity/run.sh` | Regenerate the parity fixtures from the web's core |
| `Tools/sync-questions.sh` | Refresh the bundled questions from the web repository |
| `Tools/sync-category-copy.sh` | Regenerate the category page texts from the web |
| `Tools/render-icon.sh` | Render the app icon (light, dark, tinted) from the in-app pocket watch |
| `scripts/screenshots.sh [iphone\|ipad]` | Screenshots of every flow, light and dark, plus the largest text size (`docs/verification/screenshots`) |

The scripts use Xcode through `DEVELOPER_DIR`, so `xcode-select` may keep pointing at the Command
Line Tools.

## License

Copyright (c) 2026 Gonzalo Moreno Minguito. All rights reserved: see [LICENSE](LICENSE).
