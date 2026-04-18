// Smoke test — just verifies the root app widget boots and renders the
// status strip. Richer integration tests land once the feed repository
// can be mocked without hitting the network.

import 'package:flutter_test/flutter_test.dart';

import 'package:pantaujalan_flutter/main.dart';

void main() {
  testWidgets('App boots and shows the brand title', (WidgetTester tester) async {
    await tester.pumpWidget(const PantauJalanApp());
    // Pump once; feed loading is async, so we don't wait for settle.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PANTAUJALAN'), findsOneWidget);
  });
}
