import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_sender/app.dart';

void main() {
  testWidgets('Sender home shows LanCast Sender', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LancastSenderApp()),
    );
    expect(find.text('LanCast Sender'), findsOneWidget);
    expect(find.text('Scan Rooms'), findsOneWidget);
  });
}
