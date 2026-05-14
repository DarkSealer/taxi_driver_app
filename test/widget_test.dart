import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Material shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Taxi rider'),
          ),
        ),
      ),
    );

    expect(find.text('Taxi rider'), findsOneWidget);
  });
}
