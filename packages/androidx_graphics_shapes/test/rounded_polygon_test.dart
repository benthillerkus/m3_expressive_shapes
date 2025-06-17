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
      final manualSquareOffset = RoundedPolygon.fromVertices(
        offsetVerts,
        centerX: offset.dx,
        centerY: offset.dy,
      );
      expect(manualSquareOffset.cubics, shapeListWithinBounds(const Rect.fromLTRB(0, 1, 2, 3)));
    });

    test("manual square rounded", () {
      final manualSquareRounded = RoundedPolygon.fromVertices(verts, rounding: rounding);
      expect(manualSquareRounded.cubics, shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)));
    });

    test("manual square per vertex rounded", () {
      final manualSquarePVRounded = RoundedPolygon.fromVertices(
        verts,
        perVertexRounding: perVtxRounded,
      );
      expect(
        manualSquarePVRounded.cubics,
        shapeListWithinBounds(const Rect.fromLTRB(-1, -1, 1, 1)),
      );
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

    test("reconstructs square", () {
      final base = RoundedPolygon.rectangle();
      final actual = RoundedPolygon.fromFeatures(base.features);
      expect(base, roundedPolygonMoreOrLessEquals(actual));
    });

    test("reconstructs rounded square", () {
      final base = RoundedPolygon.rectangle(
        rounding: const CornerRounding(radius: 0.5, smoothing: 0.2),
      );
      final actual = RoundedPolygon.fromFeatures(base.features);
      expect(base, roundedPolygonMoreOrLessEquals(actual));
    });

    test("reconstructs circles", () {
      for (var i = 3; i <= 20; i++) {
        final base = RoundedPolygon.circle(numVertices: i);
        final actual = RoundedPolygon.fromFeatures(base.features);
        expect(base, roundedPolygonMoreOrLessEquals(actual));
      }
    });

    test("reconstructs stars", () {
      for (var i = 3; i <= 20; i++) {
        final base = RoundedPolygon.star(i);
        final actual = RoundedPolygon.fromFeatures(base.features);
        expect(base, roundedPolygonMoreOrLessEquals(actual));
      }
    });

    test("reconstructs rounded stars", () {
      for (var i = 3; i <= 20; i++) {
        final base = RoundedPolygon.star(
          i,
          rounding: const CornerRounding(radius: 0.5, smoothing: 0.2),
        );
        final actual = RoundedPolygon.fromFeatures(base.features);
        expect(base, roundedPolygonMoreOrLessEquals(actual));
      }
    });

    test("reconstructs pill", () {
      final base = RoundedPolygon.pill();
      final actual = RoundedPolygon.fromFeatures(base.features);
      expect(base, roundedPolygonMoreOrLessEquals(actual));
    });

    test("reconstructs pill star", () {
      final base = RoundedPolygon.pillStar(
        rounding: const CornerRounding(radius: 0.5, smoothing: 0.2),
      );
      final actual = RoundedPolygon.fromFeatures(base.features);
      expect(base, roundedPolygonMoreOrLessEquals(actual));
    });
  });

  test("compute center", () {
    final polygon = RoundedPolygon.fromVertices(
      Float32List.fromList(const [0, 0, 1, 0, 0, 1, 1, 1]),
    );
    expect(polygon.centerX, closeTo(0.5, 1e-4));
    expect(polygon.centerY, closeTo(0.5, 1e-4));
  });

  test("rounding space usage", () {
    const p0 = Offset.zero;
    const p1 = Offset(1, 0);
    const p2 = Offset(0.5, 1);
    const pvRounding = [
      CornerRounding(radius: 1, smoothing: 0),
      CornerRounding(radius: 1, smoothing: 1),
      CornerRounding.unrounded,
    ];
    final polygon = RoundedPolygon.fromVertices(
      Float32List.fromList([p0.dx, p0.dy, p1.dx, p1.dy, p2.dx, p2.dy]),
      perVertexRounding: pvRounding,
    );

    // Since there is not enough room in the p0 -> p1 side even for the roundings, we shouldn't
    // take smoothing into account, so the corners should end in the middle point.
    final lowerEdgeFeature = polygon.features.firstWhere((f) => f is Edge) as Edge;
    expect(lowerEdgeFeature.cubics, hasLength(1));

    final lowerEdge = lowerEdgeFeature.cubics.first;
    expect(lowerEdge.anchor0X, closeTo(0.5, epsilon));
    expect(lowerEdge.anchor0Y, closeTo(0.0, epsilon));
    expect(lowerEdge.anchor1X, closeTo(0.5, epsilon));
    expect(lowerEdge.anchor1Y, closeTo(0.0, epsilon));
  });

  /*
     * In the following tests, we check how much was cut for the top left (vertex 0) and bottom
     * left corner (vertex 3).
     * In particular, both vertex are competing for space in the left side.
     *
     *   Vertex 0            Vertex 1
     *      *---------------------*
     *      |                     |
     *      *---------------------*
     *   Vertex 3            Vertex 2
     */
  group("uneven smoothing", () {
    const points = 20;
    test("1", () {
      // Vertex 3 has the default 0.5 radius, 0 smoothing.
      // Vertex 0 has 0.4 radius, and smoothing varying from 0 to 1.
      for (var i = 0; i <= points; i++) {
        final smooth = i / points;
        expect(
          CornerRounding(radius: 0.4, smoothing: smooth),
          withUnevenSmoothing(
            expectedV0SX: 0.4 * (1 + smooth),
            expectedV0SY: (0.4 * (1 + smooth)).clamp(0, 0.5),
            expectedV3SY: 0.5,
          ),
          reason: "smooth = $smooth",
        );
      }
    });

    test("2", () {
      // Vertex 3 has 0.2f radius and 0.2f smoothing, so it takes at most 0.4f
      // Vertex 0 has 0.4f radius and smoothing varies from 0 to 1, when it reaches 0.5 it starts
      // competing with vertex 3 for space.
      for (var i = 0; i <= points; i++) {
        final smooth = i / points;

        final smoothWantedV0 = 0.4 * smooth;
        final smoothWantedV3 = 0.2;

        // There is 0.4f room for smoothing
        final factor = (0.4 / (smoothWantedV0 + smoothWantedV3)).clamp(0, 1);
        expect(
          CornerRounding(radius: 0.4, smoothing: smooth),
          withUnevenSmoothing(
            expectedV0SX: 0.4 * (1 + smooth),
            expectedV0SY: 0.4 + factor * smoothWantedV0,
            expectedV3SY: 0.2 + factor * smoothWantedV3,
            rounding3: const CornerRounding(radius: 0.2, smoothing: 1),
          ),
          reason: "smooth = $smooth",
        );
      }
    });

    test("3", () {
      // Vertex 3 has 0.6f radius.
      // Vertex 0 has 0.4f radius and smoothing varies from 0 to 1. There is no room for smoothing
      // on the segment between these vertices, but vertex 0 can still have smoothing on the top
      // side.
      for (var i = 0; i <= points; i++) {
        final smooth = i / points;

        expect(
          CornerRounding(radius: 0.4, smoothing: smooth),
          withUnevenSmoothing(
            expectedV0SX: 0.4 * (1 + smooth),
            expectedV0SY: 0.4,
            expectedV3SY: 0.6,
            rounding3: const CornerRounding(radius: 0.6),
          ),
          reason: "smooth = $smooth",
        );
      }
    });
  });

  test("creating full size", () {
    const radius = 400.0;
    const innerRadiusFactor = 0.35;
    final innerRadius = radius * innerRadiusFactor;
    const roundingFactor = 0.32;

    final fullSizeShape = RoundedPolygon.star(
      4,
      radius: radius,
      innerRadius: innerRadius,
      rounding: const CornerRounding(radius: radius * roundingFactor),
      innerRounding: const CornerRounding(radius: radius * roundingFactor),
      centerX: radius,
      centerY: radius,
    ).ktTransformed((x, y) => (x: (x - radius) / radius, y: (y - radius) / radius));

    final canonicalShape = RoundedPolygon.star(
      4,
      radius: 1,
      innerRadius: innerRadiusFactor,
      rounding: const CornerRounding(radius: roundingFactor),
      innerRounding: const CornerRounding(radius: roundingFactor),
    );

    final cubics = canonicalShape.cubics;
    final cubics1 = fullSizeShape.cubics;
    expect(cubics, cubic2DListMoreOrLessEquals(cubics1));
  });
}

Matcher withUnevenSmoothing({
  required double expectedV0SX,
  required double expectedV0SY,
  required double expectedV3SY,
  CornerRounding rounding3 = const CornerRounding(radius: .5),
}) {
  const p0 = Offset.zero;
  const p1 = Offset(5, 0);
  const p2 = Offset(5, 1);
  const p3 = Offset(0, 1);
  return isA<CornerRounding>().having(
    (i) {
      final pvRounding = [
        i, // Vertex 0
        CornerRounding.unrounded, // Vertex 1
        CornerRounding.unrounded, // Vertex 2
        rounding3, // Vertex 3
      ];
      final polygon = RoundedPolygon.fromVertices(
        Float32List.fromList([p0.dx, p0.dy, p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy]),
        perVertexRounding: pvRounding,
      );
      final [e01, _, _, e30] = polygon.features.whereType<Edge>().toList();
      return (e01, e30);
    },
    "edges e01 and e30 from a derived RoundedPolygon",
    allOf(
      isA<(Edge, Edge)>()
          .having(
            (tup) => tup.$1.cubics.first.anchor0X,
            "e01 anchor0X",
            closeTo(expectedV0SX, epsilon),
          )
          .having(
            (tup) => tup.$2.cubics.first.anchor1Y,
            "e30 anchor1Y",
            closeTo(expectedV0SY, epsilon),
          )
          .having(
            (tup) => tup.$2.cubics.first.anchor0Y,
            "e30 anchor0Y",
            closeTo(1 - expectedV3SY, epsilon),
          ),
    ),
  );
}

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
