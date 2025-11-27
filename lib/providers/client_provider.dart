import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Map to store client counts per waiting room (roomId -> count)
  final Map<String, int> _roomClientCounts = {};

  // Realtime subscription channel
  RealtimeChannel? _clientsChannel;

  List<Client> get clients => _clients;
  List<WaitingRoom> get waitingRooms => _waitingRooms;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  /// Get the client count for a specific room
  int getClientCountForRoom(String roomId) {
    return _roomClientCounts[roomId] ?? 0;
  }

  /// Get all room client counts
  Map<String, int> get roomClientCounts => Map.unmodifiable(_roomClientCounts);

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

    // Étape 5: Refresh client counts for all rooms
    await _refreshCountsForAllRooms();
    print('📊 Counts initialized for ${_roomClientCounts.length} rooms');
    
    // Étape 6: Monitorer connectivité
    _monitorConnectivity();
    print('🌐 Monitoring de connectivité activé');

    // Étape 7: Setup realtime subscriptions
    _setupRealtimeSubscriptions();
    print('📡 Realtime subscriptions activated');
  }

  /// Refresh client counts for all waiting rooms
  Future<void> _refreshCountsForAllRooms() async {
    for (final room in _waitingRooms) {
      await _fetchCountForRoom(room.id);
    }
    notifyListeners();
  }

  /// Fetch client count for a specific room
  Future<void> _fetchCountForRoom(String roomId) async {
    try {
      // Try to get count from local SQLite first
      final localCount = await _sqliteService.getClientCountByRoomId(roomId);
      _roomClientCounts[roomId] = localCount;

      // If online, also fetch from Supabase to stay in sync
      if (await _syncService.isOnline()) {
        try {
          final remoteCount = await _supabaseService.fetchClientCountByRoomId(roomId);
          _roomClientCounts[roomId] = remoteCount;
        } catch (e) {
          print('⚠️ Could not fetch remote count for room $roomId: $e');
        }
      }
    } catch (e) {
      print('❌ Error fetching count for room $roomId: $e');
      _roomClientCounts[roomId] = 0;
    }
  }

  /// Setup realtime subscriptions for client changes
  void _setupRealtimeSubscriptions() {
    _clientsChannel = _supabaseService.subscribeToClientChanges(
      onInsert: (payload) {
        print('📡 Realtime: Client inserted');
        _handleClientInserted(payload);
      },
      onDelete: (payload) {
        print('📡 Realtime: Client deleted');
        _handleClientDeleted(payload);
      },
      onUpdate: (payload) {
        print('📡 Realtime: Client updated');
        _handleClientUpdated(payload);
      },
    );
  }

  /// Handle realtime client insert event
  void _handleClientInserted(Map<String, dynamic> payload) {
    final roomId = payload['waiting_room_id'] as String?;
    if (roomId != null) {
      _roomClientCounts[roomId] = (_roomClientCounts[roomId] ?? 0) + 1;
      notifyListeners();
    }
    // Also reload clients to get the new client
    loadClients();
  }

  /// Handle realtime client delete event
  void _handleClientDeleted(Map<String, dynamic> payload) {
    final roomId = payload['waiting_room_id'] as String?;
    if (roomId != null && _roomClientCounts.containsKey(roomId)) {
      _roomClientCounts[roomId] = max(0, _roomClientCounts[roomId]! - 1);
      notifyListeners();
    }
    // Also reload clients to reflect the deletion
    loadClients();
  }

  /// Handle realtime client update event
  void _handleClientUpdated(Map<String, dynamic> payload) {
    // Reload clients to reflect the update
    loadClients();
  }

  /// Dispose realtime subscriptions
  Future<void> _disposeSubscriptions() async {
    if (_clientsChannel != null) {
      await _supabaseService.unsubscribeFromChannel(_clientsChannel!);
      _clientsChannel = null;
    }
  }

  @override
  void dispose() {
    _disposeSubscriptions();
    super.dispose();
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
      
      // Refresh count for the affected room
      await _fetchCountForRoom(closestRoom.id);
      notifyListeners();
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
      // Get the client's room ID before deleting
      final client = await _sqliteService.getClientById(id);
      final roomId = client?.waitingRoomId;

      await _sqliteService.deleteClient(id);

      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.deleteClient(id);
        } catch (e) {
          print('⚠️ Impossible de supprimer sur Supabase: $e');
        }
      }

      await loadClients();

      // Refresh count for the affected room
      if (roomId != null) {
        await _fetchCountForRoom(roomId);
        notifyListeners();
      }
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
      
      // Refresh counts for all rooms after sync
      await _refreshCountsForAllRooms();

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
