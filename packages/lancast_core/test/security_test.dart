import 'package:lancast_core/lancast_core.dart';
import 'package:test/test.dart';

void main() {
  test('hashPin is stable and verifies', () {
    final hash = hashPin('839201');
    expect(verifyPin(pin: '839201', pinHash: hash), isTrue);
    expect(verifyPin(pin: '000000', pinHash: hash), isFalse);
  });

  test('redactToken hides secrets', () {
    expect(redactToken('abcdefghijklmnop'), isNot(contains('efghijklmn')));
    expect(redactToken('abcdefghijklmnop'), startsWith('abcd'));
  });
}
