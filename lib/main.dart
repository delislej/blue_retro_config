import 'dart:async';
import 'dart:io' show Platform;
import 'package:blue_retro_config/otaupdate.dart';
import 'package:blue_retro_config/selecteddevice.dart';
import './blueretroUtils.dart';

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
    print("starting scan...");
// Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
      btFoundDevices.clear();
      blueRetroDevices.clear();
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

      await flutterBlue.startScan(timeout: Duration(seconds: 5));

// Listen to scan results
      List<BluetoothDevice> connectedDevices =
          await flutterBlue.connectedDevices;
      for (BluetoothDevice device in connectedDevices) {
        if (device.name.contains("Blue")) {
          print(device);
          if (!blueRetroDevices.contains(device.id)) {
            print("adding device!");
            blueRetroDevices.add(device.id);
            setState(() => {btFoundDevices.add(device)});
          }
        }
      }
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
      print("stopping scanning...");
      await flutterBlue.stopScan();
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
      print(String.fromCharCodes(await readAppVersion(_device)));
      print("API version");
      print(await readAPIversion(_device));
      setState(() {
        _connected = true;
      });
    } catch (err) {
      print(err);
    }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
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
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                selecteddevice(device: _device)));
                        setState(() => {});
                      },
                    ));
                  }),
            ),
      persistentFooterButtons: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _startScan,
          child: const Icon(Icons.search),
        ),
      ],
    ));
  }
}
