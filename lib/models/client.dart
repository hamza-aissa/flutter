import 'package:uuid/uuid.dart';

class Client {
  final String id;
  final String name;
  final DateTime createdAt;
  final double lng;
  final double lat;
  final String waitingRoomId;

  Client({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lng,
    required this.lat,
    required this.waitingRoomId,
  });

  // Constructeur depuis JSON (Supabase)
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      waitingRoomId: json['waiting_room_id'] as String,
    );
  }

  // Conversion vers JSON (pour Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'lng': lng,
      'lat': lat,
      'waiting_room_id': waitingRoomId,
    };
  }

  // Constructeur depuis Map SQLite
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lng: map['lng'] as double,
      lat: map['lat'] as double,
      waitingRoomId: map['waiting_room_id'] as String,
    );
  }

  // Conversion vers Map SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'lng': lng,
      'lat': lat,
      'waiting_room_id': waitingRoomId,
    };
  }

  // Générer un nouvel ID
  static String generateId() {
    return const Uuid().v4();
  }
}
