import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:math';

class N64ManagementScreen extends StatefulWidget {
  // In the constructor, require a Todo.
  const N64ManagementScreen({super.key, required this.btDevice});

  final BluetoothDevice btDevice;
  @override
  _N64ManagementScreenState createState() => _N64ManagementScreenState();
}

class _N64ManagementScreenState extends State<N64ManagementScreen> {
  double currentProgress = 0;

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

  void pakRead(pak) async {
    int offsetNum = pak * 32768;

    int byte1 = offsetNum & 0x000000FF;
    int byte2 = (offsetNum & 0x0000FF00) >> 8;
    int byte3 = (offsetNum & 0x00FF0000) >> 16;
    int byte4 = (offsetNum & 0xFF000000) >> 24;
    List<int> offset = [byte1, byte2, byte3, byte4];

    List<BluetoothService> services = await widget.btDevice.discoverServices();
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

  void pakWrite(pak, data) async {
    List<BluetoothService> services = await widget.btDevice.discoverServices();
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
      position = end;
      i = position;
      print(i);
      setState(() {
        currentProgress = i / data.length;
      });
    }
    await characteristics[9].write([0, 0, 0, 0]);
  }
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
