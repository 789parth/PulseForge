import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulseforge/app.dart';

void main() {
  testWidgets('PulseForge app smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PulseForgeApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(PulseForgeApp), findsOneWidget);
  });
}
