// lib/main.dart
import 'package:flutter/material.dart';
import 'package:waiting_room_app/waiting_room_manager.dart';

void main() {
  runApp(const WaitingRoomApp());
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: WaitingRoomScreen());
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});
  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

// The private _WaitingRoomScreenState class manages the widget's state.
class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  // Our logic manager is now part of the UI state.
  final WaitingRoomManager _manager = WaitingRoomManager();
  // This controller manages the text input field's value.
  final TextEditingController _controller = TextEditingController();
  void _addClient() {
    if (_controller.text.isNotEmpty) {
      // We wrap the state change in setState() to tell Flutter to rebuild the UI.
      setState(() {
        _manager.addClient(_controller.text);
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
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
            ),
            const SizedBox(height: 16),
            // The Text widget dynamically shows the queue length.
            Text('Clients in Queue: ${_manager.clients.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: _manager.clients.length,
                itemBuilder: (context, index) {
                  final clientName = _manager.clients[index];
                  return Card(
                    child: ListTile(
                      title: Text(clientName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _manager.removeClient(clientName);
                          });
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

