import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class N64ManagementScreen extends StatefulWidget {
  // In the constructor, require a Todo.
  const N64ManagementScreen({super.key, required this.btDevice});

  final BluetoothDevice btDevice;
  @override
  _N64ManagementScreenState createState() => _N64ManagementScreenState();
}

class _N64ManagementScreenState extends State<N64ManagementScreen> {
  // In the constructor, require a Todo.

  // Declare a field that holds the Todo.

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text("N64 Managment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(widget.btDevice.name),
      ),
    );
  }
}
