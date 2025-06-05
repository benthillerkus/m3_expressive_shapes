import 'package:flutter/painting.dart';

class Clover4Leaf extends StarBorder {
  const Clover4Leaf() : super(points: 4, pointRounding: 1, rotation: 45, innerRadiusRatio: .15);
}

class Clover8Leaf extends StarBorder {
  const Clover8Leaf()
    : super(points: 8, pointRounding: 1, rotation: 360 / 8 / 2, innerRadiusRatio: .6);
}

class Burst extends StarBorder {
  const Burst() : super(points: 12, innerRadiusRatio: .7);
}

class SoftBurst extends StarBorder {
  const SoftBurst()
    : super(points: 10, innerRadiusRatio: .7, valleyRounding: .2, pointRounding: .4);
}

class Boom extends StarBorder {
  const Boom() : super(points: 15, innerRadiusRatio: .4);
}
