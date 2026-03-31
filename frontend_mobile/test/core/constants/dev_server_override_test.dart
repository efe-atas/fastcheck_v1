import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/core/constants/dev_server_override.dart';

void main() {
  tearDown(() {
    DevServerOverride.debugOverride(
      reset: true,
    );
  });

  test('prefers generated host over dart define and fallback', () {
    DevServerOverride.debugOverride(
      useGeneratedHost: true,
      generatedHost: '192.168.1.42',
      useDartDefineHost: true,
      dartDefineHost: '10.0.0.3',
    );

    expect(DevServerOverride.baseUrlHost, '192.168.1.42');
  });

  test('uses dart define when generated host missing', () {
    DevServerOverride.debugOverride(
      useGeneratedHost: false,
      useDartDefineHost: true,
      dartDefineHost: '10.11.12.13',
    );

    expect(DevServerOverride.baseUrlHost, '10.11.12.13');
  });

  test('falls back to localhost when nothing else provided', () {
    DevServerOverride.debugOverride(
      useGeneratedHost: false,
      useDartDefineHost: false,
    );

    expect(DevServerOverride.baseUrlHost, '127.0.0.1');
  });
}
