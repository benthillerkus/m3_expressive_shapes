// Ported from FeatureDetectorTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FeatureDetectorTest.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:androidx_graphics_shapes/feature_detector.dart';

import 'utils.dart';

void main() {
  test("recognizes straightness", () {
    final cubic = Cubic2D.straightLine(0, 0, 1, 0);
    expect(cubic.straightIsh(), isTrue);
  });

  test("recognizes straightness-ish", () {
    final slightlyNotStraightCubic = Cubic2D(
      323.508,
      201.759,
      317.35,
      192.008,
      311.193,
      182.227,
      305.035,
      172.475,
    );
    expect(slightlyNotStraightCubic.straightIsh(), isTrue);
  });

  test("recognizes curvature", () {
    final roundCubic = Cubic2D(0, 0, 0.5, 0.5, 0.5, 0.5, 1, 0);
    expect(roundCubic.straightIsh(), isFalse);
  });

  test("recognizes smoothness for curved cubic", () {
    final baseCubic = Cubic2D(0, 0, 0, 10, 10, 10, 10, 0);
    final smoothContinuation = Cubic2D(10, 0, 10, -10, 20, -10, 20, 0);
    expect(baseCubic.smoothesIntoIsh(smoothContinuation), isTrue);
  });

  test("recognizes smoothness for straight cubic", () {
    final baseCubic = Cubic2D.straightLine(0, 0, 10, 0);
    final smoothContinuation = Cubic2D.straightLine(10, 0, 20, 0);
    expect(baseCubic.smoothesIntoIsh(smoothContinuation), isTrue);
  });

  test("recognizes smoothness within relative tolerance", () {
    // These two cubics are from the edge of an imported shape. Even though they don't
    // count as smooth within the absolute distance epsilon, relatively seen they should count.

    // dart format off
    final baseCubic = Cubic2D(323.508, 201.759, 317.35, 192.008, 311.193, 182.227, 305.008, 172.475);
    final smoothContinuation = Cubic2D(305.008, 172.475, 290.812, 149.962, 276.617, 127.42, 262.422, 104.907);
    // dart format on
    expect(baseCubic.smoothesIntoIsh(smoothContinuation), isTrue);
  });

  test("empty cubics are not straight-ish", () {
    expect(Cubic2D.empty(10, 10).straightIsh(), isFalse);
  });

  test("recognizes alignment for straight lines", () {
    final baseCubic = Cubic2D.straightLine(0, 0, 10, 0);
    final smoothContinuation = Cubic2D.straightLine(10, 0, 20, 0);

    expect(baseCubic.alignsIshWith(smoothContinuation), isTrue);
  });

  test("recognizes alignment within relative tolerance", () {
    // These two cubics are from the edge of an imported shape. Even though the second edge
    // is very small within the given scale, it is not empty. However, even the length of
    // 0.027 is so relatively tiny in the given range of coordinates, that it should be seen as
    // an empty cubic. Therefore, the second can be seen as an extend of the first.
    final baseCubic = Cubic2D(
      323.508,
      201.759,
      317.35,
      192.008,
      311.193,
      182.227,
      305.035,
      172.475,
    );
    final smoothContinuation = Cubic2D.straightLine(305.035, 172.475, 305.008, 172.475);

    expect(baseCubic.alignsIshWith(smoothContinuation), isTrue);
  });

  test("includes alignment for empty cubics", () {
    final base = Cubic2D.straightLine(0, 0, 10, 0);
    final empty = Cubic2D.empty(10, 0);

    expect(base.alignsIshWith(empty), isTrue);
    expect(empty.alignsIshWith(base), isTrue);
  });

  test("converts straight cubic to edge", () {
    final cubic = Cubic2D.straightLine(0, 0, 10, 0);
    final followingCubic = Cubic2D.straightLine(10, 0, 20, 0);

    final converted = cubic.asFeature(followingCubic);
    final expected = Edge([cubic]);

    expect(converted, isA<Edge>());
    expect(expected, featureMoreOrLessEquals(converted));
  });

  test("converts curved cubic to corner", () {
    final cubic = Cubic2D(0, 0, 0.5, 0.5, 0.5, 0.5, 1, 0);
    final followingCubic = Cubic2D(1, 0, 1.5, 1.5, 1.5, 1.5, 2, 0);

    final converted = cubic.asFeature(followingCubic);
    final expected = Corner([cubic], convex: false);

    expect(converted, isA<Corner>());
    expect(expected, featureMoreOrLessEquals(converted));
  });

  group("reconstructs polygon", () {
    test("reconstructs pill star", () {
      throw UnimplementedError(
        "This test is not yet ported from FeatureDetectorTest.kt",
      );
    });

    test("reconstructs rounded pill star close enough", () {
      throw UnimplementedError(
        "This test is not yet ported from FeatureDetectorTest.kt",
      );
    });
  });
}

// TODO Port the rest of the tests from FeatureDetectorTest.kt
//     @Test
//     fun reconstructsPillStar() {
//         val originalPolygon = RoundedPolygon.pillStar()
//         val splitCubics = originalPolygon.cubics.flatMap { it.split(0.5f).toList() }

//         val createdPolygon =
//             RoundedPolygon(
//                 detectFeatures(splitCubics),
//                 originalPolygon.centerX,
//                 originalPolygon.centerY,
//             )

//         // It's okay if the cubics' control points aren't the same, as long as the shape is the same
//         assertEquals(originalPolygon.cubics.size, createdPolygon.cubics.size)
//         createdPolygon.cubics.forEachIndexed { i, new ->
//             val original = originalPolygon.cubics[i]

//             // pillStar has no roundings, so the created cubics shouldn't be as well
//             assertTrue(new.straightIsh())
//             assertTrue(original.straightIsh())

//             assertPointsEqualish(
//                 Point(new.anchor0X, new.anchor0Y),
//                 Point(original.anchor0X, original.anchor0Y),
//             )
//             assertPointsEqualish(
//                 Point(new.anchor1X, new.anchor1Y),
//                 Point(original.anchor1X, original.anchor1Y),
//             )
//         }

//         // The order of the features can be different, as long as they describe the same shape
//         assertEquals(originalPolygon.features.size, createdPolygon.features.size)
//         assertEquals(
//             originalPolygon.features.filterIsInstance<Feature.Corner>().size,
//             createdPolygon.features.filterIsInstance<Feature.Corner>().size,
//         )
//         assertEquals(
//             originalPolygon.features.filterIsInstance<Feature.Edge>().size,
//             createdPolygon.features.filterIsInstance<Feature.Edge>().size,
//         )
//         assertTrue(
//             createdPolygon.features.zipWithNext().all {
//                 it.first is Feature.Edge && it.second is Feature.Corner ||
//                     it.first is Feature.Corner && it.second is Feature.Edge
//             }
//         )
//         assertTrue(
//             createdPolygon.features.filterIsInstance<Feature.Corner>().all {
//                 it.cubics.size == 1 && it.cubics.first().zeroLength()
//             }
//         )
//     }

//     @Test
//     fun reconstructsRoundedPillStarCloseEnough() {
//         // This test aims to ensure that our distance epsilon is not set too high that
//         // the roundings of pill star gets pointy as they are small in the [0,1] space
//         val originalPolygon = RoundedPolygon.pillStar(rounding = CornerRounding(0.2f))
//         val createdPolygon =
//             RoundedPolygon(
//                 detectFeatures(originalPolygon.cubics),
//                 originalPolygon.centerX,
//                 originalPolygon.centerY,
//             )

//         assertEquals(originalPolygon.cubics.size, createdPolygon.cubics.size)
//         // Allow up to one difference...
//         assertEquals(abs(originalPolygon.features.size - createdPolygon.features.size), 1)
//         // ...as long as the edge - corner pattern persists
//         assertTrue(
//             createdPolygon.features.zipWithNext().all {
//                 it.first is Feature.Edge && it.second is Feature.Corner ||
//                     it.first is Feature.Corner && it.second is Feature.Edge
//             }
//         )
//     }
// }

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
