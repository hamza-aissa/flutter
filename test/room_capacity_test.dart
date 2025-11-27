import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waiting_room_app/utils/room_capacity.dart';

void main() {
  group('RoomCapacityLevel', () {
    group('capacityForCount', () {
      test('returns light for count 0', () {
        expect(capacityForCount(0), RoomCapacityLevel.light);
      });

      test('returns light for count 1-5', () {
        expect(capacityForCount(1), RoomCapacityLevel.light);
        expect(capacityForCount(3), RoomCapacityLevel.light);
        expect(capacityForCount(5), RoomCapacityLevel.light);
      });

      test('returns moderate for count 6-10', () {
        expect(capacityForCount(6), RoomCapacityLevel.moderate);
        expect(capacityForCount(8), RoomCapacityLevel.moderate);
        expect(capacityForCount(10), RoomCapacityLevel.moderate);
      });

      test('returns busy for count 11+', () {
        expect(capacityForCount(11), RoomCapacityLevel.busy);
        expect(capacityForCount(15), RoomCapacityLevel.busy);
        expect(capacityForCount(100), RoomCapacityLevel.busy);
      });
    });

    group('capacityLabel', () {
      test('returns correct labels for each level', () {
        expect(capacityLabel(RoomCapacityLevel.light), 'Light');
        expect(capacityLabel(RoomCapacityLevel.moderate), 'Moderate');
        expect(capacityLabel(RoomCapacityLevel.busy), 'Busy');
      });
    });

    group('capacityColor', () {
      test('returns green for light', () {
        expect(capacityColor(RoomCapacityLevel.light), Colors.green);
      });

      test('returns orange for moderate', () {
        expect(capacityColor(RoomCapacityLevel.moderate), Colors.orange);
      });

      test('returns red for busy', () {
        expect(capacityColor(RoomCapacityLevel.busy), Colors.red);
      });
    });
  });
}
