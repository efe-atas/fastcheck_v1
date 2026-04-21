# frontend_mobile

Flutter client for the Fastcheck education platform.

## Local backend access from iOS devices

The committed iOS release configuration is App Store safe and expects HTTPS
traffic to the public API. Physical-device LAN debugging against a local
`http://` backend is no longer enabled by default in `Info.plist`.

If you temporarily need local-device debugging against your Mac, add the
required ATS/local-network exceptions only in a local, uncommitted debug setup.
The workflow for that temporary setup is:

1. Keep the backend server listening on `0.0.0.0:8081` and allow incoming
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

Use the LAN IP flow only in a local debug-only setup for **physical** devices.

### Production / TestFlight builds

Release builds use the public API base URL `https://api.efeatas.dev/api` by
default.
