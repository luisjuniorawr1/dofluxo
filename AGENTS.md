# AGENTS.md

## Cursor Cloud specific instructions

### What this is
DOFLUXO (brand "Pequi Agência") is a **single product**: a Flutter **Web** app for creative-agency
workflow management, backed by **live cloud Firebase** (Auth + Cloud Firestore, project
`dofluxo-organizer`). There is no custom backend server in this repo. Docs: `PROJECT_CONTEXT.md`,
`TECHNICAL_DOC.md`, `NEXT_STEPS.md`.

### Toolchain (already provisioned in the VM snapshot)
- Flutter SDK lives at `~/flutter` (`~/flutter/bin` is on `PATH` via `~/.bashrc`). Version: Flutter
  3.44.7 / Dart 3.12.2 (satisfies `pubspec.yaml` `sdk: ^3.10.0`).
- Node/npm are preinstalled; `node_modules/` is committed. `npm` deps are only the `firebase-tools`
  CLI (deploy + Firestore emulator), not needed to run the app itself.

### Standard commands (see `PROJECT_CONTEXT.md` for more)
- Deps: `flutter pub get`
- Lint: `flutter analyze`
- Test: `flutter test` (46 Dart unit/widget tests; no Firebase needed — integration is mocked/absent)
- Run (dev): `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0` (or `-d chrome`)

### Non-obvious caveats
- **`flutter analyze` prints `error`-level issues from `node_modules/firebase-tools/templates/init/functions/dart/server.dart`.**
  Those are the npm package's template files, NOT project code, and appear only because `node_modules/`
  sits in the Flutter project root. Real `lib/`+`test/` code is clean (only `info`/`warning`). Ignore
  the `node_modules` errors when judging lint.
- **The app always talks to LIVE cloud Firebase** — there is no emulator wiring in Dart code
  (no `useFirestoreEmulator`/`useAuthEmulator`). It needs outbound network to Google/Firebase
  endpoints (`identitytoolkit.googleapis.com`, `firestore.googleapis.com`, `accounts.google.com`).
- **Login is Google OAuth via `signInWithPopup` (Web only).** There is no username/password auth, so
  authenticated flows (create/edit projects, clients, agencies) require an **interactive real Google
  account**. Without one, testing stops at the Google sign-in page (which correctly loads
  "to continue to dofluxo-organizer.firebaseapp.com"). To exercise authenticated flows, log in through
  the Desktop pane with a Google account that has access to the `dofluxo-organizer` project. Firebase
  Auth auto-authorizes `localhost`, so serving on `localhost:8080` works for the popup.
- The Firestore security-rules test is a **Node** test run against the Firestore emulator, not
  `flutter test`: `npx firebase emulators:exec --only firestore "node test/firestore_rules_test.mjs"`.
- Android/iOS/Windows/macOS are not fully configured (mobile auth unimplemented; no Windows
  `firebase_options`). Target the **Web** device.
