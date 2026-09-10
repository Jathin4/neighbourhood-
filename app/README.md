# TNN App (Flutter)

Single Flutter codebase for **web + Android + iOS**. State: Riverpod ·
Navigation: go_router · HTTP: dio · Token storage: flutter_secure_storage.

## One-time bootstrap

This repo has `lib/`, `pubspec.yaml` and tests but **no platform folders**
(they are machine-generated). After installing the Flutter SDK:

```bash
cd app
flutter create . --project-name tnn_app --org com.tnn --platforms=web,android,ios
flutter pub get
```

`flutter create .` only adds the missing `web/ android/ ios/ .metadata`
scaffolding — it will not touch the existing `lib/` or tests. If it ever
prompts to overwrite `pubspec.yaml`, decline (or `git checkout -- pubspec.yaml`
after).

## Run against the local backend

```bash
# backend first (see ../backend/README.md), listening on :8000
flutter run -d chrome  --dart-define=API_BASE_URL=http://localhost:8000
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000   # emulator
```

With `OTP_DEBUG=true` on the backend the OTP screen is pre-filled with the
code, so login is one tap.

## Test / lint

```bash
flutter test
flutter analyze
```

## Structure

```
lib/
  main.dart                      ProviderScope + MaterialApp.router
  src/core/
    env.dart                     API_BASE_URL (--dart-define)
    api_client.dart              Dio + bearer + one-shot 401 refresh/retry
    token_store.dart             secure access/refresh persistence
    app_exception.dart           backend {error:{...}} -> presentable error
    router.dart                  go_router with auth redirect + splash
    theme.dart
  src/features/
    auth/        phone -> otp -> tokens; AuthController (signedIn/out/unknown)
    dashboard/   home shell: notices / issues / events placeholders (§2.2)
    community/   GET /communities list
    profile/     GET /users/me, sign out
```

## Next

Wire the Community phase screens (notices, issues, polls/events) to the
backend once those endpoints exist. Add `json_serializable` if the DTO count
grows past a handful (hand-written `fromJson` for now).
