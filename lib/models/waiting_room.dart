import 'package:uuid/uuid.dart';

class WaitingRoom {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  WaitingRoom({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // Constructeur depuis JSON (Supabase)
  factory WaitingRoom.fromJson(Map<String, dynamic> json) {
    return WaitingRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Constructeur depuis Map SQLite
  factory WaitingRoom.fromMap(Map<String, dynamic> map) {
    return WaitingRoom(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }

  // Conversion vers Map SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Générer un nouvel ID
  static String generateId() {
    return const Uuid().v4();
  }
}
