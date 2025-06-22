import 'package:flutter/material.dart';

import 'triangle_border.dart';

void main() {
  runApp(const MainApp());
}

StarBorder? s;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TweenAnimationBuilder(
            tween: ShapeBorderTween(
              begin: const TriangleBorder(),
              end: const StarBorder(
                side: BorderSide(width: 4, style: BorderStyle.solid, color: Colors.green),
              ),
            ),
            duration: Durations.extralong1,
            builder: (BuildContext context, ShapeBorder? value, Widget? child) {
              return DecoratedBox(
                decoration: ShapeDecoration(
                  shape: value!,
                  shadows: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                  ],
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.red]),
                ),
                child: child,
              );
            },
            child: const Text(maxLines: 4, """
          asdf
          hello0 world
          asd"""),
          ),
        ),
      ),
    );
  }
}
