import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/client_provider.dart';
import '../models/waiting_room.dart';
import '../utils/capacity_helpers.dart';

/// Screen that displays a list of waiting rooms with live load indicators.
/// 
/// Each room shows:
/// - Room name
/// - Current client count
/// - Color-coded capacity badge (Light/Moderate/Busy)
class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room List'),
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
                            final syncedIds = await provider.synchronize();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${syncedIds.length} client(s) synchronized',
                                  ),
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
                    'No waiting rooms available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.synchronize().then((_) {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.waitingRooms.length,
              itemBuilder: (context, index) {
                final room = provider.waitingRooms[index];
                final clientCount = provider.getClientCountForRoom(room.id);
                
                return _RoomCard(
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

/// Card widget displaying a single waiting room with capacity indicator.
class _RoomCard extends StatelessWidget {
  final WaitingRoom room;
  final int clientCount;

  const _RoomCard({
    required this.room,
    required this.clientCount,
  });

  @override
  Widget build(BuildContext context) {
    final capacityLevel = capacityForCount(clientCount);
    final color = capacityColor(capacityLevel);
    final label = capacityLabel(capacityLevel);
    final icon = capacityIcon(capacityLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Room icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.meeting_room,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Room info
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
                    '$clientCount client${clientCount != 1 ? 's' : ''} waiting',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Capacity badge
            _CapacityBadge(
              level: capacityLevel,
              label: label,
              color: color,
              icon: icon,
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge widget showing the capacity level with color coding.
class _CapacityBadge extends StatelessWidget {
  final RoomCapacityLevel level;
  final String label;
  final Color color;
  final IconData icon;

  const _CapacityBadge({
    required this.level,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
