import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'dart:typed_data';

class OtaScreen extends StatefulWidget {
  // In the constructor, require a Todo.
  const OtaScreen({super.key, required this.btDevice});

  final BluetoothDevice btDevice;

  @override
  _OtaScreenState createState() => _OtaScreenState();
}

class _OtaScreenState extends State<OtaScreen> {
  final List<int> ota_start = [0xa5];
  final List<int> ota_end = [0x5a];
  final List<int> ota_abort = [0xde];
  double currentProgress = 0;
  bool writeStarted = false;

  void otaWrite(data) async {
    setState(() {
      writeStarted = true;
    });
    await widget.btDevice.requestMtu(512);
    await Future.delayed(const Duration(seconds: 2), () {});
    List<BluetoothService> services = await widget.btDevice.discoverServices();
    var characteristics = services[3].characteristics;

    await characteristics[6].write(ota_start);
    await Future.delayed(const Duration(milliseconds: 100), () {});

    int mtu = 144;
    int position = 0;

    for (int i = 0; i < data.length; i += 0) {
      int end = 0;
      if (position + mtu > data.length) {
        end = data.length;
      } else {
        end = position + mtu;
      }
      List<int> dataToWrite = data.sublist(position, end);
      try {
        await characteristics[7].write(dataToWrite);
      } catch (err) {
        print(err);
        setState(() {
          currentProgress = 0;
        });
        return;
      }
      //await Future.delayed(const Duration(milliseconds: 75), () {});
      position = end;
      i = position;
      setState(() {
        currentProgress = i / data.length;
      });
      print((i / data.length));
    }
    await characteristics[6].write(ota_end);
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
  // In the constructor, require a Todo.

  // Declare a field that holds the Todo.

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text("OTA Update"),
      ),
      body: writeStarted
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.grey,
                value: currentProgress,
                semanticsLabel: 'Linear progress indicator',
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.btDevice.name),
            ),
      persistentFooterButtons: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: () async {
            otaWrite(await pickFile());
          },
          child: const Icon(Icons.file_upload),
        ),
      ],
    );
  }
}
