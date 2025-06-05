// Ported from FloatMappingTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FloatMappingTest.kt
// See original license at the end of this file.

import 'package:flutter_test/flutter_test.dart';
import 'package:androidx_graphics_shapes/float_mapping.dart';

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
      DoubleMapper(const [
        (0.5, 0.5),
        (0.75, 0.75),
        (0.1, 0.1),
        (0.49, 0.49),
      ]),
      (x) => x,
    );
  });

  test("multiple point test", () {
    validateMapping(
      DoubleMapper(const [
        (0.4, 0.2),
        (0.5, 0.22),
        (0.0, 0.8),
      ]),
      (x) {
        if (x < 0.4) {
          return (0.8 + x) % 1.0;
        } else if (x < 0.5) {
          return 0.2 + (x - 0.4) / 5;
        } else {
          // maps a change of 0.5 in the source to a change 0.58 in the target, hence the 1.16
          return 0.22 + (x - 0.5) * 1.16;
        }
      },
    );
  });

  test("target double wrap throws", () {
    expect(
      () => DoubleMapper(const [
        (0.0, 0.0),
        (0.3, 0.6),
        (0.6, 0.3),
        (0.9, 0.9),
      ]),
      throwsA(isA<InvalidProgressException>()),
    );
  });

  test("source double wrap throws", () {
    expect(
      () => DoubleMapper(const [
        (0.0, 0.0),
        (0.6, 0.3),
        (0.3, 0.6),
        (0.9, 0.9),
      ]),
      throwsA(isA<InvalidProgressException>()),
    );
  });
}

// package androidx.graphics.shapes

// import androidx.test.filters.SmallTest
// import org.junit.Assert.assertThrows
// import org.junit.Test

// @SmallTest
// class FloatMappingTest {
//     @Test fun identityMappingTest() = validateMapping(DoubleMapper.Identity) { it }

//     @Test
//     fun simpleMappingTest() =
//         validateMapping(
//             // Map the first half of the start source to the first quarter of the target.
//             mapper = DoubleMapper(0f to 0f, 0.5f to 0.25f)
//         ) { x ->
//             if (x < 0.5f) x / 2 else (3 * x - 1) / 2
//         }

//     @Test
//     fun targetWrapsTest() =
//         validateMapping(
//             // mapping applies a "+ 0.5f"
//             mapper = DoubleMapper(0f to 0.5f, 0.1f to 0.6f)
//         ) { x ->
//             (x + 0.5f) % 1f
//         }

//     @Test
//     fun sourceWrapsTest() =
//         validateMapping(
//             // Values on the source wrap (this is still the "+ 0.5f" function)
//             mapper = DoubleMapper(0.5f to 0f, 0.1f to 0.6f)
//         ) { x ->
//             (x + 0.5f) % 1f
//         }

//     @Test
//     fun bothWrapTest() =
//         validateMapping(
//             // Just the identity function
//             mapper = DoubleMapper(0.5f to 0.5f, 0.75f to 0.75f, 0.1f to 0.1f, 0.49f to 0.49f)
//         ) {
//             it
//         }

//     @Test
//     fun multiplePointTest() =
//         validateMapping(mapper = DoubleMapper(0.4f to 0.2f, 0.5f to 0.22f, 0f to 0.8f)) { x ->
//             if (x < 0.4f) {
//                 (0.8f + x) % 1f
//             } else if (x < 0.5f) {
//                 0.2f + (x - 0.4f) / 5
//             } else {
//                 // maps a change of 0.5 in the source to a change 0.58 in the target, hence the 1.16
//                 0.22f + (x - 0.5f) * 1.16f
//             }
//         }

//     @Test
//     fun targetDoubleWrapThrows() {
//         assertThrows(IllegalArgumentException::class.java) {
//             DoubleMapper(0.0f to 0.0f, 0.3f to 0.6f, 0.6f to 0.3f, 0.9f to 0.9f)
//         }
//     }

//     @Test
//     fun sourceDoubleWrapThrows() {
//         assertThrows(IllegalArgumentException::class.java) {
//             DoubleMapper(0.0f to 0.0f, 0.6f to 0.3f, 0.3f to 0.6f, 0.9f to 0.9f)
//         }
//     }

//     private fun validateMapping(mapper: DoubleMapper, expectedFunction: (Float) -> Float) {
//         (0..9999).forEach { i ->
//             val source = i / 10000f
//             val target = expectedFunction(source)

//             assertEqualish(target, mapper.map(source))
//             assertEqualish(source, mapper.mapBack(target))
//         }
//     }
// }

void validateMapping(
  DoubleMapper mapper,
  double Function(double) expectedFunction,
) {
  for (int i = 0; i < 10000; i++) {
    final source = i / 10000.0;
    final target = expectedFunction(source);

    expect(mapper.map(source), closeTo(target, 1e-6), reason: "$source should map to $target (iteration $i/9999)");
    expect(mapper.mapBack(target), closeTo(source, 1e-6), reason: "$target should map back to $source (iteration $i/9999)");
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
