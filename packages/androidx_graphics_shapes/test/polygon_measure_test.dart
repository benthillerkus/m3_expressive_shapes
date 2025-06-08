// Ported from PolygonMeasureTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/PolygonMeasureTest.kt
// See original license at the end of this file.

import 'dart:typed_data';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/polygon_measure.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

const measurer = LengthMeasurer();

void main() {
  test("measure sharp triangle", () => regularPolygonMeasure(3));

  test("measure sharp pentagon", () => regularPolygonMeasure(5));

  test("measure sharp octagon", () => regularPolygonMeasure(8));

  test("meaure sharp dodecagon", () => regularPolygonMeasure(12));

  test("measure sharp icosagon", () => regularPolygonMeasure(20));

  test("measure slightly rounded hesagon", () {
    irregularPolygonMeasure(
      RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(radius: .15)),
    );
  });

  test("measure medium rounded hexagon", () {
    irregularPolygonMeasure(
      RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(radius: .5)),
    );
  });

  test("measure maximum rounded hexagon", () {
    irregularPolygonMeasure(
      RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(radius: 1)),
    );
  });

  test("measure circle", () {
    // White box test: As the length measurer approximates arcs by linear segments,
    // this test validates if the chosen segment count approximates the arc length up to         // an error of 1.5% from the true length
    const vertices = 4;
    // final polygon = RoundedPolygon.circle(numVertices = vertices);

    throw UnimplementedError("requires shapes");

    // val actualLength = polygon.cubics.sumOf { LengthMeasurer().measureCubic(it).toDouble() }
    // val expectedLength = 2 * PI

    // assertEquals(expectedLength, actualLength, 0.015f * expectedLength)
  });
}

void regularPolygonMeasure(int sides, [CornerRounding rounding = CornerRounding.unrounded]) {
  irregularPolygonMeasure(RoundedPolygon.fromNumVerts(sides, rounding: rounding), (
    measuredPolygon,
  ) {
    expect(
      measuredPolygon.indexed,
      allOf(
        hasLength(sides),
        everyElement(
          predicate(
            (r) {
              final (index, measuredCubic) = r! as (int, MeasuredCubic);
              return closeTo(
                measuredCubic.startOutlineProgress,
                epsilon,
              ).matches(index.toDouble() / sides, {});
            },
            "On a regular polygon each side has the same length, so each part cubics start should be offset by the same fraction",
          ),
        ),
      ),
    );
  });
}

void customPolygonMeasure(RoundedPolygon polygon, Float32List progresses) {
  irregularPolygonMeasure(polygon, (measuredPolygon) {
    expect(
      measuredPolygon,
      allOf(
        hasLength(progresses.length),
        pairwiseCompare(progresses, (progress, MeasuredCubic measuredCubic) {
          return closeTo(
            measuredCubic.endOutlineProgress - measuredCubic.startOutlineProgress,
            epsilon,
          ).matches(progress, {});
        }, "the per-segment progress should be calculatable as end-start"),
      ),
      reason: "Progresses should be coherent",
    );
  });
}

void irregularPolygonMeasure(
  RoundedPolygon polygon, [
  void Function(MeasuredPolygon)? extraChecks,
]) {
  final measuredPolygon = MeasuredPolygon.measurePolygon(measurer, polygon);

  expect(
    measuredPolygon.first.startOutlineProgress,
    equals(0.0),
    reason: "The first startOutlineProgress in a MeasuredPolygon should start at 0",
  );
  expect(
    measuredPolygon.last.endOutlineProgress,
    equals(1.0),
    reason: "The first startOutlineProgress in a MeasuredPolygon should end at 1",
  );

  for (final (index, measuredCubic) in measuredPolygon.indexed) {
    if (index > 0) {
      expect(
        measuredPolygon[index - 1].endOutlineProgress,
        equals(measuredCubic.startOutlineProgress),
        reason: "Progress on a MeasuredPolygon should be continuous over adjacent MeasuredCubics",
      );
    }
    expect(
      measuredCubic.endOutlineProgress,
      greaterThanOrEqualTo(measuredCubic.startOutlineProgress),
      reason: "startOutlineProgress should always be lower than or equal to endOutlineProgress",
    );
  }

  for (final (index, progressableFeature) in measuredPolygon.features.indexed) {
    expect(
      progressableFeature.progress,
      allOf(greaterThanOrEqualTo(0.0), lessThan(1.0)),
      reason: "Feature #$index has invalid progress: ${progressableFeature.progress}",
    );
  }

  extraChecks?.call(measuredPolygon);
}

// package androidx.graphics.shapes

// import androidx.test.filters.SmallTest
// import kotlin.math.PI
// import kotlin.math.sqrt
// import org.junit.Assert.assertEquals
// import org.junit.Assert.assertTrue
// import org.junit.Test

// @SmallTest
// class PolygonMeasureTest {
//     private val measurer = LengthMeasurer()

//     @Test fun measureSharpTriangle() = regularPolygonMeasure(3)

//     @Test fun measureSharpPentagon() = regularPolygonMeasure(5)

//     @Test fun measureSharpOctagon() = regularPolygonMeasure(8)

//     @Test fun measureSharpDodecagon() = regularPolygonMeasure(12)

//     @Test fun measureSharpIcosagon() = regularPolygonMeasure(20)

//     @Test
//     fun measureSlightlyRoundedHexagon() {
//         irregularPolygonMeasure(RoundedPolygon(6, rounding = CornerRounding(0.15f)))
//     }

//     @Test
//     fun measureMediumRoundedHexagon() {
//         irregularPolygonMeasure(RoundedPolygon(6, rounding = CornerRounding(0.5f)))
//     }

//     @Test
//     fun measureMaximumRoundedHexagon() {
//         irregularPolygonMeasure(RoundedPolygon(6, rounding = CornerRounding(1f)))
//     }

//     @Test
//     fun measureCircle() {
//         // White box test: As the length measurer approximates arcs by linear segments,
//         // this test validates if the chosen segment count approximates the arc length up to
//         // an error of 1.5% from the true length
//         val vertices = 4
//         val polygon = RoundedPolygon.circle(numVertices = vertices)

//         val actualLength = polygon.cubics.sumOf { LengthMeasurer().measureCubic(it).toDouble() }
//         val expectedLength = 2 * PI

//         assertEquals(expectedLength, actualLength, 0.015f * expectedLength)
//     }

//     @Test
//     fun irregularTriangleAngleMeasure() =
//         irregularPolygonMeasure(
//             RoundedPolygon(
//                 vertices = floatArrayOf(0f, -1f, 1f, 1f, 0f, 0.5f, -1f, 1f),
//                 perVertexRounding =
//                     listOf(
//                         CornerRounding(0.2f, 0.5f),
//                         CornerRounding(0.2f, 0.5f),
//                         CornerRounding(0.4f, 0f),
//                         CornerRounding(0.2f, 0.5f),
//                     ),
//             )
//         )

//     @Test
//     fun quarterAngleMeasure() =
//         irregularPolygonMeasure(
//             RoundedPolygon(
//                 vertices = floatArrayOf(-1f, -1f, 1f, -1f, 1f, 1f, -1f, 1f),
//                 perVertexRounding =
//                     listOf(
//                         CornerRounding.Unrounded,
//                         CornerRounding.Unrounded,
//                         CornerRounding(0.5f, 0.5f),
//                         CornerRounding.Unrounded,
//                     ),
//             )
//         )

//     @Test
//     fun hourGlassMeasure() {
//         // Regression test: Legacy measurer (AngleMeasurer) would skip the diagonal sides
//         // as they are 0 degrees from the center.
//         val unit = 1f
//         val coordinates =
//             floatArrayOf(
//                 // lower glass
//                 0f,
//                 0f,
//                 unit,
//                 unit,
//                 -unit,
//                 unit,

//                 // upper glass
//                 0f,
//                 0f,
//                 -unit,
//                 -unit,
//                 unit,
//                 -unit,
//             )

//         val diagonal = sqrt(unit * unit + unit * unit)
//         val horizontal = 2 * unit
//         val total = 4 * diagonal + 2 * horizontal

//         val polygon = RoundedPolygon(coordinates)
//         customPolygonMeasure(
//             polygon,
//             floatArrayOf(
//                 diagonal / total,
//                 horizontal / total,
//                 diagonal / total,
//                 diagonal / total,
//                 horizontal / total,
//                 diagonal / total,
//             ),
//         )
//     }

//     @Test
//     fun handlesEmptyFeatureLast() {
//         val triangle =
//             RoundedPolygon(
//                 listOf(
//                     Feature.buildConvexCorner(listOf(Cubic.straightLine(0f, 0f, 1f, 1f))),
//                     Feature.buildConvexCorner(listOf(Cubic.straightLine(1f, 1f, 1f, 0f))),
//                     Feature.buildConvexCorner(listOf(Cubic.straightLine(1f, 0f, 0f, 0f))),
//                     // Empty feature at the end.
//                     Feature.buildConvexCorner(listOf(Cubic.straightLine(0f, 0f, 0f, 0f))),
//                 )
//             )

//         irregularPolygonMeasure(triangle)
//     }

//     private fun regularPolygonMeasure(
//         sides: Int,
//         rounding: CornerRounding = CornerRounding.Unrounded,
//     ) {
//         irregularPolygonMeasure(RoundedPolygon(sides, rounding = rounding)) { measuredPolygon ->
//             assertEquals(sides, measuredPolygon.size)

//             measuredPolygon.forEachIndexed { index, measuredCubic ->
//                 assertEqualish(index.toFloat() / sides, measuredCubic.startOutlineProgress)
//             }
//         }
//     }

//     private fun customPolygonMeasure(polygon: RoundedPolygon, progresses: FloatArray) =
//         irregularPolygonMeasure(polygon) { measuredPolygon ->
//             require(measuredPolygon.size == progresses.size)

//             measuredPolygon.forEachIndexed { index, measuredCubic ->
//                 assertEqualish(
//                     progresses[index],
//                     measuredCubic.endOutlineProgress - measuredCubic.startOutlineProgress,
//                 )
//             }
//         }

//     private fun irregularPolygonMeasure(
//         polygon: RoundedPolygon,
//         extraChecks: (MeasuredPolygon) -> Unit = {},
//     ) {
//         val measuredPolygon = MeasuredPolygon.measurePolygon(measurer, polygon)

//         assertEquals(0f, measuredPolygon.first().startOutlineProgress)
//         assertEquals(1f, measuredPolygon.last().endOutlineProgress)

//         measuredPolygon.forEachIndexed { index, measuredCubic ->
//             if (index > 0) {
//                 assertEquals(
//                     measuredPolygon[index - 1].endOutlineProgress,
//                     measuredCubic.startOutlineProgress,
//                 )
//             }
//             assertTrue(measuredCubic.endOutlineProgress >= measuredCubic.startOutlineProgress)
//         }

//         measuredPolygon.features.forEachIndexed { index, progressableFeature ->
//             assert(progressableFeature.progress >= 0f && progressableFeature.progress < 1f) {
//                 "Feature #$index has invalid progress: ${progressableFeature.progress}"
//             }
//         }

//         extraChecks(measuredPolygon)
//     }
// }

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
