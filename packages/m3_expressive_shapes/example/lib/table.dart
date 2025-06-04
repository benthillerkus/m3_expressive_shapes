import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3_expressive_shapes/m3e_shapes.dart';

class ShapesOverviewScreen extends StatefulWidget {
  const ShapesOverviewScreen({super.key});

  static final shapesList = allShapes.values.toList(growable: false);
  static final namesList = allShapes.keys.toList(growable: false);

  @override
  State<ShapesOverviewScreen> createState() => _ShapesOverviewScreenState();
}

class _ShapesOverviewScreenState extends State<ShapesOverviewScreen> {
  ShapeBorder _current = const CircleBorder();
  ShapeBorder _next = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    final style = TextTheme.of(context).labelSmall;

    // Otherwise they won't update with hot reload
    final shapesList = switch (kDebugMode) {
      true => allShapes.values.toList(growable: false),
      false => ShapesOverviewScreen.shapesList,
    };

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 216, 234),
      floatingActionButton: TweenAnimationBuilder(
        tween: ShapeBorderTween(begin: _current, end: _next),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return FloatingActionButton(
            isExtended: true,
            onPressed: null,
            shape: value,
            enableFeedback: true,
            clipBehavior: Clip.antiAlias,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 209, 224, 141),
                    Color.fromARGB(255, 237, 46, 208),
                  ],
                ),
              ),
              child: SizedBox(width: 512, height: 512),
            ),
          );
        },
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisExtent: 128 + 64,
        ),
        itemCount: shapesList.length,

        itemBuilder: (context, index) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(26, 0, 0, 0),
                width: .5,
              ),
            ),

            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _current = _next;
                              _next = shapesList[index];
                            });
                          },
                          child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: ShapeDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              shape: shapesList[index],
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  thickness: 1,
                  color: Color.fromARGB(26, 0, 0, 0),
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    ShapesOverviewScreen.namesList[index],
                    style: style,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
