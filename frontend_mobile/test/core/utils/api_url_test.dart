import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/core/utils/api_url.dart';

void main() {
  test('remaps localhost file urls to public api host', () {
    final resolved = resolveApiUrl('http://localhost:8080/files/exam-1.jpg');

    expect(resolved, 'https://api.efeatas.dev/api/files/exam-1.jpg');
  });

  test('keeps non-loopback absolute urls unchanged', () {
    const original = 'https://cdn.fastcheck.app/files/exam-1.jpg';

    expect(resolveApiUrl(original), original);
  });
}
