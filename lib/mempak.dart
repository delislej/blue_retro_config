import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';

class Mempak extends StatelessWidget {
  final int paknum;
  const Mempak({Key? key, required this.paknum}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Center(child: Text(paknum.toString())),
    );
  }
}
