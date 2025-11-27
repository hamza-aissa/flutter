import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/utils/capacity_helpers.dart';

void main() {
  group('capacityForCount', () {
    test('should return light for counts 0-5', () {
      expect(capacityForCount(0), RoomCapacityLevel.light);
      expect(capacityForCount(1), RoomCapacityLevel.light);
      expect(capacityForCount(5), RoomCapacityLevel.light);
    });

    test('should return moderate for counts 6-10', () {
      expect(capacityForCount(6), RoomCapacityLevel.moderate);
      expect(capacityForCount(8), RoomCapacityLevel.moderate);
      expect(capacityForCount(10), RoomCapacityLevel.moderate);
    });

    test('should return busy for counts 11+', () {
      expect(capacityForCount(11), RoomCapacityLevel.busy);
      expect(capacityForCount(50), RoomCapacityLevel.busy);
      expect(capacityForCount(100), RoomCapacityLevel.busy);
    });
  });

  group('capacityLabel', () {
    test('should return correct labels for each level', () {
      expect(capacityLabel(RoomCapacityLevel.light), 'Light');
      expect(capacityLabel(RoomCapacityLevel.moderate), 'Moderate');
      expect(capacityLabel(RoomCapacityLevel.busy), 'Busy');
    });
  });

  group('capacityColor', () {
    test('should return green for light', () {
      expect(capacityColor(RoomCapacityLevel.light), Colors.green);
    });

    test('should return orange for moderate', () {
      expect(capacityColor(RoomCapacityLevel.moderate), Colors.orange);
    });

    test('should return red for busy', () {
      expect(capacityColor(RoomCapacityLevel.busy), Colors.red);
    });
  });

  group('capacityIcon', () {
    test('should return check_circle for light', () {
      expect(capacityIcon(RoomCapacityLevel.light), Icons.check_circle);
    });

    test('should return warning_amber for moderate', () {
      expect(capacityIcon(RoomCapacityLevel.moderate), Icons.warning_amber);
    });

    test('should return error for busy', () {
      expect(capacityIcon(RoomCapacityLevel.busy), Icons.error);
    });
  });
}
