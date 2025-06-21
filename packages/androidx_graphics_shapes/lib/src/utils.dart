// Ported from Utils.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Utils.kt
// See original license at the end of this file.

import 'dart:ui';

import 'package:meta/meta.dart';

import 'point.dart';

/// These epsilon values are used internally to determine when two points are the same, within some
/// reasonable roundoff error. The distance epsilon is smaller, with the intention that the roundoff
/// should not be larger than a pixel on any reasonable sized display.
@internal
const double distanceEpsilon = 1e-4;
@internal
const double angleEpsilon = 1e-6;

/// This epsilon is based on the observation that people tend to see e.g. collinearity much more
/// relaxed than what is mathematically correct. This effect is heightened on smaller displays. Use
/// this epsilon for operations that allow higher tolerances.
@internal
const double relaxedDistanceEpsilon = 5e-3;

extension Rotate90Ext on Offset {
  Offset rotate90() => Offset(-dy, dx);
}

/// Returns whether C is on the line defined by the two points AB
@internal
bool collinearIsh(
  double aX,
  double aY,
  double bX,
  double bY,
  double cX,
  double cY, {
  double tolerance = distanceEpsilon,
}) {
  // The dot product of a perpendicular angle is 0. By rotating one of the vectors,
  // we save the calculations to convert the dot product to degrees afterwards.
  final ab = Offset(bX - aX, bY - aY).rotate90();
  final ac = Offset(cX - aX, cY - aY);
  final dotProduct = ab.dotProduct(ac).abs();
  final relativeTolerance = tolerance * ab.distance * ac.distance;

  return dotProduct < tolerance || dotProduct < relativeTolerance;
}

/// Approximates whether corner at this vertex is concave or convex, based on the relationship of the
/// prev->curr/curr->next vectors.
@internal
bool convex(Offset previous, Offset current, Offset next) {
  // TODO: b/369320447 - This is a fast, but not reliable calculation.
  return (current - previous).clockwise(next - current);
}

/// Does a ternary search in [v0..v1] to find the parameter that minimizes the given function.
/// Stops when the search space size is reduced below the given tolerance.
///
/// NTS: Does it make sense to split the function f in 2, one to generate a candidate, of a custom
/// type T (i.e. (Float) -> T), and one to evaluate it ( (T) -> Float )?
@internal
double findMinimum(double v0, double v1, FindMinimumFunction f, {double tolerance = 1e-3}) {
  var a = v0;
  var b = v1;
  while (b - a > tolerance) {
    final c1 = (2 * a + b) / 3;
    final c2 = (2 * b + a) / 3;
    if (f(c1) < f(c2)) {
      b = c2;
    } else {
      a = c1;
    }
  }
  return (a + b) / 2;
}

/// A functional interface for computing a Float value when finding the minimum at [findMinimum].
@internal
typedef FindMinimumFunction = double Function(double value);

/*
 * Copyright 2022 The Android Open Source Project
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
