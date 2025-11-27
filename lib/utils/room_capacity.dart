import 'package:flutter/material.dart';

/// Enum representing the capacity level of a waiting room.
enum RoomCapacityLevel {
  light,    // 0-5 clients
  moderate, // 6-10 clients
  busy,     // 11+ clients
}

/// Determines the capacity level based on the number of clients.
///
/// Thresholds:
/// - 0-5: Light (green)
/// - 6-10: Moderate (orange)
/// - 11+: Busy (red)
RoomCapacityLevel capacityForCount(int count) {
  if (count <= 5) {
    return RoomCapacityLevel.light;
  } else if (count <= 10) {
    return RoomCapacityLevel.moderate;
  } else {
    return RoomCapacityLevel.busy;
  }
}

/// Returns a human-readable label for the capacity level.
String capacityLabel(RoomCapacityLevel level) {
  switch (level) {
    case RoomCapacityLevel.light:
      return 'Light';
    case RoomCapacityLevel.moderate:
      return 'Moderate';
    case RoomCapacityLevel.busy:
      return 'Busy';
  }
}

/// Returns the color associated with the capacity level.
Color capacityColor(RoomCapacityLevel level) {
  switch (level) {
    case RoomCapacityLevel.light:
      return Colors.green;
    case RoomCapacityLevel.moderate:
      return Colors.orange;
    case RoomCapacityLevel.busy:
      return Colors.red;
  }
}
