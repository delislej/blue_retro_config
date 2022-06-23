import 'dart:async';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'dart:typed_data';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:math';

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

      flutterBlue.startScan(timeout: Duration(seconds: 30));

// Listen to scan results
      var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
          if (r.device.name.contains("Blue")) {
            print("found a blueretro device!");
            flutterBlue.stopScan();
            setState(() {
              _device = r.device;
              _foundDeviceWaitingToConnect = true;
            });
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
    await _device.connect();
    await Future.delayed(Duration(seconds: 1), () {});
    await _device.requestMtu(512);
    await Future.delayed(Duration(seconds: 1), () {});
    setState(() {
      _connected = true;
    });
  }

  void changeMtu() async {
    //await _Device.requestMtu(512);
  }

  void _writeGlobalCfg(chrc) async {
    await chrc.write([0, 0, 0, 3]);
  }

  List<int> writeAt(ofs, data, block) {
    for (int i = 0; i < 32; i++) {
      data[ofs + i] = block[i];
    }
    return data;
  }

  List<int> makeFormattedPak() {
    List<int> data = List<int>.filled(32768, 0, growable: false);
    List<int> block = List<int>.filled(32, 0, growable: false);

    // generate id block
    block[1] = 0 | ((Random().nextDouble() * 256).toInt() & 0x3f);
    block[5] = 0 | (((Random().nextDouble() * 256).toInt()) & 0x7);
    block[6] = 0 | ((Random().nextDouble().toInt()) * 256);
    block[7] = 0 | ((Random().nextDouble() * 256).toInt());
    block[8] = 0 | (((Random().nextDouble() * 256).toInt()) & 0xf);
    block[9] = 0 | ((Random().nextDouble() * 256).toInt());
    block[10] = 0 | ((Random().nextDouble() * 256).toInt());
    block[11] = 0 | ((Random().nextDouble() * 256).toInt());
    block[25] = 0x01; // device bit
    block[26] = 0x01; // bank size int (must be exactly '01')

    // calculate pakId checksum
    int sumA = 0, sumB = 0xfff2;
    for (int i = 0; i < 28; i += 2) {
      sumA += (block[i] << 8) + block[i + 1];
      sumA &= 0xffff;
    }
    sumB -= sumA;
    // store checksums
    block[28] = sumA >> 8;
    block[29] = sumA & 0xff;
    block[30] = sumB >> 8;
    block[31] = sumB & 0xff;

    // write checksum block to multiple sections in header page
    writeAt(32, data, block);
    writeAt(96, data, block);
    writeAt(128, data, block);
    writeAt(192, data, block);

    // init IndexTable and backup (plus checksums)
    for (int i = 5; i < 128; i++) {
      data[256 + i * 2 + 1] = 3;
      data[512 + i * 2 + 1] = 3;
    }
    data[257] = 0x71;
    data[513] = 0x71;

    //for(let i = 0; i < 32; i++) data[i] = i; // write label - needs to be verified
    //data[0] = 0x81; // libultra's 81 mark
    return data;
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

  void pakRead(pak) async {
    int offsetNum = pak * 32768;

    int byte1 = offsetNum & 0x000000FF;
    int byte2 = (offsetNum & 0x0000FF00) >> 8;
    int byte3 = (offsetNum & 0x00FF0000) >> 16;
    int byte4 = (offsetNum & 0xFF000000) >> 24;
    List<int> offset = [byte1, byte2, byte3, byte4];

    List<BluetoothService> services = await _device.discoverServices();
    var characteristics = services[3].characteristics;
    await characteristics[9].write(offset);
    List<int> data = [];
    for (int i = 0; i < 32768; i += 0) {
      List<int> newdata = await characteristics[10].read();
      await Future.delayed(const Duration(milliseconds: 150), () {});
      print(newdata);
      data = data + newdata;
      i += newdata.length;
      print(i);
    }
    await characteristics[9].write([0, 0, 0, 0]);
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

  void writeGlobalCfg(cfg) async {
    try {
      List<BluetoothService> services = await _device.discoverServices();
      var characteristics = services[3].characteristics;
      await characteristics[0].write(cfg);
    } catch (err) {
      print(err);
    }
  }

  void pakWrite(pak, data) async {
    List<BluetoothService> services = await _device.discoverServices();
    var characteristics = services[3].characteristics;
    int offsetNum = pak * 32768;

    int byte1 = offsetNum & 0x000000FF;
    int byte2 = (offsetNum & 0x0000FF00) >> 8;
    int byte3 = (offsetNum & 0x00FF0000) >> 16;
    int byte4 = (offsetNum & 0xFF000000) >> 24;
    List<int> offset = [byte1, byte2, byte3, byte4];

    await characteristics[9].write(offset);
    await Future.delayed(const Duration(milliseconds: 400), () {});

    int mtu = 128;
    int position = 0;
    for (int i = 0; i < 32768; i += 0) {
      int end = 0;
      if (position + mtu > data.length) {
        end = data.length;
      } else {
        end = position + mtu;
      }
      List<int> dataToWrite = data.sublist(position, end);
      print(dataToWrite.length);
      await characteristics[10].write(dataToWrite);
      await Future.delayed(const Duration(milliseconds: 100), () {});
      position = end;
      i = position;
      print(i);
    }
    await characteristics[9].write([0, 0, 0, 0]);
  }

  void otaWrite(data) async {
    List<BluetoothService> services = await _device.discoverServices();
    var characteristics = services[3].characteristics;

    await characteristics[6].write(ota_start);
    await Future.delayed(const Duration(milliseconds: 400), () {});

    int mtu = 128;
    int position = 0;
    for (int i = 0; i < data.length; i += 0) {
      int end = 0;
      if (position + mtu > data.length) {
        end = data.length;
      } else {
        end = position + mtu;
      }
      List<int> dataToWrite = data.sublist(position, end);

      await characteristics[7].write(dataToWrite);
      await Future.delayed(const Duration(milliseconds: 75), () {});
      position = end;
      i = position;
      print((i / data.length) * 100);
    }
    await characteristics[6].write(ota_end);
  }

  void _partyTime() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawer Demo'),
      ),
      backgroundColor: Colors.white,
      body: Container(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Messages'),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
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
            pakWrite(0, await pickFile());
          },
          child: const Icon(Icons.file_upload),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () {
            //print(makeFormattedPak());
            //pakRead(0);
            pakRead(3);
          },
          child: const Icon(Icons.file_download),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () async {
            //print(makeFormattedPak());
            //pakRead(0);
            print(await readGlobalCfg());
          },
          child: const Icon(Icons.fire_truck),
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
            otaWrite(await pickFile());
          },
          child: const Icon(Icons.fire_hydrant),
        ),
      ],
    );
  }
}
