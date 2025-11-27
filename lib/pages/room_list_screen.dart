import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../models/waiting_room.dart';
import '../utils/room_capacity.dart';

/// Screen that displays all waiting rooms with their current client counts
/// and color-coded capacity badges.
class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salles d\'attente'),
        actions: [
          Consumer<ClientProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  Icon(
                    provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: provider.isOnline ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.synchronize();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Données synchronisées'),
                                ),
                              );
                            }
                          },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.waitingRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.waitingRooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune salle d\'attente',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.synchronize(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.waitingRooms.length,
              itemBuilder: (context, index) {
                final room = provider.waitingRooms[index];
                final clientCount = provider.getClientCountForRoom(room.id);
                
                return _RoomListItem(
                  room: room,
                  clientCount: clientCount,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A list item widget that displays a room's information with capacity badge.
class _RoomListItem extends StatelessWidget {
  final WaitingRoom room;
  final int clientCount;

  const _RoomListItem({
    required this.room,
    required this.clientCount,
  });

  @override
  Widget build(BuildContext context) {
    final capacityLevel = capacityForCount(clientCount);
    final badgeColor = capacityColor(capacityLevel);
    final badgeLabel = capacityLabel(capacityLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Room icon
                CircleAvatar(
                  backgroundColor: badgeColor.withOpacity(0.2),
                  child: Icon(
                    Icons.meeting_room,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Room name and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Position: ${room.latitude.toStringAsFixed(4)}, ${room.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Bottom row with client count and capacity badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Client count
                Row(
                  children: [
                    const Icon(Icons.people, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '$clientCount client${clientCount != 1 ? 's' : ''} en attente',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Capacity badge
                Chip(
                  label: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: badgeColor.withOpacity(0.15),
                  side: BorderSide(color: badgeColor, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
