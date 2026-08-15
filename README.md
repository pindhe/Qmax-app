# QMAX Tools

Professional Flutter e-commerce app for **QMAX Tools**, a hardware and construction materials store in Hargeisa, Somaliland.

The UI is complete and runs against **mock/local data**. Switch `USE_MOCK_DATA=false` and set `API_BASE_URL` in `.env` when the Laravel API is ready. No API secrets are hardcoded.

## Stack

- Flutter + Dart + Material 3
- Riverpod
- Dio (Laravel REST-ready)
- Secure storage for JWT
- Hive + SharedPreferences
- Localization: English, Somali, Arabic
- Light / Dark / System themes

## Run

```bash
flutter pub get
flutter run
```

Demo login: any Somaliland phone (e.g. `0634142010`) or `mohamed@qmaxtools.com` with a password of 8+ characters including a letter and number (`Password1`). Forgot-password OTP is `123456`. Coupon: `QMAX10`.

## Architecture

`lib/core` theme, routing, network  
`lib/domain` entities and repository contracts  
`lib/data` models, mock catalog, repository implementations  
`lib/presentation` screens, widgets, Riverpod providers  
`lib/services` API, storage, notifications  

MySQL schema for the future backend: `backend/mysql_schema.sql`.
