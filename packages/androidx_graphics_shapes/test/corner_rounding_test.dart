// Ported from CornerRoundingTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/CornerRoundingTest.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("default corner", () {
    final defaultCorner = CornerRounding();
    expect(defaultCorner.radius, 0.0);
    expect(defaultCorner.smoothing, 0.0);
  });

  test("unrounded corner", () {
    final unrounded = CornerRounding.unrounded;
    expect(unrounded.radius, 0.0);
    expect(unrounded.smoothing, 0.0);
  });

  test("rounded corner", () {
    final rounded = CornerRounding(radius: 5.0);
    expect(rounded.radius, 5.0);
    expect(rounded.smoothing, 0.0);
  });

  test("smoothed corner", () {
    final smoothed = CornerRounding(smoothing: 0.5);
    expect(smoothed.radius, 0.0);
    expect(smoothed.smoothing, 0.5);
  });

  test("rounded and smoothed corner", () {
    final roundedAndSmoothed = CornerRounding(radius: 5.0, smoothing: 0.5);
    expect(roundedAndSmoothed.radius, 5.0);
    expect(roundedAndSmoothed.smoothing, 0.5);
  });
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
