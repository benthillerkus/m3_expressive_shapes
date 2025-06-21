// Ported from CubicTest.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/CubicTest.kt
// See original license at the end of this file.
import 'dart:ui';

import 'package:androidx_graphics_shapes/src/cubic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils.dart';

void main() {
  // These points create a roughly circular arc in the upper-right quadrant around (0,0)

  const p0 = Offset(1, 0);
  const p1 = Offset(1, .5);
  const p2 = Offset(.5, 1);
  const p3 = Offset(0, 1);
  late Cubic2D cubic;

  setUp(() {
    // Make sure cubic is fresh before each test
    // as it isn't immutable
    cubic = Cubic2D.fromOffsets(p0, p1, p2, p3);
  });

  test("construction test", () {
    expect(cubic.anchor0, p0);
    expect(cubic.control0, p1);
    expect(cubic.control1, p2);
    expect(cubic.anchor1, p3);
  });

  test("circular arc test", () {
    final arcCubic = Cubic2D.circularArc(0, 0, p0.dx, p0.dy, p3.dx, p3.dy);
    expect(arcCubic.anchor0, p0);
    expect(arcCubic.anchor1, p3);
  });

  test("div test", () {
    var divCubic = cubic / 1.0;
    expect(cubic, cubic2DMoreOrLessEquals(divCubic));
    divCubic = cubic / 1;
    expect(cubic, cubic2DMoreOrLessEquals(divCubic));
    divCubic = cubic / 2.0;
    expect(p0 / 2.0, offsetMoreOrLessEquals(divCubic.anchor0, epsilon: epsilon));
    expect(p1 / 2.0, offsetMoreOrLessEquals(divCubic.control0, epsilon: epsilon));
    expect(p2 / 2.0, offsetMoreOrLessEquals(divCubic.control1, epsilon: epsilon));
    expect(p3 / 2.0, offsetMoreOrLessEquals(divCubic.anchor1, epsilon: epsilon));
    divCubic = cubic / 2;
    expect(p0 / 2.0, offsetMoreOrLessEquals(divCubic.anchor0, epsilon: epsilon));
    expect(p1 / 2.0, offsetMoreOrLessEquals(divCubic.control0, epsilon: epsilon));
    expect(p2 / 2.0, offsetMoreOrLessEquals(divCubic.control1, epsilon: epsilon));
    expect(p3 / 2.0, offsetMoreOrLessEquals(divCubic.anchor1, epsilon: epsilon));
  });

  test("times test", () {
    var timesCubic = cubic * 1.0;
    expect(p0, offsetMoreOrLessEquals(timesCubic.anchor0, epsilon: epsilon));
    expect(p1, offsetMoreOrLessEquals(timesCubic.control0, epsilon: epsilon));
    expect(p2, offsetMoreOrLessEquals(timesCubic.control1, epsilon: epsilon));
    expect(p3, offsetMoreOrLessEquals(timesCubic.anchor1, epsilon: epsilon));
    timesCubic = cubic * 1;
    expect(p0, offsetMoreOrLessEquals(timesCubic.anchor0, epsilon: epsilon));
    expect(p1, offsetMoreOrLessEquals(timesCubic.control0, epsilon: epsilon));
    expect(p2, offsetMoreOrLessEquals(timesCubic.control1, epsilon: epsilon));
    expect(p3, offsetMoreOrLessEquals(timesCubic.anchor1, epsilon: epsilon));
    timesCubic = cubic * 2.0;
    expect(p0 * 2.0, offsetMoreOrLessEquals(timesCubic.anchor0, epsilon: epsilon));
    expect(p1 * 2.0, offsetMoreOrLessEquals(timesCubic.control0, epsilon: epsilon));
    expect(p2 * 2.0, offsetMoreOrLessEquals(timesCubic.control1, epsilon: epsilon));
    expect(p3 * 2.0, offsetMoreOrLessEquals(timesCubic.anchor1, epsilon: epsilon));
    timesCubic = cubic * 2;
    expect(p0 * 2.0, offsetMoreOrLessEquals(timesCubic.anchor0, epsilon: epsilon));
    expect(p1 * 2.0, offsetMoreOrLessEquals(timesCubic.control0, epsilon: epsilon));
    expect(p2 * 2.0, offsetMoreOrLessEquals(timesCubic.control1, epsilon: epsilon));
    expect(p3 * 2.0, offsetMoreOrLessEquals(timesCubic.anchor1, epsilon: epsilon));
  });

  test("plus test", () {
    final offsetCubic = cubic * 2.0;
    final plusCubic = cubic + offsetCubic;
    expect(p0 + offsetCubic.anchor0, offsetMoreOrLessEquals(plusCubic.anchor0, epsilon: epsilon));
    expect(p1 + offsetCubic.control0, offsetMoreOrLessEquals(plusCubic.control0, epsilon: epsilon));
    expect(p2 + offsetCubic.control1, offsetMoreOrLessEquals(plusCubic.control1, epsilon: epsilon));
    expect(p3 + offsetCubic.anchor1, offsetMoreOrLessEquals(plusCubic.anchor1, epsilon: epsilon));
  });

  test("reverse test", () {
    final reverseCubic = cubic.reverse();
    expect(p3, offsetMoreOrLessEquals(reverseCubic.anchor0, epsilon: epsilon));
    expect(p2, offsetMoreOrLessEquals(reverseCubic.control0, epsilon: epsilon));
    expect(p1, offsetMoreOrLessEquals(reverseCubic.control1, epsilon: epsilon));
    expect(p0, offsetMoreOrLessEquals(reverseCubic.anchor1, epsilon: epsilon));
  });

  test("straight line test", () {
    final lineCubic = Cubic2D.straightLine(p0.dx, p0.dy, p3.dx, p3.dy);
    expect(p0, lineCubic.anchor0);
    expect(p3, lineCubic.anchor1);
    expect(lineCubic.control0, offsetWithinBounds(Rect.fromPoints(p0, p3)));
    expect(lineCubic.control1, offsetWithinBounds(Rect.fromPoints(p0, p3)));
  });

  test("split test", () {
    final (split0, split1) = cubic.split(0.5);
    expect(cubic.anchor0, split0.anchor0);
    expect(cubic.anchor1, split1.anchor1);

    expect(split0.anchor1, offsetWithinBounds(Rect.fromPoints(cubic.anchor0, cubic.anchor1)));
    expect(split1.anchor0, offsetWithinBounds(Rect.fromPoints(cubic.anchor0, cubic.anchor1)));
  });

  test("point on curve test", () {
    var halfway = cubic.transform(0.5);
    expect(halfway, offsetWithinBounds(Rect.fromPoints(cubic.anchor0, cubic.anchor1)));
    final straightLineCubic = Cubic2D.straightLine(p0.dx, p0.dy, p3.dx, p3.dy);
    halfway = straightLineCubic.transform(0.5);
    final computedHalfway = Offset(p0.dx + 0.5 * (p3.dx - p0.dx), p0.dy + 0.5 * (p3.dy - p0.dy));
    expect(computedHalfway, offsetMoreOrLessEquals(halfway, epsilon: epsilon));
  });

  group("transform", () {
    test("identity test", () {
      final transform = identityTransform;
      final transformedCubic = cubic.moved(transform);
      expect(cubic, cubic2DMoreOrLessEquals(transformedCubic));
    });

    test("scale test", () {
      final transform = scaleTransform(3, 3);
      final transformedCubic = cubic.moved(transform);
      expect(cubic * 3, cubic2DMoreOrLessEquals(transformedCubic));
    });

    test("translate test", () {
      final tx = 200.0;
      final ty = 300.0;
      final translationVector = Offset(tx, ty);
      final transform = translateTransform(tx, ty);
      final transformedCubic = cubic.moved(transform);
      expect(
        cubic.anchor0 + translationVector,
        offsetMoreOrLessEquals(transformedCubic.anchor0, epsilon: epsilon),
      );
      expect(
        cubic.control0 + translationVector,
        offsetMoreOrLessEquals(transformedCubic.control0, epsilon: epsilon),
      );
      expect(
        cubic.control1 + translationVector,
        offsetMoreOrLessEquals(transformedCubic.control1, epsilon: epsilon),
      );
      expect(
        cubic.anchor1 + translationVector,
        offsetMoreOrLessEquals(transformedCubic.anchor1, epsilon: epsilon),
      );
    });
  });

  test("empty cubic has zero length test", () {
    final emptyCubic = Cubic2D.empty(10, 10);
    expect(emptyCubic.zeroLength, isTrue);
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
