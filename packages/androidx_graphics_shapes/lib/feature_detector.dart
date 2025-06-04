// Ported from FeatureDetector.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/FeatureDetector.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/utils.dart';
import 'package:meta/meta.dart';

import 'cubic.dart';
import 'features.dart';

/// Convert cubics to Features in a 1:1 mapping of [Cubic.asFeature] unless
/// - two subsequent cubics are not continuous, in which case an empty corner needs to be added in
///   between. Example for C1, C2: /C1\/C2\ -> /C\C/C\.
/// - multiple subsequent cubics can be expressed as a single feature. Example for C1, C2:
///   --C1----C2-- -> -----E----. One exception to the latter rule is for the first and last cubic,
///   that remain the same in order to persist the start position. Assumes the list of cubics is
///   continuous.
@internal
List<Feature> detectFeatures(List<Cubic2D> cubics) {
  if (cubics.isEmpty) return const [];

  // TODO: b/372651969 Try different heuristics for corner grouping
  final res = List<Feature>.empty(growable: true);
  Cubic2D current = cubics.first;

  // Do one roundabout in which (current == last, next == first) is the last iteration.
  // Just like a snowball, subsequent cubics that align to one feature merge until
  // the streak breaks, the result is added, and a new streak starts.
  for (int i = 0; i < cubics.length; i++) {
    final next = cubics[(i + 1) % (cubics.length)];

    if (i < (cubics.length - 1) && current.alignsIshWith(next)) {
      current = current.extend(next);
      continue;
    }

    res.add(current.asFeature(next));

    if (!current.smoothesIntoIsh(next)) {
      res.add(
        Cubic2D.empty(current.anchor1X, current.anchor1Y).asFeature(next),
      );
    }

    current = next;
  }
  return res;
}

extension on Cubic2D {
  /// Convert to [Feature.Edge] if this cubic describes a straight line, otherwise to a
  /// [Feature.Corner]. Corner convexity is determined by [convex].
  Feature asFeature(Cubic2D next) =>
      straightIsh() ? Edge([this]) : Corner([this], convex: convexTo(next));

  /// Determine if the cubic is close to a straight line. Empty cubics don't count as straightIsh.
  bool straightIsh() =>
      !zeroLength &&
      collinearIsh(
        anchor0X,
        anchor0Y,
        anchor1X,
        anchor1Y,
        control0X,
        control0Y,
        tolerance: relaxedDistanceEpsilon,
      ) &&
      collinearIsh(
        anchor0X,
        anchor0Y,
        anchor1X,
        anchor1Y,
        control1X,
        control1Y,
        tolerance: relaxedDistanceEpsilon,
      );

  /// Determines if next is a smooth continuation of this cubic. Smooth meaning that the first control
  /// point of next is a reflection of this' second control point, similar to the S/s or t/T command in
  /// svg paths https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths#b%C3%A9zier_curves
  bool smoothesIntoIsh(Cubic2D next) => collinearIsh(
    control1X,
    control1Y,
    next.control0X,
    next.control0Y,
    anchor1X,
    anchor1Y,
    tolerance: relaxedDistanceEpsilon,
  );

  /// Determines if all of this' points align with next's points. For straight lines, this is the same
  /// as if next was a continuation of this.
  bool alignsIshWith(Cubic2D next) =>
      straightIsh() && next.straightIsh() && smoothesIntoIsh(next) ||
      zeroLength ||
      next.zeroLength;

  /// Create a new cubic by extending A to B's second anchor point
  Cubic2D extend(Cubic2D other) => zeroLength
      ? Cubic2D(
          anchor0X,
          anchor0Y,
          other.control0X,
          other.control0Y,
          other.control1X,
          other.control1Y,
          other.anchor1X,
          other.anchor1Y,
        )
      : Cubic2D(
          anchor0X,
          anchor0Y,
          control0X,
          control0Y,
          control1X,
          control1Y,
          other.anchor1X,
          other.anchor1Y,
        );
}

/*
 * Copyright 2024 The Android Open Source Project
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
