// Ported from FeatureMappingTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FeatureMappingTest.kt
// See original license at the end of this file.

import 'dart:typed_data';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/feature_mapping.dart';
import 'package:androidx_graphics_shapes/polygon_measure.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  final triangleWithRoundings = RoundedPolygon.fromNumVerts(
    3,
    rounding: const CornerRounding(radius: 0.2),
  );
  final triangle = RoundedPolygon.fromNumVerts(3);
  final square = RoundedPolygon.fromNumVerts(4);
  final squareRotated = RoundedPolygon.fromNumVerts(4).ktTransformed(pointRotator(45));

  test('feature mapping triangles', () {
    expect(triangleWithRoundings, mappingDistance(triangle, everyElement(lessThan(.1))));
  });

  test('feature mapping triangle to square', () {
    expect(
      triangle,
      mappingDistance(
        square,
        allOf(
          // We have one exact match (both have points at 0 degrees), and 2 close ones
          hasLength(3),
          isA<List<double>>()
              .having((it) => it.first, "first", lessThan(.3))
              .having((it) => it.last, "last", lessThan(1e-6)),
          predicate((e) {
            final it = e! as List<double>;
            return closeTo(it[1], epsilon).matches(it.first, {});
          }, "first two elements are equalish"),
        ),
      ),
    );
  });

  test('feature mapping square to triangle', () {
    expect(
      square,
      mappingDistance(
        triangle,
        allOf(
          // We have one exact match (both have points at 0 degrees), and 2 close ones
          hasLength(3),
          isA<List<double>>()
              .having((it) => it.first, "first", lessThan(.3))
              .having((it) => it.last, "last", lessThan(1e-6)),
          predicate((e) {
            final it = e! as List<double>;
            return closeTo(it[1], epsilon).matches(it.first, {});
          }, "first two elements are equalish"),
        ),
      ),
    );
  });

  test("feature mapping rotated square to triangle", () {
    expect(
      squareRotated,
      mappingDistance(
        triangle,
        allOf(
          // We have a very bad mapping (the triangle vertex just in the middle of one of the
          // square's sides) and 2 decent ones.
          hasLength(3),
          isA<List<double>>()
              .having((it) => it.first, "first", greaterThan(.5))
              .having((it) => it.last, "last", lessThan(.1)),
          predicate((e) {
            final it = e! as List<double>;
            return closeTo(it[2], epsilon).matches(it[1], {});
          }, "last two elements are equalish"),
        ),
      ),
    );
  });

  test("feature mapping doesn't crash", () {
    // Verify that complicated shapes can be matched (this used to crash before).
    final checkmark = RoundedPolygon.fromVertices(
      Float32List.fromList([
        400,
        -304,
        240,
        -464,
        296,
        -520,
        400,
        -416,
        664,
        -680,
        720,
        -624,
        400,
        -304,
      ]),
    ).normalized();
    final verySunny = RoundedPolygon.star(
      8,
      innerRadius: .65,
      rounding: const CornerRounding(radius: .15),
    ).normalized();

    expect(
      checkmark,
      mappingDistance(
        verySunny,
        allOf(
          // Most vertices on the checkmark map to a feature in the second shape.
          hasLength(greaterThanOrEqualTo(6)),
          isA<List<double>>()
          // And they are close enough
          .having((it) => it.first, "first", lessThan(.15)),
        ),
      ),
    );
  });

  group("insertion index", () {
    test("a", () {
      final list = [0.1, 0.2, 0.3];
      final index = list.insertionIndex(0.15);
      expect(index, 1, reason: "0.15 should be inserted between 0.1 and 0.2");
      list.insert(index, 0.15);
      expect(
        list,
        containsAllInOrder(list.sorted((a, b) => a.compareTo(b))),
        reason: "List should be sorted after insertion",
      );
    });

    test("b", () {
      final list = [0.1, 0.2, 0.3];
      final index = list.insertionIndex(0.05);
      expect(index, 0, reason: "0.05 should be inserted at the start");
      list.insert(index, 0.05);
      expect(
        list,
        containsAllInOrder(list.sorted((a, b) => a.compareTo(b))),
        reason: "List should be sorted after insertion",
      );
    });

    test("c", () {
      final list = [0.1, 0.2, 0.3];
      final index = list.insertionIndex(0.35);
      expect(index, 3, reason: "0.35 should be inserted at the end");
      list.insert(index, 0.35);
      expect(
        list,
        containsAllInOrder(list.sorted((a, b) => a.compareTo(b))),
        reason: "List should be sorted after insertion",
      );
    });

    test("empty list", () {
      final list = <double>[];
      final index = list.insertionIndex(0.15);
      expect(index, 0, reason: "0.15 should be inserted at the start of an empty list");
      list.insert(index, 0.15);
      expect(list, [0.15], reason: "List should contain the inserted element");
    });

    test("throws on duplicate", () {
      final list = [0.1, 0.2, 0.3];
      expect(
        () => list.insertionIndex(0.2),
        throwsArgumentError,
        reason: "Should throw when trying to insert a duplicate element",
      );
    });
  });
}

// package androidx.graphics.shapes

// import org.junit.Test

// class FeatureMappingTest {
//     private val triangleWithRoundings = RoundedPolygon(3, rounding = CornerRounding(0.2f))
//     private val triangle = RoundedPolygon(3)
//     private val square = RoundedPolygon(4)
//     private val squareRotated = RoundedPolygon(4).transformed(pointRotator(45f))

//     @Test
//     fun featureMappingTriangles() =
//         verifyMapping(triangleWithRoundings, triangle) { distances ->
//             distances.forEach { assert(it < 0.1f) }
//         }

//     @Test
//     fun featureMappingTriangleToSquare() =
//         verifyMapping(triangle, square) { distances ->
//             // We have one exact match (both have points at 0 degrees), and 2 close ones
//             assert(distances.size == 3)
//             assertEqualish(distances[0], distances[1])
//             assert(distances[0] < 0.3f)
//             assert(distances[2] < 1e-6f)
//         }

//     @Test
//     fun featureMappingSquareToTriangle() =
//         verifyMapping(square, triangle) { distances ->
//             // We have one exact match (both have points at 0 degrees), and 2 close ones
//             assert(distances.size == 3)

//             assertEqualish(distances[0], distances[1])
//             assert(distances[0] < 0.3f)
//             assert(distances[2] < 1e-6f)
//         }

//     @Test
//     fun featureMappingSquareRotatedToTriangle() =
//         verifyMapping(squareRotated, triangle) { distances ->
//             // We have a very bad mapping (the triangle vertex just in the middle of one of the
//             // square's sides) and 2 decent ones.
//             assert(distances.size == 3)

//             assert(distances[0] > 0.5f)
//             assertEqualish(distances[1], distances[2])
//             assert(distances[2] < 0.1f)
//         }

//     @Test
//     fun featureMappingDoesntCrash() {
//         // Verify that complicated shapes can me matched (this used to crash before).
//         val checkmark =
//             RoundedPolygon(
//                     floatArrayOf(
//                         400f,
//                         -304f,
//                         240f,
//                         -464f,
//                         296f,
//                         -520f,
//                         400f,
//                         -416f,
//                         664f,
//                         -680f,
//                         720f,
//                         -624f,
//                         400f,
//                         -304f,
//                     )
//                 )
//                 .normalized()
//         val verySunny =
//             RoundedPolygon.star(
//                     numVerticesPerRadius = 8,
//                     innerRadius = .65f,
//                     rounding = CornerRounding(radius = .15f),
//                 )
//                 .normalized()
//         verifyMapping(checkmark, verySunny) {
//             // Most vertices on the checkmark map to a feature in the second shape.
//             assert(it.size >= 6)

//             // And they are close enough
//             assert(it[0] < 0.15f)
//         }
//     }

//     private fun verifyMapping(
//         p1: RoundedPolygon,
//         p2: RoundedPolygon,
//         validator: (List<Float>) -> Unit,
//     ) {
//         val f1 = MeasuredPolygon.measurePolygon(LengthMeasurer(), p1).features
//         val f2 = MeasuredPolygon.measurePolygon(LengthMeasurer(), p2).features

//         // Maps progress in p1 to progress in p2
//         val map = doMapping(f1, f2)

//         // See which features where actually mapped and the distance between their representative
//         // points
//         val distances = buildList {
//             map.forEach { (progress1, progress2) ->
//                 val feature1 = f1.find { it.progress == progress1 }!!
//                 val feature2 = f2.find { it.progress == progress2 }!!
//                 add(featureDistSquared(feature1.feature, feature2.feature))
//             }
//         }

//         validator(distances.sortedDescending())
//     }
// }

/// [matcher] needs to match on a [List<double>] of distances between features of the two polygons.
Matcher mappingDistance(RoundedPolygon other, Matcher matcher) {
  return isA<RoundedPolygon>().having(
    (it) {
      final f1 = MeasuredPolygon.measurePolygon(const LengthMeasurer(), it).features;
      final f2 = MeasuredPolygon.measurePolygon(const LengthMeasurer(), other).features;

      // Maps progress in it to progress in other
      final map = doMapping(f1, f2);

      // See which features were actually mapped and the distance between their representative
      // points
      final distances = map.map((entry) {
        final feature1 = f1.firstWhere((f) => f.progress == entry.$1);
        final feature2 = f2.firstWhere((f) => f.progress == entry.$2);
        return featureDistSquared(feature1.feature, feature2.feature);
      }).toList();

      return distances..sort((a, b) => b.compareTo(a));
    },
    "distances between features of this and other polygon",
    matcher,
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
