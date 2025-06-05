// Ported from FeaturesTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FeaturesTest.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  test("cannot build empty features", () {
    expect(() => Feature.buildConvexCorner([]), throwsA(isA<ArgumentError>()));
    expect(() => Feature.buildConcaveCorner([]), throwsA(isA<ArgumentError>()));
    expect(() => Feature.buildIgnorableFeature([]), throwsA(isA<ArgumentError>()));
  });

  test("cannot build non-continous features", () {
    final cubic1 = Cubic2D.straightLine(0, 0, 1, 1);
    final cubic2 = Cubic2D.straightLine(10, 10, 11, 11);

    expect(() => Feature.buildConvexCorner([cubic1, cubic2]), throwsA(isA<ArgumentError>()));

    expect(() => Feature.buildConcaveCorner([cubic1, cubic2]), throwsA(isA<ArgumentError>()));

    expect(() => Feature.buildIgnorableFeature([cubic1, cubic2]), throwsA(isA<ArgumentError>()));
  });

  test("build concave corner", () {
    final cubic = Cubic2D.straightLine(0, 0, 1, 0);
    final actual = Feature.buildConcaveCorner([cubic]);
    final expected = Corner([cubic], convex: false);
    expect(expected, featureMoreOrLessEquals(actual));
  });

  test("build convex corner", () {
    final cubic = Cubic2D.straightLine(0, 0, 1, 0);
    final actual = Feature.buildConvexCorner([cubic]);
    final expected = Corner([cubic], convex: true);
    expect(expected, featureMoreOrLessEquals(actual));
  });

  test("builds edge", () {
    final cubic = Cubic2D.straightLine(0, 0, 1, 0);
    final actual = Feature.buildEdge(cubic);
    final expected = Edge([cubic]);
    expect(expected, featureMoreOrLessEquals(actual));
  });

  test("builds ignorable as edge", () {
    final cubic = Cubic2D.straightLine(0, 0, 1, 0);
    final actual = Feature.buildIgnorableFeature([cubic]);
    final expected = Edge([cubic]);
    expect(expected, featureMoreOrLessEquals(actual));
  });
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
