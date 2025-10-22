import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WaitingRoomScreen());
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use watch to listen to state changes (rebuilds widget)
    final provider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Waiting Room'),
        actions: [
          IconButton(
            key: const Key('nextClientButton'),
            icon: const Icon(Icons.skip_next),
            onPressed: () {
              // Use context.read() to call a method without listening for changes.
              context.read<QueueProvider>().nextClient();
            },
            tooltip: 'Next Client',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _AddClientField(),
            const SizedBox(height: 16),
            Text('Clients in Queue: ${provider.clients.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: provider.clients.length,
                itemBuilder: (context, index) {
                  final clientName = provider.clients[index];
                  return Card(
                    child: ListTile(
                      title: Text(clientName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Use read to call methods (doesn't rebuild)
                          context.read<QueueProvider>().removeClient(
                            clientName,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddClientField extends StatefulWidget {
  const _AddClientField();

  @override
  State<_AddClientField> createState() => _AddClientFieldState();
}

class _AddClientFieldState extends State<_AddClientField> {
  final TextEditingController _controller = TextEditingController();

  void _addClient() {
    if (_controller.text.isNotEmpty) {
      // Use read to call methods (doesn't rebuild)
      context.read<QueueProvider>().addClient(_controller.text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Client Name'),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: _addClient, child: const Text('Add')),
      ],
    );
  }
}
