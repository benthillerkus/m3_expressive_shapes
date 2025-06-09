// Ported from ShapesTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/ShapesTest.kt
// See original license at the end of this file.

import 'dart:ui';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  group("circle tests", () {
    test("default circle", () {
      final circle = RoundedPolygon.circle();
      expect(circle.cubics, isCircleShape());
    });

    test("simple circle with radius", () {
      final circle = RoundedPolygon.circle(radius: 3);
      expect(circle.cubics, isCircleShape(radius: 3));
    });

    test("complex circle with many segments", () {
      final circle = RoundedPolygon.circle(numVertices: 20);
      expect(circle.cubics, isCircleShape());
    });

    test("big circle with radius", () {
      final bigCircle = RoundedPolygon.circle(radius: 3);
      expect(bigCircle.cubics, isCircleShape(radius: 3));
    });

    test("offset circle", () {
      final center = const Offset(1, 2);
      final offsetCircle = RoundedPolygon.circle(centerX: center.dx, centerY: center.dy);
      expect(offsetCircle.cubics, isCircleShape(center: center));
    });
  });

  /**
   * Stars are complicated. For the unrounded version, we can check whether the vertices are the
   * right distance from the center. For the rounded versions, just check that the shape is within
   * the appropriate bounds.
   */
  group("star tests", () {
    test("star with inner radius", () {
      final star = RoundedPolygon.star(4, innerRadius: 0.5);
      final shape = star.cubics;
      final radius = 1.0;
      final innerRadius = 0.5;
      for (final cubic in shape) {
        expect(cubic, isCubicOnRadii(radius, radius2: innerRadius));
      }
    });

    test("offset star", () {
      final center = const Offset(1, 2);
      final star = RoundedPolygon.star(4, innerRadius: 0.5, centerX: center.dx, centerY: center.dy);
      final shape = star.cubics;
      for (final cubic in shape) {
        expect(cubic, isCubicOnRadii(1, radius2: 0.5, center: center));
      }
    });

    test("star with larger radii", () {
      final radius = 4.0;
      final innerRadius = 2.0;
      final star = RoundedPolygon.star(4, radius: radius, innerRadius: innerRadius);
      final shape = star.cubics;
      for (final cubic in shape) {
        expect(cubic, isCubicOnRadii(radius, radius2: innerRadius));
      }
    });
  });

  group("rounded star tests", () {
    final rounding = const CornerRounding(radius: 0.1);
    final innerRounding = const CornerRounding(radius: 0.2);
    final perVertexRounded = [
      rounding,
      innerRounding,
      rounding,
      innerRounding,
      rounding,
      innerRounding,
      rounding,
      innerRounding,
    ];

    test("star with rounding", () {
      final star = RoundedPolygon.star(4, innerRadius: 0.5, rounding: rounding);
      expect(star.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("star with inner rounding", () {
      final star = RoundedPolygon.star(4, innerRadius: 0.5, innerRounding: innerRounding);
      expect(star.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("star with both roundings", () {
      final star = RoundedPolygon.star(
        4,
        innerRadius: 0.5,
        rounding: rounding,
        innerRounding: innerRounding,
      );
      expect(star.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("star with per-vertex rounding", () {
      final star = RoundedPolygon.star(4, innerRadius: 0.5, perVertexRounding: perVertexRounded);
      expect(star.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("star with invalid per-vertex rounding", () {
      expect(
        () => RoundedPolygon.star(6, innerRadius: 0.5, perVertexRounding: perVertexRounded),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

const epsilon = 0.01;

Matcher hasDistanceFrom(Offset point, double distance, {double epsilon = epsilon}) {
  return isA<Offset>().having(
    (offset) => (offset - point).distance,
    'distance from $point',
    closeTo(distance, epsilon),
  );
}

/// Test that the given point is radius distance away from [center]. If two radii are provided it
/// is sufficient to lie on either one (used for testing points on stars).
Matcher isPointOnRadii(
  double radius1, {
  double? radius2,
  Offset center = Offset.zero,
  double epsilon = epsilon,
}) {
  return anyOf(
    hasDistanceFrom(center, radius1, epsilon: epsilon),
    (radius2 != null) ? hasDistanceFrom(center, radius2, epsilon: epsilon) : isNot(anything),
  );
}

Matcher isCubicOnRadii(double radius1, {double? radius2, Offset center = Offset.zero}) {
  return allOf(
    isA<Cubic2D>(),
    HasAnchor0(isPointOnRadii(radius1, radius2: radius2, center: center)),
    HasAnchor1(isPointOnRadii(radius1, radius2: radius2, center: center)),
  );
}

/// Tests points along the curve of the cubic by comparing the distance from that point to the
/// center, compared to the requested radius. The test is very lenient since the Circle shape is
/// only a 4x cubic approximation of the circle and varies from the true circle.
Matcher isCircularCubic(double radius, Offset center, {double epsilon = epsilon}) {
  var matcher = isA<Cubic2D>();
  for (double t = 0; t <= 1; t += .1) {
    matcher = matcher.having(
      (cubic) => cubic.transform(t),
      'evaluated at $t',
      isPointOnRadii(radius, center: center, epsilon: epsilon),
    );
  }
  return matcher;
}

/// Matcher for a [List<Cubic2D>] that represents a circle shape.
Matcher isCircleShape({double radius = 1, Offset center = Offset.zero, double epsilon = epsilon}) {
  return allOf(
    isA<List<Cubic2D>>(),
    everyElement(isCircularCubic(radius, center, epsilon: epsilon)),
  );
}

// package androidx.graphics.shapes

// import androidx.test.filters.SmallTest
// import kotlin.AssertionError
// import kotlin.math.sqrt
// import org.junit.Assert
// import org.junit.Assert.assertEquals
// import org.junit.Assert.assertThrows
// import org.junit.Test

// /** Tests the utility shape-creating functions like Circle and Star */
// @SmallTest
// class ShapesTest {

//     private val Zero = Point(0f, 0f)
//     val Epsilon = .01f

//     private fun distance(start: Point, end: Point): Float {
//         val vector = end - start
//         return sqrt(vector.x * vector.x + vector.y * vector.y)
//     }

//     /**
//      * Test that the given point is radius distance away from [center]. If two radii are provided it
//      * is sufficient to lie on either one (used for testing points on stars).
//      */
//     private fun assertPointOnRadii(
//         point: Point,
//         radius1: Float,
//         radius2: Float = radius1,
//         center: Point = Zero,
//     ) {
//         val dist = distance(center, point)
//         try {
//             assertEquals(radius1, dist, Epsilon)
//         } catch (e: AssertionError) {
//             assertEquals(radius2, dist, Epsilon)
//         }
//     }

//     private fun assertCubicOnRadii(
//         cubic: Cubic,
//         radius1: Float,
//         radius2: Float = radius1,
//         center: Point = Zero,
//     ) {
//         assertPointOnRadii(Point(cubic.anchor0X, cubic.anchor0Y), radius1, radius2, center)
//         assertPointOnRadii(Point(cubic.anchor1X, cubic.anchor1Y), radius1, radius2, center)
//     }

//     /**
//      * Tests points along the curve of the cubic by comparing the distance from that point to the
//      * center, compared to the requested radius. The test is very lenient since the Circle shape is
//      * only a 4x cubic approximation of the circle and varies from the true circle.
//      */
//     private fun assertCircularCubic(cubic: Cubic, radius: Float, center: Point) {
//         var t = 0f
//         while (t <= 1f) {
//             val pointOnCurve = cubic.pointOnCurve(t)
//             val distanceToPoint = distance(center, pointOnCurve)
//             assertEquals(radius, distanceToPoint, Epsilon)
//             t += .1f
//         }
//     }

//     private fun assertCircleShape(shape: List<Cubic>, radius: Float = 1f, center: Point = Zero) {
//         for (cubic in shape) {
//             assertCircularCubic(cubic, radius, center)
//         }
//     }

//     @Test
//     fun circleTest() {
//         Assert.assertThrows(IllegalArgumentException::class.java) { RoundedPolygon.circle(2) }

//         val circle = RoundedPolygon.circle()
//         assertCircleShape(circle.cubics)

//         val simpleCircle = RoundedPolygon.circle(3)
//         assertCircleShape(simpleCircle.cubics)

//         val complexCircle = RoundedPolygon.circle(20)
//         assertCircleShape(complexCircle.cubics)

//         val bigCircle = RoundedPolygon.circle(radius = 3f)
//         assertCircleShape(bigCircle.cubics, radius = 3f)

//         val center = Point(1f, 2f)
//         val offsetCircle = RoundedPolygon.circle(centerX = center.x, centerY = center.y)
//         assertCircleShape(offsetCircle.cubics, center = center)
//     }

//     /**
//      * Stars are complicated. For the unrounded version, we can check whether the vertices are the
//      * right distance from the center. For the rounded versions, just check that the shape is within
//      * the appropriate bounds.
//      */
//     @Test
//     fun starTest() {
//         var star = RoundedPolygon.star(4, innerRadius = .5f)
//         var shape = star.cubics
//         var radius = 1f
//         var innerRadius = .5f
//         for (cubic in shape) {
//             assertCubicOnRadii(cubic, radius, innerRadius)
//         }

//         val center = Point(1f, 2f)
//         star =
//             RoundedPolygon.star(
//                 4,
//                 innerRadius = innerRadius,
//                 centerX = center.x,
//                 centerY = center.y,
//             )
//         shape = star.cubics
//         for (cubic in shape) {
//             assertCubicOnRadii(cubic, radius, innerRadius, center)
//         }

//         radius = 4f
//         innerRadius = 2f
//         star = RoundedPolygon.star(4, radius, innerRadius)
//         shape = star.cubics
//         for (cubic in shape) {
//             assertCubicOnRadii(cubic, radius, innerRadius)
//         }
//     }

//     @Test
//     fun roundedStarTest() {
//         val rounding = CornerRounding(.1f)
//         val innerRounding = CornerRounding(.2f)
//         val perVtxRounded =
//             listOf<CornerRounding>(
//                 rounding,
//                 innerRounding,
//                 rounding,
//                 innerRounding,
//                 rounding,
//                 innerRounding,
//                 rounding,
//                 innerRounding,
//             )

//         var star = RoundedPolygon.star(4, innerRadius = .5f, rounding = rounding)
//         val min = Point(-1f, -1f)
//         val max = Point(1f, 1f)
//         assertInBounds(star.cubics, min, max)

//         star = RoundedPolygon.star(4, innerRadius = .5f, innerRounding = innerRounding)
//         assertInBounds(star.cubics, min, max)

//         star =
//             RoundedPolygon.star(
//                 4,
//                 innerRadius = .5f,
//                 rounding = rounding,
//                 innerRounding = innerRounding,
//             )
//         assertInBounds(star.cubics, min, max)

//         star = RoundedPolygon.star(4, innerRadius = .5f, perVertexRounding = perVtxRounded)
//         assertInBounds(star.cubics, min, max)

//         assertThrows(IllegalArgumentException::class.java) {
//             star = RoundedPolygon.star(6, innerRadius = .5f, perVertexRounding = perVtxRounded)
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
