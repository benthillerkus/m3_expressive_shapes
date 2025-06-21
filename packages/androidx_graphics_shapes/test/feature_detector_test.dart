// Ported from FeatureDetectorTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/FeatureDetectorTest.kt
// See original license at the end of this file.

import 'dart:collection';

import 'package:androidx_graphics_shapes/corner_rounding.dart';
import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
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
    group("reconstructs pill star", () {
      final originalPolygon = RoundedPolygon.pillStar();
      final splitCubics = originalPolygon.cubics.expand((it) {
        final (a, b) = it.split(.5);
        return [a, b];
      }).toList();

      final createdPolygon = RoundedPolygon.fromFeatures(
        detectFeatures(splitCubics),
        centerX: originalPolygon.centerX,
        centerY: originalPolygon.centerY,
      );

      test("cubics match", () {
        // It's okay if the cubics' control points aren't the same, as long as the shape is the same
        expect(originalPolygon.cubics, hasLength(createdPolygon.cubics.length));

        for (final (index, created) in createdPolygon.cubics.indexed) {
          final original = originalPolygon.cubics[index];

          // pillStar has no roundings, so the created cubics shouldn't be as well
          expect(created.straightIsh(), isTrue);
          expect(original.straightIsh(), isTrue);

          expect(created.anchor0, offsetMoreOrLessEquals(original.anchor0));
          expect(created.anchor1, offsetMoreOrLessEquals(original.anchor1));
        }
      });

      test("zip with next / window", () {
        // https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/zip-with-next.html
        final letters = ["a", "b", "c", "d", "e", "f"];
        final pairs = letters.window(2, 1);
        expect(pairs, hasLength(5));
        expect(
          pairs,
          containsAllInOrder([
            ["a", "b"],
            ["b", "c"],
            ["c", "d"],
            ["d", "e"],
            ["e", "f"],
          ]),
        );
      });

      test("features match", () {
        // The order of the features can be different, as long as they describe the same shape
        expect(originalPolygon.features, hasLength(createdPolygon.features.length));
        expect(
          originalPolygon.features.whereType<Corner>(),
          hasLength(createdPolygon.features.whereType<Corner>().length),
        );
        expect(
          originalPolygon.features.whereType<Edge>(),
          hasLength(createdPolygon.features.whereType<Edge>().length),
        );

        expect(
          createdPolygon.features.window(2, 1),
          everyElement(
            isA<List<Feature>>()
                .having((it) => it.length, "length", 2)
                .having(
                  (it) =>
                      it.first is Edge && it.last is Corner ||
                      it.first is Corner && it.last is Edge,
                  "edge-corner pattern",
                  isTrue,
                ),
          ),
        );

        expect(
          createdPolygon.features.whereType<Corner>(),
          everyElement(
            isA<Corner>().having(
              (it) => it.cubics,
              "cubics",
              allOf(
                isA<List<Cubic2D>>().having(
                  (it) => it.first,
                  "first element",
                  isA<Cubic2D>().having((it) => it.zeroLength, "zero-length", isTrue),
                ),
                hasLength(1),
              ),
            ),
          ),
        );
      });
    });

    test("reconstructs rounded pill star close enough", () {
      // This test aims to ensure that our distance epsilon is not set too high that
      // the roundings of pill star gets pointy as they are small in the [0,1] space
      final originalPolygon = RoundedPolygon.pillStar(rounding: const CornerRounding(0.2));
      final createdPolygon = RoundedPolygon.fromFeatures(
        detectFeatures(originalPolygon.cubics),
        centerX: originalPolygon.centerX,
        centerY: originalPolygon.centerY,
      );

      expect(originalPolygon.cubics, hasLength(createdPolygon.cubics.length));
      // Allow up to one difference...
      expect(
        (originalPolygon.features.length - createdPolygon.features.length).abs(),
        lessThanOrEqualTo(1),
      );
      // ...as long as the edge - corner pattern persists
      expect(
        createdPolygon.features.window(2, 1),
        everyElement(
          isA<List<Feature>>()
              .having((it) => it.length, "length", 2)
              .having(
                (it) =>
                    it.first is Edge && it.last is Corner || it.first is Corner && it.last is Edge,
                "edge-corner pattern",
                isTrue,
              ),
        ),
      );
    });
  });
}

extension ZipExt<T> on Iterable<T> {
  Iterable<T> zip(Iterable<T> other) sync* {
    final iterator = this.iterator;
    final otherIterator = other.iterator;
    while (iterator.moveNext() && otherIterator.moveNext()) {
      yield iterator.current;
      yield otherIterator.current;
    }
  }
}

extension WindowExt<T> on Iterable<T> {
  Iterable<List<T>> window(int size, [int overlap = 0]) sync* {
    if (size <= 0 || overlap < 0) {
      throw ArgumentError("Size must be positive and overlap must be non-negative");
    }
    final iterator = this.iterator;
    final buffer = Queue<T>();
    while (iterator.moveNext()) {
      buffer.addLast(iterator.current);
      if (buffer.length == size) {
        yield List<T>.from(buffer, growable: false);
        for (int i = 0; i < size - overlap; i++) {
          buffer.removeFirst();
        }
      }
    }
  }
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
