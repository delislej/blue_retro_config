import 'package:flutter_blue/flutter_blue.dart';

Future<List<int>> readGlobalCfg(BluetoothDevice device) async {
  try {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services[3].characteristics;
    List<int> globalCfg = await characteristics[0].read();
    print(globalCfg);
    return globalCfg;
  } catch (err) {
    return [-1, -1, -1, -1];
  }
}

Future<List<int>> readAppVersion(BluetoothDevice device) async {
  try {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services[3].characteristics;
    List<int> globalCfg = await characteristics[8].read();
    print(globalCfg);
    return globalCfg;
  } catch (err) {
    return [-1, -1, -1, -1];
  }
}

void connectToDevice(BluetoothDevice device) async {
  try {
    await device.connect();
  } catch (err) {
    print(err);
  }
}

Future<List<int>> readAPIversion(BluetoothDevice device) async {
  try {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services[3].characteristics;
    List<int> globalCfg = await characteristics[5].read();
    print(globalCfg);
    return globalCfg;
  } catch (err) {
    return [-1];
  }
}

void writeGlobalCfg(List<int> cfg, BluetoothDevice device) async {
  try {
    List<BluetoothService> services = await device.discoverServices();
    var characteristics = services[3].characteristics;
    await characteristics[0].write(cfg);
  } catch (err) {
    print(err);
  }
}
