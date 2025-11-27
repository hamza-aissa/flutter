import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';
import 'sqlite_service.dart';

class SyncService {
  final SupabaseService _supabaseService = SupabaseService();
  final SQLiteService _sqliteService = SQLiteService();

  // Vérifier la connexion Internet
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<String>> syncWaitingRoomsToSupabase() async {
    if (!await isOnline()) return [];

    final syncedIds = <String>[];

    try {
      final localRooms = await _sqliteService.getWaitingRooms();

      for (var room in localRooms) {
        try {
          await _supabaseService.addWaitingRoom(room);
          syncedIds.add(room.id);
          print('Waiting room ${room.id} synced to Supabase');
        } catch (e) {
          print('Error syncing waiting room ${room.id}: $e');
        }
      }
    } catch (e) {
      print('Error during waiting room sync: $e');
    }

    return syncedIds;
  }

  // Synchroniser les waiting rooms depuis Supabase vers SQLite
  Future<void> syncWaitingRooms() async {
    if (!await isOnline()) return;

    try {
      // Récupérer depuis Supabase
      final rooms = await _supabaseService.fetchWaitingRooms();

      // Insérer dans SQLite
      for (var room in rooms) {
        await _sqliteService.insertWaitingRoom(room);
      }
    } catch (e) {
      print('Erreur sync waiting rooms: $e');
    }
  }

  // Synchroniser les clients locaux vers Supabase
  Future<List<String>> syncClientsToSupabase() async {
    if (!await isOnline()) {
      return [];
    }

    final syncedIds = <String>[];

    try {
      // Récupérer tous les clients locaux
      final localClients = await _sqliteService.getClients();

      for (var client in localClients) {
        try {
          // Vérifier si le client existe déjà sur Supabase
          final exists = await _supabaseService.clientExists(client.id);

          if (exists) {
            // Mettre à jour (Supabase a priorité mais on peut choisir)
            // Pour l'instant on ne fait rien si existe déjà
            print('Client ${client.id} existe déjà sur Supabase');
          } else {
            // Ajouter le nouveau client
            await _supabaseService.addClient(client);
            syncedIds.add(client.id);
            print('Client ${client.id} synchronisé avec succès');
          }
        } catch (e) {
          print('Erreur sync client ${client.id}: $e');
        }
      }
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }

    return syncedIds;
  }

  // Synchroniser les clients depuis Supabase vers SQLite
  Future<void> syncClientsFromSupabase() async {
    if (!await isOnline()) return;

    try {
      final supabaseClients = await _supabaseService.fetchClients();

      for (var client in supabaseClients) {
        await _sqliteService.insertClient(client);
      }
    } catch (e) {
      print('Erreur sync clients from Supabase: $e');
    }
  }

  // Synchronisation complète (bidirectionnelle)
  Future<List<String>> fullSync() async {
    if (!await isOnline()) {
      return [];
    }
    await syncWaitingRoomsToSupabase();

    // Sync waiting rooms d'abord
    await syncWaitingRooms();

    // Sync clients local → Supabase
    final syncedIds = await syncClientsToSupabase();

    // Sync clients Supabase → local
    await syncClientsFromSupabase();

    return syncedIds;
  }

  // Écouter les changements de connectivité
  Stream<bool> get connectivityStream {
    return Connectivity().onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
}
