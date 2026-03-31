# frontend_mobile

Flutter client for the Fastcheck education platform.

## Local backend access from iOS devices

Physical iOS builds can now reach the backend running on your Mac without
changing code or remembering `--dart-define` flags. The workflow:

1. Keep the backend server listening on `0.0.0.0:8080` and allow incoming
   connections in macOS Firewall (or disable the firewall while developing).
2. Ensure your Mac **and** iOS device share the same LAN (Wi‑Fi/Ethernet).
3. Run the helper before launching the app:

   ```bash
   make ios-dev-run
   ```

   This target runs `flutter pub run tool/update_dev_machine_ip.dart` to detect
   your LAN IP (or uses `FASTCHECK_DEV_MACHINE_IP` if you export it) and then
   launches `flutter run -d ios`. The generated file is ignored by git, so you
   can re-run this command freely.

### Manual override / advanced usage

- Override detection when on VPNs or unusual interfaces:

  ```bash
  FASTCHECK_DEV_MACHINE_IP=10.10.0.12 \
    flutter pub run tool/update_dev_machine_ip.dart --platform=ios
  ```

- See [tool/README.md](tool/README.md) for more CLI examples.
- Xcode automatically runs the same script via the “Fastcheck | Dev IP” build
  phase, so tapping **Run** already updates the generated file. If the script
  cannot determine an IP it fails fast with an actionable error.

### Simulator & Android

Simulators/emulators keep their previous behavior:

- iOS Simulator → `127.0.0.1`
- Android Emulator → `10.0.2.2`

Use the LAN IP flow only when deploying to **physical** devices.

### Local Network permission

`NSLocalNetworkUsageDescription` explains why the app needs LAN access:
“Uygulama, aynı ağdaki Fastcheck sunucusuna bağlanabilmek için yerel ağ erişimine
ihtiyaç duyar.” Make sure this string matches your localization requirements.
