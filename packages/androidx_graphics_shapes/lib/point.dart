// Ported from Point.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Point.kt
// See original license at the end of this file.

import 'dart:ui';

import 'cubic.dart';

extension OffsetExt on Offset {
  @pragma('vm:prefer-inline')
  double dotProduct(Offset other) => dx * other.dx + dy * other.dy;

  /// Compute the Z coordinate of the cross product of two vectors, to check if the second vector is
  /// going clockwise ( > 0 ) or counterclockwise (< 0) compared with the first one. It could also be
  /// 0, if the vectors are co-linear.
  @pragma('vm:prefer-inline')
  bool clockwise(Offset other) => dx * other.dy - dy * other.dx > 0;

  Offset normalize() => this / distance;

  Offset ktTransformed(PointTransformer f) {
    return f(dx, dy);
  }
}

/*
 * Copyright 2023 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
