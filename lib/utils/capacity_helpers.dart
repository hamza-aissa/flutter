import 'package:flutter/material.dart';

/// Enum representing the capacity level of a waiting room based on client count.
enum RoomCapacityLevel {
  /// 0-5 clients - Low occupancy
  light,
  /// 6-10 clients - Medium occupancy
  moderate,
  /// 11+ clients - High occupancy
  busy,
}

/// Determines the capacity level based on client count.
/// 
/// Thresholds:
/// - 0-5 → Light (green)
/// - 6-10 → Moderate (orange)
/// - 11+ → Busy (red)
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
/// 
/// Colors:
/// - Light → Green
/// - Moderate → Orange
/// - Busy → Red
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

/// Returns the icon associated with the capacity level.
IconData capacityIcon(RoomCapacityLevel level) {
  switch (level) {
    case RoomCapacityLevel.light:
      return Icons.check_circle;
    case RoomCapacityLevel.moderate:
      return Icons.warning_amber;
    case RoomCapacityLevel.busy:
      return Icons.error;
  }
}
