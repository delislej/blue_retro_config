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
  bool isN64 = false;
  String appVer = "";
  bool loading = true;
  List<int> apiver = [];
  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  void _connectToDevice() async {
    try {
      await widget.device.connect();
    } catch (e) {}
    try {
      await Future.delayed(const Duration(seconds: 1), () {});
      await widget.device.requestMtu(512);
      await Future.delayed(const Duration(seconds: 1), () {});
      print("app version:");
      appVer = String.fromCharCodes(await readAppVersion(widget.device));
      print("API version");
      apiver = await readAPIversion(widget.device);
      setState(() {
        loading = false;
      });
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading == false
        ? Scaffold(
            appBar: AppBar(
              title: const Text('BlueRetro Config'),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
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
                    leading: const Icon(Icons.alt_route),
                    title: const Text('Presets'),
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
                    leading: const Icon(Icons.construction),
                    title: const Text('Custom Bindings'),
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
                  if (appVer.contains("n64") == true)
                    ListTile(
                      leading: const Icon(Icons.sd_card),
                      title: const Text('N64 management'),
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
                    leading: const Icon(Icons.settings),
                    title: const Text('Advance Settings'),
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
                    leading: const Icon(Icons.update),
                    title: const Text('OTA update'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OtaScreen(btDevice: widget.device),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: ListView(
              children: [Text(widget.device.name), Text(appVer)],
            ),
            persistentFooterButtons: [],
          )
        : const CircularProgressIndicator();
  }
}
