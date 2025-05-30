import 'dart:math';
import 'dart:ui';

import 'package:meta/meta.dart';

extension OffsetExt on Offset {

  @pragma('vm:prefer-inline')
  double dotProduct(Offset other) => dx * other.dx + dy * other.dy;

  /// Compute the Z coordinate of the cross product of two vectors, to check if the second vector is
  /// going clockwise ( > 0 ) or counterclockwise (< 0) compared with the first one. It could also be
  /// 0, if the vectors are co-linear.
  @pragma('vm:prefer-inline')
  bool clockwise(Offset other) => dx * other.dy - dy * other.dx > 0;

  Offset normalize() => this / distance;
}