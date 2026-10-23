# MarketSquare / CSWG Ordering — Flutter

Flutter port of the native Kotlin/Jetpack Compose **CSWG Ordering** (MS Ordering)
handheld store-ordering app, targeting **Android + iOS** from one codebase.

- **Bundle id / applicationId:** `com.ms.marketsquare`
- **Stack:** Flutter (Dart), Riverpod (state), go_router (navigation), Dio (HTTP),
  sqflite (local DB), shared_preferences, firebase_messaging + flutter_local_notifications (push).

---

## Project structure

```
lib/
├─ main.dart            Entry point (runApp)
├─ app.dart             Root widget: MaterialApp.router + theme
├─ core/                Shared basics: constants, theme, device_meta, network/
├─ data/                Data layer
│   ├─ models/          Request/response data classes
│   ├─ repository/      Backend calls (LoginRepository, ApiClient…)
│   ├─ session/         SessionManager (SharedPreferences) + Riverpod providers
│   └─ db/              sqflite local database
├─ features/            One folder per screen/area (screen + controller)
│   ├─ login/ dashboard/ datasync/ refreshdata/ tos/ repflow/ …
├─ router/              app_routes.dart (paths) + app_router.dart (wiring)
└─ widgets/             Reusable UI (BrandLogo, NetworkStatusAction…)
android/   Android host (Gradle, MainActivity.kt, res/)
ios/       iOS host (Xcode project, Runner, Podfile)
```

The same `lib/` runs on both platforms; `android/` and `ios/` are only the native hosts.

---

## Build & run

### Android (works on Windows/macOS/Linux)
```bash
flutter pub get
flutter run                         # debug on a connected device (hot reload)
flutter build apk --release         # -> build/app/outputs/flutter-apk/app-release.apk
```

### iOS
iOS **cannot be built on Windows** — Apple requires macOS + Xcode. Use either a Mac
(`flutter build ipa`) or **Codemagic** cloud CI (below). A physical iPhone can only
install a *signed* build via **TestFlight**, which needs a paid Apple Developer account.

---

## iOS via Codemagic → TestFlight

CI config lives in [`codemagic.yaml`](codemagic.yaml) (workflows: `ios-testflight`, `android-apk`).

### Prerequisites (one-time)
1. **Apple Developer Program** — $99/yr, enroll at <https://developer.apple.com/programs>
   (activation can take 24–48h). Required for signing + TestFlight.
2. **GitHub** repo (this one).
3. **Codemagic** account — <https://codemagic.io>, sign in with GitHub.

### Setup steps
1. **Connect the repo** in Codemagic (it auto-detects `codemagic.yaml`).
2. **App Store Connect API key:** in App Store Connect → Users and Access → Integrations,
   create a key. You get a `.p8` file + **Key ID** + **Issuer ID**.
3. In Codemagic → **Teams → Integrations → Apple Developer Portal**, add that API key and
   give the integration a **name**. Put the same name in `codemagic.yaml` under
   `integrations.app_store_connect` (replace `CodemagicAppStoreKey`).
4. **Create the app record** in App Store Connect with bundle id `com.ms.marketsquare`.
5. Run the **`ios-testflight`** workflow. It builds, signs automatically, and uploads to TestFlight.
6. On your **iPhone**: install the **TestFlight** app → accept the invite → Install → validate.

### iOS push / Firebase (optional, add later)
- In the Firebase console add an **iOS app** with bundle id `com.ms.marketsquare`,
  download **`GoogleService-Info.plist`** into `ios/Runner/`.
- Create an **APNs key** and upload it to Firebase.
- The app builds and runs without this (push code is defensive and no-ops if unconfigured).

---

## Environment notes
- **Release build disables R8/shrinking** (`android/app/build.gradle.kts`): R8 was stripping
  `shared_preferences`' generated methods → white screen. Re-enable later with proper keep rules.
- Local Gradle/Java downloads on the dev machine need `-Djava.net.preferIPv4Stack=true`
  (broken IPv6). Not needed on Codemagic.
- Release APK is currently **debug-keystore-signed** (installs for validation, not Play-ready).

## Known follow-ups
- iOS Firebase `GoogleService-Info.plist` + APNs (push on iOS).
- Refresh Data: **AD PROMO ITEM FILE** block + live **IMAGES IN STORE** count (need the
  image-download endpoint wired; currently show `—`).
- Production-signed release with proper R8 keep rules.
