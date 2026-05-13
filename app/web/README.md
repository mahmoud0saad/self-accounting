# Web assets for Drift (SQLite WASM)

Bundled for **drift 2.20.0** + **sqlite3.dart 2.9.4**:

- `sqlite3.wasm` — from [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases) (`sqlite3-2.9.4/sqlite3.wasm`).
- `drift_worker.js` — from [drift releases](https://github.com/simolus3/drift/releases) (`drift-2.20.0/drift_worker.js`).

To upgrade: match versions in `pubspec.lock`, download the matching pair from those release pages, replace these files, and smoke-test `flutter run -d chrome`.

Optional (faster OPFS path): run with COOP/COEP headers, e.g.  
`flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp`.
