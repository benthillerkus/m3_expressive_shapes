import 'package:example/list.dart';
import 'package:example/table.dart';
import 'package:flutter/material.dart';
import 'package:m3e_shapes/m3e_shapes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShapesOverviewScreen()
    );
  }
}
