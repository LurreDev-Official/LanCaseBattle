import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_viewer/app.dart';

void main() {
  testWidgets('Viewer home shows LanCast Viewer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LancastViewerApp()),
    );
    expect(find.text('LanCast Viewer'), findsOneWidget);
    expect(find.text('Buat Room'), findsOneWidget);
  });
}
