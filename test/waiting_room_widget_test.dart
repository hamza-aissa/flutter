import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/main.dart';

void main() {
  testWidgets('should add a new client to the list on button tap', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    await tester.pumpWidget(const WaitingRoomApp());
    // ACT
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild the widget after state change
    // ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });
}
