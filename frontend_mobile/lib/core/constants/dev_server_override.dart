import 'package:flutter/foundation.dart';

import 'generated_dev_server_override.dart';

class DevServerOverride {
  DevServerOverride._();

  static const String _dartDefineHost =
      String.fromEnvironment('DEV_MACHINE_IP', defaultValue: '');
  static const String _fallbackHost = '127.0.0.1';

  static bool _didLog = false;
  static bool? _generatedOverrideEnabled;
  static String? _testGeneratedHost;
  static bool? _dartDefineOverrideEnabled;
  static String? _testDartDefineHost;

  /// Resolves the base URL host that should be used when talking to the local
  /// development backend.
  static String get baseUrlHost {
    final generatedHost = _resolveGeneratedHost();
    final dartDefineHost = _resolveDartDefineHost();

    final host = generatedHost ?? dartDefineHost ?? _fallbackHost;
    final source = generatedHost != null
        ? (generatedDevMachineIpSource.isNotEmpty
            ? generatedDevMachineIpSource
            : 'generated')
        : dartDefineHost != null
            ? 'dart-define'
            : 'fallback';

    _logOnce(host, source);
    return host;
  }

  static String? _resolveGeneratedHost() {
    if (_generatedOverrideEnabled == null) {
      return _normalize(generatedDevMachineIp);
    }
    if (_generatedOverrideEnabled == false) {
      return null;
    }
    return _normalize(_testGeneratedHost);
  }

  static String? _resolveDartDefineHost() {
    if (_dartDefineOverrideEnabled == null) {
      return _normalize(_dartDefineHost.trim());
    }
    if (_dartDefineOverrideEnabled == false) {
      return null;
    }
    return _normalize(_testDartDefineHost);
  }

  static String? _normalize(String? value) {
    if (value == null || value.isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed == '0.0.0.0') {
      return null;
    }
    return trimmed;
  }

  static void _logOnce(String host, String source) {
    if (!kDebugMode || _didLog) return;
    _didLog = true;
    debugPrint('[DevServerOverride] Using $host (source: $source)');
  }

  @visibleForTesting
  static void debugOverride({
    bool reset = false,
    bool? useGeneratedHost,
    String? generatedHost,
    bool? useDartDefineHost,
    String? dartDefineHost,
  }) {
    if (reset) {
      _generatedOverrideEnabled = null;
      _dartDefineOverrideEnabled = null;
      _testGeneratedHost = null;
      _testDartDefineHost = null;
      _didLog = false;
      return;
    }

    if (useGeneratedHost != null) {
      _generatedOverrideEnabled = useGeneratedHost;
    }
    if (generatedHost != null) {
      _testGeneratedHost = generatedHost;
    }
    if (useDartDefineHost != null) {
      _dartDefineOverrideEnabled = useDartDefineHost;
    }
    if (dartDefineHost != null) {
      _testDartDefineHost = dartDefineHost;
    }
    _didLog = false;
  }
}
