import 'package:flutter/foundation.dart';
import 'package:m3_expressive_shapes/all_shapes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:m3_expressive_shapes/m3e_shapes.dart';

class ListShapesScreen extends StatefulWidget {
  const ListShapesScreen({super.key});

  @override
  State<ListShapesScreen> createState() => _ListShapesScreenState();
}

class _ListShapesScreenState extends State<ListShapesScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  Duration _progress = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _progress = elapsed;
      if (mounted) {
        setState(() {});
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static final shapesList = allShapes.values.toList(growable: false);
  static final namesList = allShapes.keys.toList(growable: false);

  @override
  Widget build(BuildContext context) {
    // Otherwise they won't update with hot reload
    final shapesList = switch (kDebugMode) {
      true => allShapes.values.toList(growable: false),
      false => _ListShapesScreenState.shapesList,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverFixedExtentList.builder(
            itemCount: shapesList.length,
            itemBuilder: (context, index) {
              return Align(
                alignment: Alignment(index.isEven ? -.5 : .5, 0),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: ShapeDecoration(color: Colors.pink, shape: shapesList[index]),
                  child: SizedBox(
                    width: 256 - 64,
                    height: 256 - 64,
                    child: Text(namesList[index] * 12),
                  ),
                ),
              );
            },
            itemExtent: 256,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
          ),
        ],
      ),
    );
  }
}
