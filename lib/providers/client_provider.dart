import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/client.dart';
import '../models/waiting_room.dart';
import '../models/waiting_room_timestamp.dart';
import '../services/sqlite_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'dart:math';

class ClientProvider with ChangeNotifier {
  final SQLiteService _sqliteService = SQLiteService();
  final SupabaseService _supabaseService = SupabaseService();
  final SyncService _syncService = SyncService();

  List<Client> _clients = [];
  List<WaitingRoom> _waitingRooms = [];
  bool _isLoading = false;
  bool _isOnline = false;

  List<Client> get clients => _clients;
  List<WaitingRoom> get waitingRooms => _waitingRooms;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  ClientProvider() {
    _init();
  }

  Future<void> _init() async {
    print('🚀 Initialisation ClientProvider...');
    
    // Étape 1: Charger depuis SQLite
    await loadWaitingRooms();
    print('📍 Étape 1: ${_waitingRooms.length} salles chargées depuis SQLite');
    
    // Étape 2: Si vide, essayer de synchroniser depuis Supabase
    if (_waitingRooms.isEmpty) {
      print('⚠️ Aucune salle locale, tentative de sync Supabase...');
      try {
        await _syncService.syncWaitingRooms();
        await loadWaitingRooms();
        print('✅ ${_waitingRooms.length} salles synchronisées depuis Supabase');
      } catch (e) {
        print('❌ Erreur sync Supabase: $e');
      }
    }
    
    // Étape 3: Si ENCORE vide, créer des salles par défaut
    if (_waitingRooms.isEmpty) {
      print('🔧 Création de salles par défaut...');
      await _createDefaultWaitingRooms();
      await loadWaitingRooms();
      print('✅ ${_waitingRooms.length} salles créées par défaut');
    }
    
    // Étape 4: Charger les clients
    await loadClients();
    print('👥 ${_clients.length} clients chargés');
    
    // Étape 5: Monitorer connectivité
    _monitorConnectivity();
    print('🌐 Monitoring de connectivité activé');
  }

  // NOUVELLE MÉTHODE: Créer des salles par défaut
  Future<void> _createDefaultWaitingRooms() async {
    final defaultRooms = [
      WaitingRoom(
        id: '550e8400-e29b-41d4-a716-446655440001',
        name: 'Salle A - Centre-ville',
        latitude: 48.8566,
        longitude: 2.3522,
      ),
      WaitingRoom(
        id: '550e8400-e29b-41d4-a716-446655440002',
        name: 'Salle B - Nord',
        latitude: 48.8700,
        longitude: 2.3800,
      ),
      WaitingRoom(
        id: '550e8400-e29b-41d4-a716-446655440003',
        name: 'Salle C - Sud',
        latitude: 48.8400,
        longitude: 2.3200,
      ),
    ];

    // Sauvegarder localement d'abord
    for (var room in defaultRooms) {
      await _sqliteService.insertWaitingRoom(room);
      print('💾 Salle créée: ${room.name}');
    }

    // Si online, essayer de les envoyer vers Supabase
    if (await _syncService.isOnline()) {
      try {
        for (var room in defaultRooms) {
          await _supabaseService.addWaitingRoom(room);
        }
        print('☁️ Salles synchronisées avec Supabase');
      } catch (e) {
        print('⚠️ Impossible de synchroniser avec Supabase: $e');
      }
    }
  }

  // Surveiller la connectivité
  void _monitorConnectivity() {
    _syncService.connectivityStream.listen((online) async {
      _isOnline = online;
      notifyListeners();

      if (online) {
        print('🌐 Connexion rétablie, synchronisation...');
        await synchronize();
      }
    });

    // Vérifier l'état initial
    _syncService.isOnline().then((online) {
      _isOnline = online;
      notifyListeners();
    });
  }

  // Charger les clients depuis SQLite
  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _sqliteService.getClients();
    } catch (e) {
      print('❌ Erreur chargement clients: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Charger les waiting rooms depuis SQLite
  Future<void> loadWaitingRooms() async {
    try {
      _waitingRooms = await _sqliteService.getWaitingRooms();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur chargement waiting rooms: $e');
    }
  }

  // Ajouter un client
  Future<void> addClient(String name, Position position) async {
    try {
      // DEBUG: Afficher le nombre de salles
      print('🔍 Nombre de waiting_rooms disponibles: ${_waitingRooms.length}');
      
      // Trouver la waiting room la plus proche
      final closestRoom = _findClosestWaitingRoom(
        position.latitude,
        position.longitude,
      );

      if (closestRoom == null) {
        throw Exception('Aucune salle d\'attente disponible');
      }

      print('📍 Salle la plus proche: ${closestRoom.name}');

      final client = Client(
        id: Client.generateId(),
        name: name,
        createdAt: WaitingRoomTimestamp.now(),
        lng: position.longitude,
        lat: position.latitude,
        waitingRoomId: closestRoom.id,
      );

      // Enregistrer en local
      await _sqliteService.insertClient(client);
      print('💾 Client sauvegardé localement: ${client.name}');

      // Enregistrer sur Supabase si online
      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.addClient(client);
          print('☁️ Client synchronisé avec Supabase: ${client.name}');
        } catch (e) {
          print('⚠️ Impossible d\'ajouter sur Supabase: $e');
        }
      }

      await loadClients();
    } catch (e) {
      print('❌ Erreur ajout client: $e');
      rethrow;
    }
  }

  // Modifier un client
  Future<void> updateClient(Client client) async {
    try {
      await _sqliteService.updateClient(client);

      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.updateClient(client);
        } catch (e) {
          print('⚠️ Impossible de modifier sur Supabase: $e');
        }
      }

      await loadClients();
    } catch (e) {
      print('❌ Erreur modification client: $e');
      rethrow;
    }
  }

  // Supprimer un client
  Future<void> deleteClient(String id) async {
    try {
      await _sqliteService.deleteClient(id);

      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.deleteClient(id);
        } catch (e) {
          print('⚠️ Impossible de supprimer sur Supabase: $e');
        }
      }

      await loadClients();
    } catch (e) {
      print('❌ Erreur suppression client: $e');
      rethrow;
    }
  }

  // Synchroniser
  Future<List<String>> synchronize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final syncedIds = await _syncService.fullSync();
      await loadClients();
      await loadWaitingRooms();

      _isLoading = false;
      notifyListeners();

      return syncedIds;
    } catch (e) {
      print('❌ Erreur synchronisation: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Trouver la waiting room la plus proche (Haversine)
  WaitingRoom? _findClosestWaitingRoom(double lat, double lng) {
    if (_waitingRooms.isEmpty) {
      print('⚠️ _findClosestWaitingRoom: Liste vide!');
      return null;
    }

    WaitingRoom? closest;
    double minDistance = double.infinity;

    for (var room in _waitingRooms) {
      final distance = _calculateDistance(lat, lng, room.latitude, room.longitude);
      print('📏 Distance vers ${room.name}: ${distance.toStringAsFixed(2)} km');
      
      if (distance < minDistance) {
        minDistance = distance;
        closest = room;
      }
    }

    return closest;
  }

  // Calcul de distance Haversine (en kilomètres)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Récupérer une waiting room par ID
  Future<WaitingRoom?> getWaitingRoomById(String id) async {
    return await _sqliteService.getWaitingRoomById(id);
  }
}
