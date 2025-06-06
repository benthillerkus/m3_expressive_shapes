// Ported from RoundedPolygonTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/RoundedPolygonTest.kt
// See original license at the end of this file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  const rounding = CornerRounding(radius: .1);
  const perVtxRounded = [rounding, rounding, rounding, rounding];

  group("num verts constructor", () {
    test("throws for too few vertices", () {
      expect(() => RoundedPolygon.fromNumVerts(2), throwsArgumentError);
    });

    test("square in bounds", () {
      final square = RoundedPolygon.fromNumVerts(4);
      expect(square.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("double square in bounds", () {
      final doubleSquare = RoundedPolygon.fromNumVerts(4, radius: 2);
      expect(doubleSquare.cubics, shapeListWithinBounds(const Rect.fromLTRB(-2, -2, 2, 2)));
    });

    test("square rounded in bounds", () {
      final squareRounded = RoundedPolygon.fromNumVerts(4, rounding: rounding);
      expect(squareRounded.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("square per vertex rounded in bounds", () {
      final squarePVRounded = RoundedPolygon.fromNumVerts(4, perVertexRounding: perVtxRounded);
      expect(squarePVRounded.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });
  });

  group("vertices constructor", () {
    const p0 = Offset(1, 0);
    const p1 = Offset(0, 1);
    const p2 = Offset(-1, 0);
    const p3 = Offset(0, -1);
    final verts = Float32List.fromList([p0.dx, p0.dy, p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy]);

    test("throws for too few vertices", () {
      expect(
        () => RoundedPolygon.fromVertices(Float32List.fromList([p0.dx, p0.dy, p1.dx, p1.dy])),
        throwsArgumentError,
      );
    });

    test("manual square", () {
      final manualSquare = RoundedPolygon.fromVertices(verts);
      expect(manualSquare.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("manual square with offset", () {
      const offset = Offset(1, 2);
      final offsetVerts = Float32List.fromList([
        p0.dx + offset.dx,
        p0.dy + offset.dy,
        p1.dx + offset.dx,
        p1.dy + offset.dy,
        p2.dx + offset.dx,
        p2.dy + offset.dy,
        p3.dx + offset.dx,
        p3.dy + offset.dy,
      ]);
      final manualSquareOffset = RoundedPolygon.fromVertices(offsetVerts, centerX: offset.dx, centerY: offset.dy);
      expect(manualSquareOffset.cubics, shapeListWithinBounds(const Rect.fromLTRB(0, 1, 2, 3)));
    });

    test("manual square rounded", () {
      final manualSquareRounded = RoundedPolygon.fromVertices(verts, rounding: rounding);
      expect(manualSquareRounded.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("manual square per vertex rounded", () {
      final manualSquarePVRounded = RoundedPolygon.fromVertices(verts, perVertexRounding: perVtxRounded);
      expect(manualSquarePVRounded.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });
  });

  group("features constructor", () {
    test("throws for too few features", () {
      expect(() => RoundedPolygon.fromFeatures([]), throwsArgumentError);
      final corner = Corner([Cubic2D.empty(0, 0)]);
      expect(() => RoundedPolygon.fromFeatures([corner]), throwsArgumentError);
    });

    test("throws for non-continuous features", () {
      final cubic1 = Cubic2D.straightLine(0, 0, 1, 0);
      final cubic2 = Cubic2D.straightLine(10, 10, 20, 20);
      expect(
        () => RoundedPolygon.fromFeatures([Feature.buildEdge(cubic1), Feature.buildEdge(cubic2)]),
        throwsArgumentError,
      );
    });

    throw UnimplementedError("Needs Shapes to be implemented");

    // test("reconstructs square", () {
    //   final base = RoundedPolygon.rectangle();
    //   final actual = RoundedPolygon.fromFeatures(base.features);
    //   expect(base, roundedPolygonMoreOrLessEquals(actual));
    // });
  });
}

// package androidx.graphics.shapes

// import androidx.test.filters.SmallTest
// import org.junit.Assert.assertEquals
// import org.junit.Assert.assertThrows
// import org.junit.Test

// @SmallTest
// class RoundedPolygonTest {

//     val rounding = CornerRounding(.1f)
//     val perVtxRounded = listOf(rounding, rounding, rounding, rounding)

//     @Test
//     fun numVertsConstructorTest() {
//         assertThrows(IllegalArgumentException::class.java) { RoundedPolygon(2) }

//         val square = RoundedPolygon(4)
//         var min = Point(-1f, -1f)
//         var max = Point(1f, 1f)
//         assertInBounds(square.cubics, min, max)

//         val doubleSquare = RoundedPolygon(4, 2f)
//         min *= 2f
//         max *= 2f
//         assertInBounds(doubleSquare.cubics, min, max)

//         val squareRounded = RoundedPolygon(4, rounding = rounding)
//         min = Point(-1f, -1f)
//         max = Point(1f, 1f)
//         assertInBounds(squareRounded.cubics, min, max)

//         val squarePVRounded = RoundedPolygon(4, perVertexRounding = perVtxRounded)
//         min = Point(-1f, -1f)
//         max = Point(1f, 1f)
//         assertInBounds(squarePVRounded.cubics, min, max)
//     }

//     @Test
//     fun verticesConstructorTest() {
//         val p0 = Point(1f, 0f)
//         val p1 = Point(0f, 1f)
//         val p2 = Point(-1f, 0f)
//         val p3 = Point(0f, -1f)
//         val verts = floatArrayOf(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)

//         assertThrows(IllegalArgumentException::class.java) {
//             RoundedPolygon(floatArrayOf(p0.x, p0.y, p1.x, p1.y))
//         }

//         val manualSquare = RoundedPolygon(verts)
//         var min = Point(-1f, -1f)
//         var max = Point(1f, 1f)
//         assertInBounds(manualSquare.cubics, min, max)

//         val offset = Point(1f, 2f)
//         val offsetVerts =
//             floatArrayOf(
//                 p0.x + offset.x,
//                 p0.y + offset.y,
//                 p1.x + offset.x,
//                 p1.y + offset.y,
//                 p2.x + offset.x,
//                 p2.y + offset.y,
//                 p3.x + offset.x,
//                 p3.y + offset.y,
//             )
//         val manualSquareOffset = RoundedPolygon(offsetVerts, centerX = offset.x, centerY = offset.y)
//         min = Point(0f, 1f)
//         max = Point(2f, 3f)
//         assertInBounds(manualSquareOffset.cubics, min, max)

//         val manualSquareRounded = RoundedPolygon(verts, rounding = rounding)
//         min = Point(-1f, -1f)
//         max = Point(1f, 1f)
//         assertInBounds(manualSquareRounded.cubics, min, max)

//         val manualSquarePVRounded = RoundedPolygon(verts, perVertexRounding = perVtxRounded)
//         min = Point(-1f, -1f)
//         max = Point(1f, 1f)
//         assertInBounds(manualSquarePVRounded.cubics, min, max)
//     }

//     @Test
//     fun featuresConstructorThrowsForTooFewFeatures() {
//         assertThrows(IllegalArgumentException::class.java) { RoundedPolygon(listOf()) }
//         val corner = Feature.Corner(listOf(Cubic.empty(0f, 0f)))
//         assertThrows(IllegalArgumentException::class.java) { RoundedPolygon(listOf(corner)) }
//     }

//     @Test
//     fun featuresConstructorThrowsForNonContinuousFeatures() {
//         val cubic1 = Cubic.straightLine(0f, 0f, 1f, 0f)
//         val cubic2 = Cubic.straightLine(10f, 10f, 20f, 20f)
//         assertThrows(IllegalArgumentException::class.java) {
//             RoundedPolygon(listOf(Feature.buildEdge(cubic1), Feature.buildEdge(cubic2)))
//         }
//     }

//     @Test
//     fun featuresConstructorReconstructsSquare() {
//         val base = RoundedPolygon.rectangle()
//         val actual = RoundedPolygon(base.features)
//         assertPolygonsEqualish(base, actual)
//     }

//     @Test
//     fun featuresConstructorReconstructsRoundedSquare() {
//         val base = RoundedPolygon.rectangle(rounding = CornerRounding(0.5f, 0.2f))
//         val actual = RoundedPolygon(base.features)
//         assertPolygonsEqualish(base, actual)
//     }

//     @Test
//     fun featuresConstructorReconstructsCircles() {
//         for (i in 3..20) {
//             val base = RoundedPolygon.circle(i)
//             val actual = RoundedPolygon(base.features)
//             assertPolygonsEqualish(base, actual)
//         }
//     }

//     @Test
//     fun featuresConstructorReconstructsStars() {
//         for (i in 3..20) {
//             val base = RoundedPolygon.star(i)
//             val actual = RoundedPolygon(base.features)
//             assertPolygonsEqualish(base, actual)
//         }
//     }

//     @Test
//     fun featuresConstructorReconstructsRoundedStars() {
//         for (i in 3..20) {
//             val base = RoundedPolygon.star(i, rounding = CornerRounding(0.5f, 0.2f))
//             val actual = RoundedPolygon(base.features)
//             assertPolygonsEqualish(base, actual)
//         }
//     }

//     @Test
//     fun featuresConstructorReconstructsPill() {
//         val base = RoundedPolygon.pill()
//         val actual = RoundedPolygon(base.features)
//         assertPolygonsEqualish(base, actual)
//     }

//     @Test
//     fun featuresConstructorReconstructsPillStar() {
//         val base = RoundedPolygon.pillStar(rounding = CornerRounding(0.5f, 0.2f))
//         val actual = RoundedPolygon(base.features)
//         assertPolygonsEqualish(base, actual)
//     }

//     @Test
//     fun computeCenterTest() {
//         val polygon = RoundedPolygon(floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f))

//         assertEquals(0.5f, polygon.centerX, 1e-4f)
//         assertEquals(0.5f, polygon.centerY, 1e-4f)
//     }

//     private fun pointsToFloats(points: List<Point>): FloatArray {
//         val result = FloatArray(points.size * 2)
//         var index = 0
//         for (point in points) {
//             result[index++] = point.x
//             result[index++] = point.y
//         }
//         return result
//     }

//     @Test
//     fun roundingSpaceUsageTest() {
//         val p0 = Point(0f, 0f)
//         val p1 = Point(1f, 0f)
//         val p2 = Point(0.5f, 1f)
//         val pvRounding =
//             listOf(CornerRounding(1f, 0f), CornerRounding(1f, 1f), CornerRounding.Unrounded)
//         val polygon =
//             RoundedPolygon(
//                 vertices = pointsToFloats(listOf(p0, p1, p2)),
//                 perVertexRounding = pvRounding,
//             )

//         // Since there is not enough room in the p0 -> p1 side even for the roundings, we shouldn't
//         // take smoothing into account, so the corners should end in the middle point.
//         val lowerEdgeFeature = polygon.features.first { it is Feature.Edge } as Feature.Edge
//         assertEquals(1, lowerEdgeFeature.cubics.size)

//         val lowerEdge = lowerEdgeFeature.cubics.first()
//         assertEqualish(0.5f, lowerEdge.anchor0X)
//         assertEqualish(0.0f, lowerEdge.anchor0Y)
//         assertEqualish(0.5f, lowerEdge.anchor1X)
//         assertEqualish(0.0f, lowerEdge.anchor1Y)
//     }

//     /*
//      * In the following tests, we check how much was cut for the top left (vertex 0) and bottom
//      * left corner (vertex 3).
//      * In particular, both vertex are competing for space in the left side.
//      *
//      *   Vertex 0            Vertex 1
//      *      *---------------------*
//      *      |                     |
//      *      *---------------------*
//      *   Vertex 3            Vertex 2
//      */
//     private val points = 20

//     @Test
//     fun unevenSmoothingTest() {
//         // Vertex 3 has the default 0.5 radius, 0 smoothing.
//         // Vertex 0 has 0.4 radius, and smoothing varying from 0 to 1.
//         repeat(points + 1) {
//             val smooth = it.toFloat() / points
//             doUnevenSmoothTest(
//                 CornerRounding(0.4f, smooth),
//                 expectedV0SX = 0.4f * (1 + smooth),
//                 expectedV0SY = (0.4f * (1 + smooth)).coerceAtMost(0.5f),
//                 expectedV3SY = 0.5f,
//             )
//         }
//     }

//     @Test
//     fun unevenSmoothingTest2() {
//         // Vertex 3 has 0.2f radius and 0.2f smoothing, so it takes at most 0.4f
//         // Vertex 0 has 0.4f radius and smoothing varies from 0 to 1, when it reaches 0.5 it starts
//         // competing with vertex 3 for space.
//         repeat(points + 1) {
//             val smooth = it.toFloat() / points

//             val smoothWantedV0 = 0.4f * smooth
//             val smoothWantedV3 = 0.2f

//             // There is 0.4f room for smoothing
//             val factor = (0.4f / (smoothWantedV0 + smoothWantedV3)).coerceAtMost(1f)
//             doUnevenSmoothTest(
//                 CornerRounding(0.4f, smooth),
//                 expectedV0SX = 0.4f * (1 + smooth),
//                 expectedV0SY = 0.4f + factor * smoothWantedV0,
//                 expectedV3SY = 0.2f + factor * smoothWantedV3,
//                 rounding3 = CornerRounding(0.2f, 1f),
//             )
//         }
//     }

//     @Test
//     fun unevenSmoothingTest3() {
//         // Vertex 3 has 0.6f radius.
//         // Vertex 0 has 0.4f radius and smoothing varies from 0 to 1. There is no room for smoothing
//         // on the segment between these vertices, but vertex 0 can still have smoothing on the top
//         // side.
//         repeat(points + 1) {
//             val smooth = it.toFloat() / points

//             doUnevenSmoothTest(
//                 CornerRounding(0.4f, smooth),
//                 expectedV0SX = 0.4f * (1 + smooth),
//                 expectedV0SY = 0.4f,
//                 expectedV3SY = 0.6f,
//                 rounding3 = CornerRounding(0.6f),
//             )
//         }
//     }

//     @Test
//     fun creatingFullSizeTest() {
//         val radius = 400f
//         val innerRadiusFactor = 0.35f
//         val innerRadius = radius * innerRadiusFactor
//         val roundingFactor = 0.32f

//         val fullSizeShape =
//             RoundedPolygon.star(
//                     numVerticesPerRadius = 4,
//                     radius,
//                     innerRadius,
//                     rounding = CornerRounding(radius * roundingFactor),
//                     innerRounding = CornerRounding(radius * roundingFactor),
//                     centerX = radius,
//                     centerY = radius,
//                 )
//                 .transformed { x, y ->
//                     TransformResult((x - radius) / radius, (y - radius) / radius)
//                 }

//         val canonicalShape =
//             RoundedPolygon.star(
//                 numVerticesPerRadius = 4,
//                 1f,
//                 innerRadiusFactor,
//                 rounding = CornerRounding(roundingFactor),
//                 innerRounding = CornerRounding(roundingFactor),
//             )

//         val cubics = canonicalShape.cubics
//         val cubics1 = fullSizeShape.cubics
//         assertEquals(cubics.size, cubics1.size)
//         cubics.zip(cubics1).forEach { (cubic, cubic1) ->
//             assertEqualish(cubic.anchor0X, cubic1.anchor0X)
//             assertEqualish(cubic.anchor0Y, cubic1.anchor0Y)
//             assertEqualish(cubic.anchor1X, cubic1.anchor1X)
//             assertEqualish(cubic.anchor1Y, cubic1.anchor1Y)
//             assertEqualish(cubic.control0X, cubic1.control0X)
//             assertEqualish(cubic.control0Y, cubic1.control0Y)
//             assertEqualish(cubic.control1X, cubic1.control1X)
//             assertEqualish(cubic.control1Y, cubic1.control1Y)
//         }
//     }

//     private fun doUnevenSmoothTest(
//         // Corner rounding parameter for vertex 0 (top left)
//         rounding0: CornerRounding,
//         expectedV0SX: Float, // Expected total cut from vertex 0 towards vertex 1
//         expectedV0SY: Float, // Expected total cut from vertex 0 towards vertex 3
//         expectedV3SY: Float, // Expected total cut from vertex 3 towards vertex 0
//         // Corner rounding parameter for vertex 3 (bottom left)
//         rounding3: CornerRounding = CornerRounding(0.5f),
//     ) {
//         val p0 = Point(0f, 0f)
//         val p1 = Point(5f, 0f)
//         val p2 = Point(5f, 1f)
//         val p3 = Point(0f, 1f)

//         val pvRounding =
//             listOf(rounding0, CornerRounding.Unrounded, CornerRounding.Unrounded, rounding3)
//         val polygon =
//             RoundedPolygon(
//                 vertices = pointsToFloats(listOf(p0, p1, p2, p3)),
//                 perVertexRounding = pvRounding,
//             )
//         val (e01, _, _, e30) = polygon.features.filterIsInstance<Feature.Edge>()
//         val msg = "r0 = ${show(rounding0)}, r3 = ${show(rounding3)}"
//         assertEqualish(expectedV0SX, e01.cubics.first().anchor0X, msg)
//         assertEqualish(expectedV0SY, e30.cubics.first().anchor1Y, msg)
//         assertEqualish(expectedV3SY, 1f - e30.cubics.first().anchor0Y, msg)
//     }

//     private fun show(cr: CornerRounding) = "(r=${cr.radius}, s=${cr.smoothing})"
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
