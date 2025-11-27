import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/waiting_room.dart';
import '../providers/client_provider.dart';

class ClientDetailPage extends StatelessWidget {
  final Client client;

  const ClientDetailPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du client'),
      ),
      body: FutureBuilder<WaitingRoom?>(
        future: context.read<ClientProvider>().getWaitingRoomById(
          client.waitingRoomId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final waitingRoom = snapshot.data;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card principale
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            child: Text(
                              client.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            client.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Informations
                  _InfoSection(
                    title: 'Informations générales',
                    items: [
                      _InfoItem(
                        icon: Icons.access_time,
                        label: 'Date de création',
                        value: _formatDateTime(client.createdAt),
                      ),
                      _InfoItem(
                        icon: Icons.fingerprint,
                        label: 'ID',
                        value: client.id,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Localisation
                  _InfoSection(
                    title: 'Localisation',
                    items: [
                      _InfoItem(
                        icon: Icons.location_on,
                        label: 'Latitude',
                        value: client.lat.toStringAsFixed(6),
                      ),
                      _InfoItem(
                        icon: Icons.location_on,
                        label: 'Longitude',
                        value: client.lng.toStringAsFixed(6),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Waiting Room
                  _InfoSection(
                    title: 'Salle d\'attente',
                    items: [
                      _InfoItem(
                        icon: Icons.meeting_room,
                        label: 'Nom',
                        value: waitingRoom?.name ?? 'Chargement...',
                      ),
                      if (waitingRoom != null) ...[
                        _InfoItem(
                          icon: Icons.place,
                          label: 'Position salle',
                          value: '${waitingRoom.latitude.toStringAsFixed(4)}, '
                              '${waitingRoom.longitude.toStringAsFixed(4)}',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _InfoSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
