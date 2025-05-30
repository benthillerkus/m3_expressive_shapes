import 'package:flutter/painting.dart';

class Triangle extends StarBorder {
  const Triangle() : super.polygon(sides: 3, pointRounding: .35);
}

class Diamond extends StarBorder {
  const Diamond() : super.polygon(sides: 4, pointRounding: .35, squash: .8);
}
