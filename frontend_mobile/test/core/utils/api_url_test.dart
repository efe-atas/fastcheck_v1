import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/core/constants/dev_server_override.dart';
import 'package:frontend_mobile/core/utils/api_url.dart';

void main() {
  tearDown(() {
    DevServerOverride.debugOverride(reset: true);
  });

  test('remaps localhost file urls to dev machine host', () {
    DevServerOverride.debugOverride(
      useGeneratedHost: true,
      generatedHost: '192.168.1.42',
      useDartDefineHost: false,
    );

    final resolved = resolveApiUrl('http://localhost:8080/files/exam-1.jpg');

    expect(resolved, 'http://192.168.1.42:8080/files/exam-1.jpg');
  });

  test('keeps non-loopback absolute urls unchanged', () {
    DevServerOverride.debugOverride(
      useGeneratedHost: true,
      generatedHost: '192.168.1.42',
      useDartDefineHost: false,
    );

    const original = 'https://cdn.fastcheck.app/files/exam-1.jpg';

    expect(resolveApiUrl(original), original);
  });
}
