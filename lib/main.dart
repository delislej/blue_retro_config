import 'dart:async';
import 'dart:io' show Platform;
import 'package:blue_retro_config/otaupdate.dart';

import './n64manager.dart';
//import 'package:collection/collection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'dart:typed_data';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  return runApp(
    const MaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
//OTA update bytes
  List<int> ota_start = [0xa5];

  List<int> ota_end = [0x5a];

  List<int> ota_abort = [0xde];
  double currentProgress = 0;

//list view stuff

  List<BluetoothDevice> btFoundDevices = [];
  Set<DeviceIdentifier> blueRetroDevices = {};

// Some state management stuff
  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;
  Uint8List fileData = Uint8List.fromList([0]);
  FlutterBlue flutterBlue = FlutterBlue.instance;
  late BluetoothDevice _device;

  void _startScan() async {
// Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });

    if (Platform.isAndroid) {
      if (await Permission.location.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        permGranted = true;
      }
    } else if (Platform.isIOS) {
      permGranted = true;
    }

    if (await Permission.bluetooth.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    }

    if (await Permission.bluetoothScan.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    }
    if (await Permission.bluetoothConnect.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    }

    if (permGranted) {
// Main scanning logic happens here ⤵️

      flutterBlue.startScan(timeout: Duration(seconds: 15));

// Listen to scan results
      var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results

        for (ScanResult r in results) {
          if (r.device.name.contains("Blue")) {
            print(r.device);
            if (!blueRetroDevices.contains(r.device.id)) {
              print("adding device!");
              blueRetroDevices.add(r.device.id);
              setState(() => {btFoundDevices.add(r.device)});
            }
          }
        }
      });

// Stop scanning
      flutterBlue.stopScan();
      setState(() {
        _scanStarted = false;
      });
    }
  }

  void _connectToDevice() async {
    try {
      await _device.connect();
      await Future.delayed(Duration(seconds: 1), () {});
      await _device.requestMtu(512);
      await Future.delayed(Duration(seconds: 1), () {});
      print("app version:");
      print(String.fromCharCodes(await readAppVersion()));
      print("API version");
      print(await readAPIversion());
      setState(() {
        _connected = true;
      });
    } catch (err) {
      print(err);
    }
  }

  void _writeGlobalCfg(chrc) async {
    await chrc.write([0, 0, 0, 3]);
  }

  Future<Uint8List> pickFile() async {
    try {
      FilePickerCross data =
          await FilePickerCross.importFromStorage(type: FileTypeCross.any);
      return data.toUint8List();
    } catch (err) {
      return Uint8List.fromList([0]);
    }
  }

  Future<List<int>> readGlobalCfg() async {
    try {
      List<BluetoothService> services = await _device.discoverServices();
      var characteristics = services[3].characteristics;
      List<int> globalCfg = await characteristics[0].read();
      print(globalCfg);
      return globalCfg;
    } catch (err) {
      return [-1, -1, -1, -1];
    }
  }

  Future<List<int>> readAppVersion() async {
    try {
      List<BluetoothService> services = await _device.discoverServices();
      var characteristics = services[3].characteristics;
      List<int> globalCfg = await characteristics[8].read();
      print(globalCfg);
      return globalCfg;
    } catch (err) {
      return [-1, -1, -1, -1];
    }
  }

  Future<List<int>> readAPIversion() async {
    try {
      List<BluetoothService> services = await _device.discoverServices();
      var characteristics = services[3].characteristics;
      List<int> globalCfg = await characteristics[5].read();
      print(globalCfg);
      return globalCfg;
    } catch (err) {
      return [-1];
    }
  }

  void writeGlobalCfg(cfg) async {
    try {
      List<BluetoothService> services = await _device.discoverServices();
      var characteristics = services[3].characteristics;
      await characteristics[0].write(cfg);
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
      backgroundColor: Colors.white,
      body: _connected
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.grey,
                value: currentProgress,
                semanticsLabel: 'Linear progress indicator',
              ),
            )
          : Center(
              child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: btFoundDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                        child: ListTile(
                      title: Text(btFoundDevices[index].name),
                      onTap: () {
                        BluetoothDevice temp = btFoundDevices[index];
                        print(btFoundDevices[index]);
                        _device = btFoundDevices[index];
                        _foundDeviceWaitingToConnect = true;
                        setState(() => {});
                      },
                    ));
                  }),
            ),
      /**/
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
                        N64ManagementScreen(btDevice: _device),
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
                        N64ManagementScreen(btDevice: _device),
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
                        N64ManagementScreen(btDevice: _device),
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
                        N64ManagementScreen(btDevice: _device),
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
                    builder: (context) => OtaScreen(btDevice: _device),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      persistentFooterButtons: [
        // We want to enable this button if the scan has NOT started
        // If the scan HAS started, it should be disabled.
        _scanStarted
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.search),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _startScan,
                child: const Icon(Icons.search),
              ),
        _foundDeviceWaitingToConnect
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _connectToDevice,
                child: const Icon(Icons.bluetooth),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.bluetooth),
              ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () async {
            //pakWrite(0, await pickFile());
          },
          child: const Icon(Icons.file_upload),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () async {
            //print(makeFormattedPak());
            //pakRead(0);
            //writeGlobalCfg([0, 0, 0, 0]);
            //otaWrite(await pickFile());
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => N64ManagementScreen(btDevice: _device),
              ),
            );
          },
          child: const Icon(Icons.fire_hydrant),
        ),
      ],
    );
  }
}
