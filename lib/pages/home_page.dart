import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/client_provider.dart';
import '../models/client.dart';
import '../utils/test_data_generator.dart';
import 'client_detail_page.dart';
import 'room_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      // Récupérer la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur localisation: $e')),
        );
      }
      return null;
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _addClient() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    final position = await _getCurrentLocation();
    if (position == null) return;

    try {
      await context.read<ClientProvider>().addClient(
        _nameController.text.trim(),
        position,
      );

      _nameController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client ajouté avec succès ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle d\'attente'),
        actions: [
          // Room List button
          IconButton(
            icon: const Icon(Icons.meeting_room),
            tooltip: 'View Rooms',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoomListScreen(),
                ),
              );
            },
          ),
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
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${syncedIds.length} client(s) synchronisé(s)',
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
      body: Column(
        children: [
          // Zone d'ajout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du client',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSubmitted: (_) => _addClient(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _addClient,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_location),
                    label: Text(
                      _isLoadingLocation
                          ? 'Localisation...'
                          : 'Ajouter le client',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Liste des clients
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.clients.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.clients.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun client en attente',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.clients.length,
                  itemBuilder: (context, index) {
                    final client = provider.clients[index];
                    return _ClientListItem(
                      client: client,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailPage(client: client),
                          ),
                        );
                      },
                      onDelete: () async {
                        await provider.deleteClient(client.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Client supprimé'),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FloatingActionButton pour ajouter des données de test
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final testClients = TestDataGenerator.getTestClients();
          for (var testData in testClients) {
            await context.read<ClientProvider>().addClient(
              testData['name'] as String,
              testData['position'] as Position,
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${testClients.length} clients de test ajoutés'),
              ),
            );
          }
        },
        icon: const Icon(Icons.science),
        label: const Text('Test Data'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

class _ClientListItem extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClientListItem({
    required this.client,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(client.name[0].toUpperCase()),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Ajouté: ${_formatDateTime(client.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Position: ${client.lat.toStringAsFixed(4)}, ${client.lng.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
