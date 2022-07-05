import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:blue_retro_config/otaupdate.dart';
import './blueretroUtils.dart';
import './n64manager.dart';

class selecteddevice extends StatefulWidget {
  final BluetoothDevice device;
  const selecteddevice({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  State<selecteddevice> createState() => _selecteddeviceState();
}

class _selecteddeviceState extends State<selecteddevice> {
  @override
  void initState() {
    super.initState();
  }

  void _connectToDevice() async {
    try {
      await widget.device.connect();
      await Future.delayed(Duration(seconds: 1), () {});
      await widget.device.requestMtu(512);
      await Future.delayed(Duration(seconds: 1), () {});
      print("app version:");
      print(String.fromCharCodes(await readAppVersion(widget.device)));
      print("API version");
      print(await readAPIversion(widget.device));
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlueRetro Config'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'BlueRetro Config',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.alt_route),
              title: Text('Presets'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        N64ManagementScreen(btDevice: widget.device),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.construction),
              title: Text('Custom Bindings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        N64ManagementScreen(btDevice: widget.device),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sd_card),
              title: Text('N64 management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        N64ManagementScreen(btDevice: widget.device),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Advance Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        N64ManagementScreen(btDevice: widget.device),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.update),
              title: Text('OTA update'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtaScreen(btDevice: widget.device),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Text(widget.device.name),
      persistentFooterButtons: [],
    );
  }
}
