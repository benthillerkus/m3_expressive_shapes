import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

export 'all_shapes.dart';
export 'stars.dart';
export 'polygons.dart';

class Todo extends LinearBorder {
  const Todo();
}

class Circle extends CircleBorder {
  const Circle();
}

class Square extends RoundedRectangleBorder {
  const Square()
    : super(borderRadius: const BorderRadius.all(Radius.circular(28)));
}

class Slanted extends Todo {
  const Slanted();
}

class Arch extends Todo {
  const Arch();
}

class SemiCircle extends Todo {
  const SemiCircle();
}

class Oval extends Todo {
  const Oval();
}

class Pill extends Todo {
  const Pill();
}

class Arrow extends Todo {
  const Arrow();
}

class Fan extends Todo {
  const Fan();
}

class ClamShell extends Todo {
  const ClamShell();
}

class Pentagon extends Todo {
  const Pentagon();
}

class Gem extends Todo {
  const Gem();
}

class Sunny extends Todo {
  const Sunny();
}

class VerySunny extends Todo {
  const VerySunny();
}

class Cookie4Sided extends Todo {
  const Cookie4Sided();
}

class Cookie6Sided extends Todo {
  const Cookie6Sided();
}

class Cookie7Sided extends Todo {
  const Cookie7Sided();
}

class Cookie9Sided extends Todo {
  const Cookie9Sided();
}

class Cookie12Sided extends Todo {
  const Cookie12Sided();
}

class SoftBoom extends Todo {
  const SoftBoom();
}

class Flower extends Todo {
  const Flower();
}

class Puffy extends Todo {
  const Puffy();
}

class PuffyDiamond extends Todo {
  const PuffyDiamond();
}

class Ghostish extends Todo {
  const Ghostish();
}

class PixelCircle extends Todo {
  const PixelCircle();
}

class PixelTriangle extends Todo {
  const PixelTriangle();
}

class Bun extends Todo {
  const Bun();
}

class Heart extends Todo {
  const Heart();
}
