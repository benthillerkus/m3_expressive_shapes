// Ported from PolygonMeasureTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/PolygonMeasureTest.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:typed_data';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:androidx_graphics_shapes/polygon_measure.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:collection/collection.dart';
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
    irregularPolygonMeasure(RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(.15)));
  });

  test("measure medium rounded hexagon", () {
    irregularPolygonMeasure(RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(.5)));
  });

  test("measure maximum rounded hexagon", () {
    irregularPolygonMeasure(RoundedPolygon.fromNumVerts(6, rounding: const CornerRounding(1)));
  });

  test("measure circle", () {
    // White box test: As the length measurer approximates arcs by linear segments,
    // this test validates if the chosen segment count approximates the arc length up to         // an error of 1.5% from the true length
    const vertices = 4;
    final polygon = RoundedPolygon.circle(numVertices: vertices);

    final actualLength = polygon.cubics.map((it) => const LengthMeasurer().measureCubic(it)).sum;
    final expectedLength = 2 * pi;

    expect(actualLength, closeTo(actualLength, 0.015 * expectedLength));
  });

  test("irregular triangle angle measure", () {
    irregularPolygonMeasure(
      RoundedPolygon.fromVertices(
        Float32List.fromList([0, -1, 1, 1, 0, 0.5, -1, 1]),
        perVertexRounding: [
          const CornerRounding(.2, smoothing: .5),
          const CornerRounding(.2, smoothing: .5),
          const CornerRounding(.4, smoothing: 0),
          const CornerRounding(.2, smoothing: .5),
        ],
      ),
    );
  });

  test("quarter angle measure", () {
    irregularPolygonMeasure(
      RoundedPolygon.fromVertices(
        Float32List.fromList([-1, -1, 1, -1, 1, 1, -1, 1]),
        perVertexRounding: [
          CornerRounding.unrounded,
          CornerRounding.unrounded,
          const CornerRounding(.5, smoothing: .5),
          CornerRounding.unrounded,
        ],
      ),
    );
  });

  test("hour glass measure", () {
    // Regression test: Legacy measurer (AngleMeasurer) would skip the diagonal sides
    // as they are 0 degrees from the center.
    const unit = 1.0;
    final coordinates = Float32List.fromList([
      // lower glass
      0, 0,
      unit, unit,
      -unit, unit,

      // upper glass
      0, 0,
      -unit, -unit,
      unit, -unit,
    ]);

    final diagonal = sqrt(unit * unit + unit * unit);
    final horizontal = 2 * unit;
    final total = 4 * diagonal + 2 * horizontal;

    final polygon = RoundedPolygon.fromVertices(coordinates);
    customPolygonMeasure(
      polygon,
      Float32List.fromList([
        diagonal / total,
        horizontal / total,
        diagonal / total,
        diagonal / total,
        horizontal / total,
        diagonal / total,
      ]),
    );
  });

  test("handles empty feature last", () {
    final triangle = RoundedPolygon.fromFeatures([
      Feature.buildConvexCorner([Cubic2D.straightLine(0, 0, 1, 1)]),
      Feature.buildConvexCorner([Cubic2D.straightLine(1, 1, 1, 0)]),
      Feature.buildConvexCorner([Cubic2D.straightLine(1, 0, 0, 0)]),
      // Empty feature at the end.
      Feature.buildConvexCorner([Cubic2D.straightLine(0, 0, 0, 0)]),
    ]);

    irregularPolygonMeasure(triangle);
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
