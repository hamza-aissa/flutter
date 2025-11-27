import 'package:geolocator/geolocator.dart';
import '../models/client.dart';
import '../models/waiting_room_timestamp.dart';

class TestDataGenerator {
  // Générer des positions de test
  static List<Map<String, dynamic>> getTestClients() {
    return [
      {
        'name': 'Marie Dubois',
        'position': Position(
          latitude: 48.8570,
          longitude: 2.3525,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      },
      {
        'name': 'Jean Martin',
        'position': Position(
          latitude: 48.8560,
          longitude: 2.3520,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      },
      {
        'name': 'Sophie Lambert',
        'position': Position(
          latitude: 48.8575,
          longitude: 2.3530,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      },
      {
        'name': 'Pierre Rousseau',
        'position': Position(
          latitude: 48.8705,
          longitude: 2.3805,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      },
      {
        'name': 'Lucas Bernard',
        'position': Position(
          latitude: 48.8405,
          longitude: 2.3205,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      },
    ];
  }

  // Générer des clients directement
  static List<Client> generateMockClients(String waitingRoomId) {
    return [
      Client(
        id: Client.generateId(),
        name: 'Thomas Lefebvre',
        createdAt: WaitingRoomTimestamp.now().subtract(const Duration(hours: 3)),
        lng: 2.3525,
        lat: 48.8570,
        waitingRoomId: waitingRoomId,
      ),
      Client(
        id: Client.generateId(),
        name: 'Julie Simon',
        createdAt: WaitingRoomTimestamp.now().subtract(const Duration(hours: 2)),
        lng: 2.3520,
        lat: 48.8560,
        waitingRoomId: waitingRoomId,
      ),
      Client(
        id: Client.generateId(),
        name: 'François-Xavier Müller',
        createdAt: WaitingRoomTimestamp.now().subtract(const Duration(hours: 1)),
        lng: 2.3530,
        lat: 48.8575,
        waitingRoomId: waitingRoomId,
      ),
    ];
  }
}
