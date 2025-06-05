// Ported from FloatMapping.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/FloatMapping.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:typed_data';

import 'package:androidx_graphics_shapes/utils.dart';
import 'package:meta/meta.dart';

/// Checks if the given progress is in the given progress range, since progress is in the [0..1)
/// interval, and wraps, there is a special case when progressTo < progressFrom. For example, if the
/// progress range is 0.7 to 0.2, both 0.8 and 0.1 are inside and 0.5 is outside.
@internal
bool progressInRange(double progress, double progressFrom, double progressTo) =>
    (progressTo >= progressFrom)
    ? progress >= progressFrom && progress <= progressTo
    : progress >= progressFrom || progress <= progressTo;

/// Maps from one set of progress values to another. This is used by DoubleMapper to retrieve the
/// value on one shape that maps to the appropriate value on the other.
@internal
double linearMap(Float32List xValues, Float32List yValues, double x) {
  if (x < 0 || x > 1) throw ArgumentError.value(x, 'x', 'Invalid progress: $x');
  final segmentStartIndex = xValues.indexed
      .map((t) => t.$1)
      .firstWhere(
        (it) =>
            progressInRange(x, xValues[it], xValues[(it + 1) % xValues.length]),
      );
  final segmentEndIndex = (segmentStartIndex + 1) % xValues.length;
  final segmentSizeX = positiveModulo(
    xValues[segmentEndIndex] - xValues[segmentStartIndex],
    1,
  );
  final segmentSizeY = positiveModulo(
    yValues[segmentEndIndex] - yValues[segmentStartIndex],
    1,
  );
  final positionInSegment = (segmentSizeX < 0.001)
      ? 0.5
      : positiveModulo(x - xValues[segmentStartIndex], 1) / segmentSizeX;

  return positiveModulo(
    yValues[segmentStartIndex] + segmentSizeY * positionInSegment,
    1,
  );
}

/// DoubleMapper creates mappings from values in the
/// [0..1) source space to values in the [0..1) target space, and back.
///
/// This mapping is created given a finite list of representative mappings,
/// and this is extended to the whole interval by linear interpolation, and wrapping around.
///
/// For example, if we have mappings 0.2 to 0.5 and 0.4 to 0.6, then 0.3 (which is in the middle of the source interval)
/// will be mapped to 0.55 (the middle of the targets for the interval), 0.21 will map to 0.505, and so on.
/// As a more complete example, if we use x to represent a value in the source space and y for the target space,
/// and given as input the mappings 0 to 0, 0.5 to 0.25, this will create a mapping that:
/// `{ if x in [0 .. 0.5] } y = x / 2 { if x in [0.5 .. 1] } y = 0.25 + (x - 0.5) * 1.5 = x * 1.5 - 0.5`
///
/// The mapping can also be used the other way around (using the mapBack function), resulting in:
/// `{ if y in [0 .. 0.25] } x = y * 2 { if y in [0.25 .. 1] } x = (y + 0.5) / 1.5`
///
/// This is used to create mappings of progress values between the start and end shape,
/// which is then used to insert new curves and match curves overall.
@internal
class DoubleMapper {
  final Float32List _sourceValues;
  final Float32List _targetValues;

  DoubleMapper([List<(double, double)> mappings = const []])
    : _sourceValues = Float32List(mappings.length),
      _targetValues = Float32List(mappings.length) {
    for (final (i, (from, to)) in mappings.indexed) {
      _sourceValues[i] = from;
      _targetValues[i] = to;
    }
    // Both source values and target values should be monotonically increasing, with the
    // exception of maybe one time (since progress wraps around).
    validateProgress(_sourceValues);
    validateProgress(_targetValues);
  }

  double map(double x) => linearMap(_sourceValues, _targetValues, x);

  double mapBack(double x) => linearMap(_targetValues, _sourceValues, x);

  static final identity = DoubleMapper([
    // We need any 2 points in the (x, x) diagonal, with x in the [0, 1) range,
    // We spread them as much as possible to minimize float errors.
    (0, 0), (0.5, 0.5),
  ]);
}

/// Verify that a list of progress values are all in the range [0.0, 1.0) and is monotonically
/// increasing, with the exception of maybe one time in which the progress wraps around.
///
/// This check needs to include all pairs of consecutive elements in the list plus the last to first element
/// pair.
///
/// For example: (0.0, 0.3, 0.6) is a valid list, so are (0.3, 0.6, 0.0) and (0.6, 0.3, 0.0).
///
/// On the other hand, something like (0.5, 0.0, 0.7) is not (since it goes down twice, from 0.5 to
/// 0.0 and then from to 0.7 to 0.5).
///
/// Throws an [InvalidProgressException] if the checks fail.
@internal
void validateProgress(Float32List p) {
  var prev = p.last;
  var wraps = 0;
  for (final curr in p) {
    if (curr < 0 || curr >= 1) {
      throw InvalidProgressException(
        "FloatMapping - Progress outside of range: $p",
      );
    }
    if (progressDistance(curr, prev) <= distanceEpsilon) {
      throw InvalidProgressException(
        "FloatMapping - Progress repeats a value: $p",
      );
    }
    if (curr < prev) {
      wraps++;
      if (wraps > 1) {
        throw InvalidProgressException(
          "FloatMapping - Progress wraps more than once: $p",
        );
      }
    }
    prev = curr;
  }
}

class InvalidProgressException implements Exception {
  const InvalidProgressException(this.message);

  final String message;

  @override
  String toString() => 'InvalidProgressException: $message';
}

// Distance between two progress values.
// Since progress wraps around, we consider a difference of 0.99 as a distance of 0.01
@internal
double progressDistance(double p1, double p2) {
  final it = (p1 - p2).abs();
  return min(it, 1.0 - it);
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
