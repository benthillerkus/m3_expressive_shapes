// Ported from TestUtils.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/TestUtils.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const epsilon = 1e-4;

Matcher cubic2DMoreOrLessEquals(Cubic2D value, {double epsilon = epsilon}) {
  return allOf(
    isA<Cubic2D>(),
    _HasAnchor0(offsetMoreOrLessEquals(value.anchor0, epsilon: epsilon)),
    _HasControl0(offsetMoreOrLessEquals(value.control0, epsilon: epsilon)),
    _HasControl1(offsetMoreOrLessEquals(value.control1, epsilon: epsilon)),
    _HasAnchor1(offsetMoreOrLessEquals(value.anchor1, epsilon: epsilon)),
  );
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.anchor0].
class _HasAnchor0 extends CustomMatcher {
  _HasAnchor0(Matcher matcher) : super('Cubic2D with anchor0', 'anchor0', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).anchor0;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.control0].
class _HasControl0 extends CustomMatcher {
  _HasControl0(Matcher matcher) : super('Cubic2D with control0', 'control0', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).control0;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.control1].
class _HasControl1 extends CustomMatcher {
  _HasControl1(Matcher matcher) : super('Cubic2D with control1', 'control1', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).control1;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.anchor1].
class _HasAnchor1 extends CustomMatcher {
  _HasAnchor1(Matcher matcher) : super('Cubic2D with anchor1', 'anchor1', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).anchor1;
}

Matcher cubic2DListMoreOrLessEquals(List<Cubic2D> expected, {double epsilon = epsilon}) {
  return allOf(
    isA<List<Cubic2D>>(),
    hasLength(expected.length),
    pairwiseCompare(expected, (a, b) {
      return cubic2DMoreOrLessEquals(a, epsilon: epsilon).matches(b, {});
    }, "Cubic2D more or less equals (within $epsilon)"),
  );
}

/// Lens for [Feature] to focus on its cubics.
class _HasCubic2DList extends CustomMatcher {
  _HasCubic2DList(Matcher matcher) : super('List<Cubic2D> with cubics', 'cubics', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Feature).cubics;
}

class _IfBothAreCornersIsConvexSame extends CustomMatcher {
  _IfBothAreCornersIsConvexSame(Feature other)
    : super('Feature with isConvex', 'isConvex', equals(other is Corner ? other.convex : null));

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is Corner) return actual.convex;

    return null; // Not applicable for non-Corner features.
  }
}

Matcher featureMoreOrLessEquals(Feature expected, {double epsilon = epsilon}) {
  return allOf(
    isA<Feature>(),
    _HasCubic2DList(cubic2DListMoreOrLessEquals(expected.cubics, epsilon: epsilon)),
    _IfBothAreCornersIsConvexSame(expected),
  );
}

// internal fun assertPolygonsEqualish(expected: RoundedPolygon, actual: RoundedPolygon) {
//     assertCubicListsEqualish(expected.cubics, actual.cubics)

//     assertEquals(expected.features.size, actual.features.size)
//     for (i in expected.features.indices) {
//         assertFeaturesEqualish(expected.features[i], actual.features[i])
//     }
// }

class _HasDx extends CustomMatcher {
  _HasDx(Matcher matcher) : super('Offset with dx', 'dx', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Offset).dx;
}

class _HasDy extends CustomMatcher {
  _HasDy(Matcher matcher) : super('Offset with dy', 'dy', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Offset).dy;
}

Matcher offsetGreaterish(Offset other, {double epsilon = epsilon}) {
  return allOf(
    isA<Offset>(),
    _HasDx(greaterThanOrEqualTo(other.dx - epsilon)),
    _HasDy(greaterThanOrEqualTo(other.dy - epsilon)),
  );
}

Matcher offsetLessish(Offset other, {double epsilon = epsilon}) {
  return allOf(
    isA<Offset>(),
    _HasDx(lessThanOrEqualTo(other.dx + epsilon)),
    _HasDy(lessThanOrEqualTo(other.dy + epsilon)),
  );
}

Matcher offsetWithinRect(Rect rect) {
  return allOf(
    isA<Offset>(),
    _HasDx(greaterThanOrEqualTo(rect.left)),
    _HasDx(lessThan(rect.right)),
    _HasDy(greaterThanOrEqualTo(rect.top)),
    _HasDy(lessThan(rect.bottom)),
  );
}

Matcher shapeListWithinRect(Rect bounds) {
  return allOf(
    isA<List<Cubic2D>>(),
    everyElement(
      allOf(
        _HasAnchor0(offsetWithinRect(bounds)),
        _HasControl0(offsetWithinRect(bounds)),
        _HasControl1(offsetWithinRect(bounds)),
        _HasAnchor1(offsetWithinRect(bounds)),
      ),
    ),
  );
}

ktTransformResult identityTransform(double x, double y) => (x: x, y: y);

ktTransformResult Function(double, double) pointRotator(double angle) {
  final matrix = Matrix4.rotationZ(angle);
  return (x, y) {
    final point = matrix * [x, y, 0, 1];
    return (x: point.x, y: point.y);
  };
}

ktTransformResult Function(double, double) scaleTransform(double sx, double sy) {
  return (x, y) {
    return (x: x * sx, y: y * sy);
  };
}

ktTransformResult Function(double, double) translateTransform(double dx, double dy) {
  return (x, y) {
    return (x: x + dx, y: y + dy);
  };
}

// internal fun assertBitmapsEqual(b0: Bitmap, b1: Bitmap) {
//     assertEquals(b0.width, b1.width)
//     assertEquals(b0.height, b1.height)
//     for (row in 0 until b0.height) {
//         for (col in 0 until b0.width) {
//             assertEquals("Pixels at ($col, $row) not equal", b0.get(col, row), b1.get(col, row))
//         }
//     }
// }

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
