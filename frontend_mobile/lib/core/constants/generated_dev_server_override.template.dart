/// Template fallback for the dev machine IP override.
///
/// The `tool/update_dev_machine_ip.dart` script copies/updates this content into
/// `generated_dev_server_override.dart`, which is ignored by git. Keeping this
/// template in the repo ensures first-time setups can still compile until the
/// script runs and detects the actual LAN IP.
const String generatedDevMachineIp = '127.0.0.1';
const String generatedDevMachineIpSource = 'template';
const String generatedDevMachineIpGeneratedAt = 'never';
