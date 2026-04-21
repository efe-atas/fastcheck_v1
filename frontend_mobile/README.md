# frontend_mobile

Flutter client for the Fastcheck education platform.

## API base URL

All Flutter builds use the public API base URL `https://api.efeatas.dev/api`
by default, including debug runs on simulators, emulators, and physical
devices.

If you need to point the app to a different environment temporarily, override
the base URL explicitly:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api-host/api
```
