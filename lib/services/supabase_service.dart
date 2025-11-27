import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client.dart';
import '../models/waiting_room.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== WAITING ROOMS ==========

  Future<List<WaitingRoom>> fetchWaitingRooms() async {
    try {
      final response =
          await _supabase.from('waiting_rooms').select().order('name');

      return (response as List)
          .map((json) => WaitingRoom.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des salles: $e');
    }
  }

  Future<WaitingRoom?> fetchWaitingRoomById(String id) async {
    try {
      final response =
          await _supabase.from('waiting_rooms').select().eq('id', id).single();

      return WaitingRoom.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ========== CLIENTS ==========

  Future<List<Client>> fetchClients() async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Client.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  /// Fetch the count of clients for a specific waiting room
  Future<int> fetchClientCountByRoomId(String roomId) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('waiting_room_id', roomId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('Error fetching client count for room $roomId: $e');
      return 0;
    }
  }

  /// Fetch client counts for all waiting rooms in a single query
  Future<Map<String, int>> fetchAllRoomClientCounts(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return {};
    }
    
    try {
      // Use a single query with filter to get all clients
      final response = await _supabase
          .from('clients')
          .select('waiting_room_id')
          .inFilter('waiting_room_id', roomIds);

      // Count clients per room
      final Map<String, int> counts = {};
      for (final roomId in roomIds) {
        counts[roomId] = 0;
      }
      
      for (final row in response as List) {
        final roomId = row['waiting_room_id'] as String;
        counts[roomId] = (counts[roomId] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      debugPrint('Error fetching all room client counts: $e');
      // Fallback: return empty counts for all rooms
      return {for (final roomId in roomIds) roomId: 0};
    }
  }

  Future<void> addClient(Client client) async {
    try {
      await _supabase.from('clients').insert(client.toJson());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du client: $e');
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _supabase
          .from('clients')
          .update(client.toJson())
          .eq('id', client.id);
    } catch (e) {
      throw Exception('Erreur lors de la modification du client: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _supabase.from('clients').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du client: $e');
    }
  }

  // Vérifier si un client existe déjà
  Future<bool> clientExists(String id) async {
    try {
      final response = await _supabase
          .from('clients')
          .select('id')
          .eq('id', id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Ajouter une waiting room
  Future<void> addWaitingRoom(WaitingRoom room) async {
    try {
      await _supabase.from('waiting_rooms').insert(room.toJson());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la waiting room: $e');
    }
  }

  // ========== REALTIME SUBSCRIPTIONS ==========

  /// Subscribe to realtime client changes (INSERT, DELETE, UPDATE)
  /// Returns a RealtimeChannel that can be used to unsubscribe later
  RealtimeChannel subscribeToClientChanges({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onDelete,
    void Function(Map<String, dynamic> payload)? onUpdate,
  }) {
    return _supabase
        .channel('clients-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            if (onUpdate != null) {
              onUpdate(payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from a realtime channel
  Future<void> unsubscribeFromChannel(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
