// Ported from FloatMappingTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FloatMappingTest.kt
// See original license at the end of this file.

import 'package:flutter_test/flutter_test.dart';
import 'package:androidx_graphics_shapes/float_mapping.dart';

import 'utils.dart';

void main() {
  test("identity mapping test", () {
    validateMapping(DoubleMapper.identity, (x) => x);
  });

  test("simple mapping test", () {
    validateMapping(
      // Map the first half of the start source to the first quarter of the target.
      DoubleMapper(const [(0.0, 0.0), (0.5, 0.25)]),
      (x) => x < 0.5 ? x / 2 : (3 * x - 1) / 2,
    );
  });

  test("target wraps test", () {
    validateMapping(
      // mapping applies a "+ 0.5"
      DoubleMapper(const [(0.0, 0.5), (0.1, 0.6)]),
      (x) => (x + 0.5) % 1.0,
    );
  });

  test("source wraps test", () {
    validateMapping(
      // Values on the source wrap (this is still the "+ 0.5" function)
      DoubleMapper(const [(0.5, 0.0), (0.1, 0.6)]),
      (x) => (x + 0.5) % 1.0,
    );
  });

  test("both wrap test", () {
    // Just the identity function
    validateMapping(
      DoubleMapper(const [(0.5, 0.5), (0.75, 0.75), (0.1, 0.1), (0.49, 0.49)]),
      (x) => x,
    );
  });

  test("multiple point test", () {
    validateMapping(DoubleMapper(const [(0.4, 0.2), (0.5, 0.22), (0.0, 0.8)]), (x) {
      if (x < 0.4) {
        return (0.8 + x) % 1.0;
      } else if (x < 0.5) {
        return 0.2 + (x - 0.4) / 5;
      } else {
        // maps a change of 0.5 in the source to a change 0.58 in the target, hence the 1.16
        return 0.22 + (x - 0.5) * 1.16;
      }
    });
  });

  test("target double wrap throws", () {
    expect(
      () => DoubleMapper(const [(0.0, 0.0), (0.3, 0.6), (0.6, 0.3), (0.9, 0.9)]),
      throwsA(isA<InvalidProgressException>()),
    );
  });

  test("source double wrap throws", () {
    expect(
      () => DoubleMapper(const [(0.0, 0.0), (0.6, 0.3), (0.3, 0.6), (0.9, 0.9)]),
      throwsA(isA<InvalidProgressException>()),
    );
  });
}

void validateMapping(DoubleMapper mapper, double Function(double) expectedFunction) {
  for (int i = 0; i <= 10000; i++) {
    final source = i / 10000.0;
    final target = expectedFunction(source);

    expect(
      mapper.map(source),
      anyOf(closeTo(target, epsilon), closeTo(1 - target, epsilon)),
      reason: "$source should map to $target (iteration $i/9999)",
    );
    expect(
      mapper.mapBack(target),
      anyOf(closeTo(source, epsilon), closeTo(1 - source, epsilon)),
      reason: "$target should map back to $source (iteration $i/9999)",
    );
  }
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
