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
import 'dart:async';

class ClientProvider with ChangeNotifier {
  final SQLiteService _sqliteService = SQLiteService();
  final SupabaseService _supabaseService = SupabaseService();
  final SyncService _syncService = SyncService();

  List<Client> _clients = [];
  List<WaitingRoom> _waitingRooms = [];
  bool _isLoading = false;
  bool _isOnline = false;
  
  /// Map of room IDs to their current client counts.
  /// This is used to display live load indicators on the Room List screen.
  final Map<String, int> _roomClientCounts = {};
  
  /// Supabase realtime channel for client updates
  RealtimeChannel? _clientsChannel;

  List<Client> get clients => _clients;
  List<WaitingRoom> get waitingRooms => _waitingRooms;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  
  /// Returns the map of room IDs to client counts.
  Map<String, int> get roomClientCounts => Map.unmodifiable(_roomClientCounts);
  
  /// Returns the client count for a specific room.
  int getClientCountForRoom(String roomId) {
    return _roomClientCounts[roomId] ?? 0;
  }

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
    
    // Étape 5: Refresh room client counts
    await _refreshCountsForAllRooms();
    print('📊 Compteurs de clients par salle rafraîchis');
    
    // Étape 6: Monitorer connectivité
    _monitorConnectivity();
    print('🌐 Monitoring de connectivité activé');
    
    // Étape 7: Set up realtime subscriptions
    _setupRealtimeSubscriptions();
    print('📡 Abonnements temps réel configurés');
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
  
  /// Refreshes the client count for all waiting rooms.
  /// This iterates through all rooms and fetches the count from local clients.
  Future<void> _refreshCountsForAllRooms() async {
    for (final room in _waitingRooms) {
      await _fetchCountForRoom(room.id);
    }
    notifyListeners();
  }
  
  /// Fetches and updates the client count for a specific room.
  Future<void> _fetchCountForRoom(String roomId) async {
    final count = _clients.where((c) => c.waitingRoomId == roomId).length;
    _roomClientCounts[roomId] = count;
  }
  
  /// Sets up Supabase realtime subscriptions to listen for client changes.
  /// When clients are added or removed, the counts are automatically updated.
  void _setupRealtimeSubscriptions() {
    try {
      final supabase = Supabase.instance.client;
      
      _clientsChannel = supabase.channel('public:clients');
      
      _clientsChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'clients',
        callback: (payload) {
          print('📥 Realtime: Client ajouté - ${payload.newRecord}');
          _handleClientInsert(payload.newRecord);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'clients',
        callback: (payload) {
          print('📤 Realtime: Client supprimé - ${payload.oldRecord}');
          _handleClientDelete(payload.oldRecord);
        },
      ).subscribe();
      
      print('✅ Abonnement realtime configuré pour la table clients');
    } catch (e) {
      print('⚠️ Erreur configuration realtime: $e');
    }
  }
  
  /// Handles a realtime INSERT event for a client.
  void _handleClientInsert(Map<String, dynamic> record) {
    final roomId = record['waiting_room_id'] as String?;
    if (roomId != null) {
      _roomClientCounts[roomId] = (_roomClientCounts[roomId] ?? 0) + 1;
      notifyListeners();
    }
  }
  
  /// Handles a realtime DELETE event for a client.
  void _handleClientDelete(Map<String, dynamic> record) {
    final roomId = record['waiting_room_id'] as String?;
    if (roomId != null) {
      final currentCount = _roomClientCounts[roomId] ?? 0;
      if (currentCount > 0) {
        _roomClientCounts[roomId] = currentCount - 1;
      }
      notifyListeners();
    }
  }
  
  /// Disposes of the realtime channel when no longer needed.
  void dispose() {
    _clientsChannel?.unsubscribe();
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
      
      // Refresh the count for the affected room
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
      final client = _clients.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Client not found'),
      );
      final roomId = client.waitingRoomId;
      
      await _sqliteService.deleteClient(id);

      if (await _syncService.isOnline()) {
        try {
          await _supabaseService.deleteClient(id);
        } catch (e) {
          print('⚠️ Impossible de supprimer sur Supabase: $e');
        }
      }

      await loadClients();
      
      // Refresh the count for the affected room
      await _fetchCountForRoom(roomId);
      notifyListeners();
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
      
      // Refresh counts after synchronization
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
