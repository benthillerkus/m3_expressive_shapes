// Ported from TestUtils.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/androidInstrumentedTest/kotlin/androidx/graphics/shapes/TestUtils.kt
// See original license at the end of this file.

import 'dart:math';

import 'package:androidx_graphics_shapes/cubic.dart';
import 'package:androidx_graphics_shapes/features.dart';
import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

const epsilon = 1e-4;

Matcher cubic2DMoreOrLessEquals(Cubic2D value, {double epsilon = epsilon}) {
  return allOf(
    isA<Cubic2D>(),
    HasAnchor0(offsetMoreOrLessEquals(value.anchor0, epsilon: epsilon)),
    HasControl0(offsetMoreOrLessEquals(value.control0, epsilon: epsilon)),
    HasControl1(offsetMoreOrLessEquals(value.control1, epsilon: epsilon)),
    HasAnchor1(offsetMoreOrLessEquals(value.anchor1, epsilon: epsilon)),
  );
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.anchor0].
class HasAnchor0 extends CustomMatcher {
  HasAnchor0(Matcher matcher) : super('Cubic2D with anchor0', 'anchor0', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).anchor0;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.control0].
class HasControl0 extends CustomMatcher {
  HasControl0(Matcher matcher) : super('Cubic2D with control0', 'control0', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).control0;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.control1].
class HasControl1 extends CustomMatcher {
  HasControl1(Matcher matcher) : super('Cubic2D with control1', 'control1', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).control1;
}

/// Lens for [Cubic2D] to focus on its [Cubic2D.anchor1].
class HasAnchor1 extends CustomMatcher {
  HasAnchor1(Matcher matcher) : super('Cubic2D with anchor1', 'anchor1', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Cubic2D).anchor1;
}

Matcher cubic2DListMoreOrLessEquals(List<Cubic2D> expected, {double epsilon = epsilon}) {
  return allOf(
    isA<List<Cubic2D>>(),
    hasLength(expected.length),
    pairwiseCompare(expected, (a, b) {
      return cubic2DMoreOrLessEquals(a, epsilon: epsilon).matches(b, {});
    }, "Cubic2D more or less equals (within $epsilon)"),
  );
}

/// Lens for [Feature] to focus on its cubics.
class _HasCubic2DList extends CustomMatcher {
  _HasCubic2DList(Matcher matcher) : super('List<Cubic2D> with cubics', 'cubics', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Feature).cubics;
}

class _IfBothAreCornersIsConvexSame extends CustomMatcher {
  _IfBothAreCornersIsConvexSame(Feature other)
    : super('Feature with isConvex', 'isConvex', equals(other is Corner ? other.convex : null));

  @override
  Object? featureValueOf(dynamic actual) {
    if (actual is Corner) return actual.convex;

    return null; // Not applicable for non-Corner features.
  }
}

Matcher featureMoreOrLessEquals(Feature expected, {double epsilon = epsilon}) {
  return allOf(
    isA<Feature>(),
    _HasCubic2DList(cubic2DListMoreOrLessEquals(expected.cubics, epsilon: epsilon)),
    _IfBothAreCornersIsConvexSame(expected),
  );
}

Matcher roundedPolygonMoreOrLessEquals(RoundedPolygon expected) {
  return allOf(
    isA<RoundedPolygon>(),
    _HasCubics(cubic2DListMoreOrLessEquals(expected.cubics, epsilon: epsilon)),
    _HasFeatures(
      allOf(
        isA<List<Feature>>(),
        hasLength(expected.features.length),
        pairwiseCompare(
          expected.features,
          (a, b) => featureMoreOrLessEquals(a, epsilon: epsilon).matches(b, {}),
          "Feature more or less equals (within $epsilon)",
        ),
      ),
    ),
  );
}

class _HasCubics extends CustomMatcher {
  _HasCubics(Matcher matcher) : super('RoundedPolygon with cubics', 'cubics', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as RoundedPolygon).cubics;
}

class _HasFeatures extends CustomMatcher {
  _HasFeatures(Matcher matcher) : super('RoundedPolygon with features', 'features', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as RoundedPolygon).features;
}

class _HasDx extends CustomMatcher {
  _HasDx(Matcher matcher) : super('Offset with dx', 'dx', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Offset).dx;
}

class _HasDy extends CustomMatcher {
  _HasDy(Matcher matcher) : super('Offset with dy', 'dy', matcher);

  @override
  Object? featureValueOf(dynamic actual) => (actual as Offset).dy;
}

Matcher offsetGreaterish(Offset other, {double epsilon = epsilon}) {
  return allOf(
    isA<Offset>(),
    _HasDx(greaterThanOrEqualTo(other.dx - epsilon)),
    _HasDy(greaterThanOrEqualTo(other.dy - epsilon)),
  );
}

Matcher offsetLessish(Offset other, {double epsilon = epsilon}) {
  return allOf(
    isA<Offset>(),
    _HasDx(lessThanOrEqualTo(other.dx + epsilon)),
    _HasDy(lessThanOrEqualTo(other.dy + epsilon)),
  );
}

Matcher offsetWithinBounds(Rect rect) {
  return allOf(
    isA<Offset>(),
    _HasDx(greaterThanOrEqualTo(rect.left)),
    _HasDx(lessThanOrEqualTo(rect.right)),
    _HasDy(greaterThanOrEqualTo(rect.top)),
    _HasDy(lessThanOrEqualTo(rect.bottom)),
  );
}

Matcher shapeListWithinBounds(Rect bounds) {
  return allOf(
    isA<List<Cubic2D>>(),
    everyElement(
      allOf(
        HasAnchor0(offsetWithinBounds(bounds)),
        HasControl0(offsetWithinBounds(bounds)),
        HasControl1(offsetWithinBounds(bounds)),
        HasAnchor1(offsetWithinBounds(bounds)),
      ),
    ),
  );
}

ktTransformResult identityTransform(double x, double y) => (x: x, y: y);

/// [angle] is the angle in degrees to rotate the point around the origin (0, 0).
ktTransformResult Function(double, double) pointRotator(double angle) {
  final matrix = Matrix4.rotationZ(angle / 180 * pi);
  return (x, y) {
    final point = matrix * Vector4(x, y, 0, 1);
    return (x: point.x, y: point.y);
  };
}

ktTransformResult Function(double, double) scaleTransform(double sx, double sy) {
  return (x, y) {
    return (x: x * sx, y: y * sy);
  };
}

ktTransformResult Function(double, double) translateTransform(double dx, double dy) {
  return (x, y) {
    return (x: x + dx, y: y + dy);
  };
}

class MatcherBuilder extends Matcher {
  MatcherBuilder(this.builder);

  Matcher Function(Object? item) builder;

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    final matcher = builder(item);
    return matcher.matches(item, matchState..[(#generatedMatcher, item)] = matcher);
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final matcher = matchState[(#generatedMatcher, item)] as Matcher;
    return matcher.describeMismatch(item, mismatchDescription, matchState, verbose);
  }
}

class _TypeMatcher<T> implements TypeMatcher<T> {
  _TypeMatcher(this.matcher);

  final Matcher matcher;

  @override
  Description describe(Description description) {
    return matcher.describe(description);
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return matcher.describeMismatch(item, mismatchDescription, matchState, verbose);
  }

  @override
  TypeMatcher<T> having(Object? Function(T p1) feature, String description, matcher) {
    throw UnimplementedError();
  }

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) => matcher.matches(item, matchState);
}

extension on Matcher {
  TypeMatcher<T> cast<T>() => _TypeMatcher<T>(this);
}

extension MatcherBuilderExtension<T> on TypeMatcher<T> {
  /// Builds a [Matcher] using the provided [builder] function.
  ///
  /// The [builder] function receives the [item] being matched and returns a [TypeMatcher].
  TypeMatcher<T> build(Matcher Function(T item) builder) {
    return MatcherBuilder((a) => allOf(this, builder(a as T))).cast<T>();
  }

  TypeMatcher<T> derive(Matcher Function(T item, TypeMatcher<T> matcher) builder) {
    return MatcherBuilder((a) => builder(a as T, this)).cast<T>();
  }
}

/// A [Matcher] that creates a new [Matcher] based on the provided [matcherBuilder] function,
/// using the actual, discriminated value as the input to the builder.
///
/// This matcher is then being matched against the [newContext].
class ChangeContextMatcher<T> extends TypeMatcher<T> {
  ChangeContextMatcher(this.matcherBuilder, this.newContext);

  final Matcher Function(T actual) matcherBuilder;
  final Object? newContext;

  @override
  Description describe(Description description) {
    return description.add("creates a matcher that matches with ").addDescriptionOf(newContext);
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final matcher = matchState["matcher"] as Matcher;
    return matcher.describeMismatch(newContext, mismatchDescription, matchState, verbose);
  }

  @override
  bool matches(item, Map<dynamic, dynamic> matchState) {
    final matcher = matcherBuilder(item as T);
    addStateInfo(matchState, {"matcher": matcher});
    return matcher.matches(newContext, matchState);
  }
}

extension ChangeContextMatcherExtension<T> on TypeMatcher<T> {
  /// Creates a [ChangeContextMatcher] that uses the provided [matcherBuilder] to create a new
  /// matcher based on the actual value, and matches it against the [newContext].
  ChangeContextMatcher<T> changeContext(
    Matcher Function(T actual) matcherBuilder,
    Object? newContext,
  ) {
    return ChangeContextMatcher(matcherBuilder, newContext);
  }
}

// internal fun assertBitmapsEqual(b0: Bitmap, b1: Bitmap) {
//     assertEquals(b0.width, b1.width)
//     assertEquals(b0.height, b1.height)
//     for (row in 0 until b0.height) {
//         for (col in 0 until b0.width) {
//             assertEquals("Pixels at ($col, $row) not equal", b0.get(col, row), b1.get(col, row))
//         }
//     }
// }

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
