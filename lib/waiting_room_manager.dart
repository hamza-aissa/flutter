// lib/waiting_room_manager.dart
class WaitingRoomManager {
  final List<String> _clients = [];
  List<String> get clients => _clients;
  void addClient(String name) {
    _clients.add(name);
  }
}
