# Dev Machine IP Utilities

`update_dev_machine_ip.dart` keeps `lib/core/constants/generated_dev_server_override.dart`
in sync with the LAN IPv4 of your Mac so physical iOS devices can call the
backend running on your laptop.

## Usage

```bash
# Detect IP automatically (preferred).
flutter pub run tool/update_dev_machine_ip.dart --platform=ios

# Print what would change without writing files.
flutter pub run tool/update_dev_machine_ip.dart --dry-run

# Override detection when on VPN/Ethernet:
FASTCHECK_DEV_MACHINE_IP=10.0.0.42 \
  flutter pub run tool/update_dev_machine_ip.dart --platform=ios
```

The script writes the generated file only when its contents change, so re-running
it is inexpensive. It also warns when the backend port (`8080`) is unreachable so
you can fix firewall/VPN issues before deploying to a device.
