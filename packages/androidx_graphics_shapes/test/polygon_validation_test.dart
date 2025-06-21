// Ported from PolygonValidationTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/PolygonValidationTest.kt
// See original license at the end of this file.

import 'dart:typed_data';

import 'package:androidx_graphics_shapes/src/corner_rounding.dart';
import 'package:androidx_graphics_shapes/src/polygon_validation.dart';
import 'package:androidx_graphics_shapes/src/rounded_polygon.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  final pentagonPoints = Float32List.fromList(const [
    .2,
    0.0,
    0.8,
    0.0,
    1.0,
    0.6,
    0.5,
    1.0,
    0.0,
    0.6,
  ]);
  final reverseOrientedPentagonPoints = Float32List.fromList(const [
    .2,
    0.0,
    0.0,
    0.6,
    0.5,
    1.0,
    1.0,
    0.6,
    0.8,
    0.0,
  ]);

  test('does not fix valid sharp polygon', () {
    final polygon = RoundedPolygon.fromNumVerts(5);
    expect(polygon, staysUnchanged);
  });

  test('fixes anti-clockwise oriented polygon', () {
    final valid = RoundedPolygon.fromVertices(pentagonPoints);
    final broken = RoundedPolygon.fromVertices(reverseOrientedPentagonPoints);

    expect(broken, fixes(valid));
  });

  test('fixes anti-clockwise oriented rounded polygon', () {
    final valid = RoundedPolygon.fromVertices(pentagonPoints, rounding: const CornerRounding(0.5));
    final broken = RoundedPolygon.fromVertices(
      reverseOrientedPentagonPoints,
      rounding: const CornerRounding(0.5),
    );

    expect(broken, fixes(valid));
  });
}

final Matcher staysUnchanged = isA<RoundedPolygon>().derive(
  (item, matcher) => matcher
      .having(RoundedPolygon.copy, "copy", equals(item))
      .having(PolygonValidator.fix, "fixed", equals(item)),
);

Matcher fixes(RoundedPolygon expected) {
  return isA<RoundedPolygon>().derive(
    (item, matcher) => matcher.having(
      PolygonValidator.fix,
      "fixed",
      allOf(isNot(equals(expected)), roundedPolygonMoreOrLessEquals(expected)),
    ),
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
