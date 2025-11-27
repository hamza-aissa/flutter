<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'dart:async'; // Required for the Timer class

class WaitingRoomTimestamp extends StatefulWidget {
  const WaitingRoomTimestamp({super.key});
  @override
  State<WaitingRoomTimestamp> createState() => _WaitingRoomTimestampState();
}

class _WaitingRoomTimestampState extends State<WaitingRoomTimestamp> {
  // A variable to hold the current time
  late DateTime _currentTime;
  // A timer to update the time periodically
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    // Initialize the current time when the widget is created
    _currentTime = DateTime.now();

    // Set up a periodic timer to update the state every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Use setState to rebuild the widget with the new time
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    // This is crucial! Cancel the timer when the widget is removed from the tree
    // to prevent memory leaks and unnecessary processing.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the date and time to a readable string
    final formattedTime = _currentTime.toString().split('.')[0];
    return Text(
      'Current Time: $formattedTime',
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
=======
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waiting_room_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
>>>>>>> workshop6
}
