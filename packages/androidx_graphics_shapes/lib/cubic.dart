// Ported from Cubic.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Cubic.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:androidx_graphics_shapes/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'point.dart';

/// This class holds the anchor and control point data for a single cubic Bézier curve, with anchor
/// points ([anchor0X], [anchor0Y]) and ([anchor1X], [anchor1Y]) at either end and control points
/// ([control0X], [control0Y]) and ([control1X], [control1Y]) determining the slope of the curve
/// between the anchor points.
final class Cubic2D extends Curve2D {
  Cubic2D(
    this.anchor0X,
    this.anchor0Y,
    this.control0X,
    this.control0Y,
    this.control1X,
    this.control1Y,
    this.anchor1X,
    this.anchor1Y,
  );

  Cubic2D.fromOffsets(Offset anchor0, Offset control0, Offset control1, Offset anchor1)
    : this(
        anchor0.dx,
        anchor0.dy,
        control0.dx,
        control0.dy,
        control1.dx,
        control1.dy,
        anchor1.dx,
        anchor1.dy,
      );

  /// The first anchor point x coordinate
  double anchor0X;

  /// The first anchor point y coordinate
  double anchor0Y;

  /// The first control point x coordinate
  double control0X;

  /// The first control point y coordinate
  double control0Y;

  /// The second control point x coordinate
  double control1X;

  /// The second control point y coordinate
  double control1Y;

  /// The second anchor point x coordinate
  double anchor1X;

  /// The second anchor point y coordinate
  double anchor1Y;

  Offset get anchor0 => Offset(anchor0X, anchor0Y);
  Offset get control0 => Offset(control0X, control0Y);
  Offset get control1 => Offset(control1X, control1Y);
  Offset get anchor1 => Offset(anchor1X, anchor1Y);

  @override
  int get samplingSeed => Object.hash(
    anchor0X,
    anchor0Y,
    control0X,
    control0Y,
    control1X,
    control1Y,
    anchor1X,
    anchor1Y,
  );

  @override
  /// Returns a point on the curve for parameter t, representing the proportional distance along
  /// the curve between its starting point at anchor0 and ending point at anchor1.
  ///
  /// [t] The distance along the curve between the anchor points, where 0 is at anchor0 and 1
  ///   is at anchor1
  Offset transformInternal(double t) {
    final u = 1 - t;
    return Offset(
      anchor0X * (u * u * u) +
          control0X * (3 * t * u * u) +
          control1X * (3 * t * t * u) +
          anchor1X * (t * t * t),
      anchor0Y * (u * u * u) +
          control0Y * (3 * t * u * u) +
          control1Y * (3 * t * t * u) +
          anchor1Y * (t * t * t),
    );
  }

  @internal
  bool get zeroLength {
    return (anchor0X - anchor1X).abs() < distanceEpsilon &&
        (anchor0Y - anchor1Y).abs() < distanceEpsilon;
  }

  @internal
  bool convexTo(Cubic2D next) {
    final prevVertex = Offset(anchor0X, anchor0Y);
    final currVertex = Offset(anchor1X, anchor1Y);
    final nextVertex = Offset(next.anchor1X, next.anchor1Y);
    return convex(prevVertex, currVertex, nextVertex);
  }

  static bool _zeroIsh(double value) => value.abs() < distanceEpsilon;

  /// This function returns the true bounds of this curve, filling [bounds] with the axis-aligned
  /// bounding box values for left, top, right, and bottom, in that order.
  @internal
  Float32x4 calculateBounds({bool approximate = false}) {
    // A curve might be of zero-length, with both anchors co-lated.
    // Just return the point itself.
    if (zeroLength) {
      return Float32x4(anchor0X, anchor0Y, anchor0X, anchor0Y);
    }

    var minX = min(anchor0X, anchor1X);
    var minY = min(anchor0Y, anchor1Y);
    var maxX = max(anchor0X, anchor1X);
    var maxY = max(anchor0Y, anchor1Y);

    if (approximate) {
      // Approximate bounds use the bounding box of all anchors and controls
      return Float32x4(
        min(minX, min(control0X, control1X)),
        min(minY, min(control0Y, control1Y)),
        max(maxX, max(control0X, control1X)),
        max(maxY, max(control0Y, control1Y)),
      );
    }

    // Find the derivative, which is a quadratic Bezier. Then we can solve for t using
    // the quadratic formula
    final xa = -anchor0X + 3 * control0X - 3 * control1X + anchor1X;
    final xb = 2 * anchor0X - 4 * control0X + 2 * control1X;
    final xc = -anchor0X + control0X;

    if (_zeroIsh(xa)) {
      // Try Muller's method instead; it can find a single root when a is 0
      if (xb != 0) {
        final t = 2 * xc / (-2 * xb);
        if (t >= 0 && t <= 1) {
          final double it = transformInternal(t).dx;
          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }
      }
    } else {
      final xs = xb * xb - 4 * xa * xc;
      if (xs >= 0) {
        final t1 = (-xb + sqrt(xs)) / (2 * xa);
        if (t1 >= 0 && t1 <= 1) {
          final double it = transformInternal(t1).dx;
          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }

        final t2 = (-xb - sqrt(xs)) / (2 * xa);
        if (t2 >= 0 && t2 <= 1) {
          final double it = transformInternal(t2).dx;

          if (it < minX) minX = it;
          if (it > maxX) maxX = it;
        }
      }
    }

    // Repeat the above for y coordinate
    final ya = -anchor0Y + 3 * control0Y - 3 * control1Y + anchor1Y;
    final yb = 2 * anchor0Y - 4 * control0Y + 2 * control1Y;
    final yc = -anchor0Y + control0Y;

    if (_zeroIsh(ya)) {
      if (yb != 0) {
        final t = 2 * yc / (-2 * yb);
        if (t >= 0 && t <= 1) {
          final double it = transformInternal(t).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }
      }
    } else {
      final ys = yb * yb - 4 * ya * yc;
      if (ys >= 0) {
        final t1 = (-yb + sqrt(ys)) / (2 * ya);
        if (t1 >= 0 && t1 <= 1) {
          final double it = transformInternal(t1).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }

        final t2 = (-yb - sqrt(ys)) / (2 * ya);
        if (t2 >= 0 && t2 <= 1) {
          final double it = transformInternal(t2).dy;
          if (it < minY) minY = it;
          if (it > maxY) maxY = it;
        }
      }
    }
    return Float32x4(minX, minY, maxX, maxY);
  }

  /// Returns two Cubics, created by splitting this curve at the given distance of [t] between the
  /// original starting and ending anchor points.
  // TODO: cartesian optimization?
  (Cubic2D, Cubic2D) split(double t) {
    final u = 1 - t;
    final pointOnCurve = transform(t);
    return (
      Cubic2D(
        anchor0X,
        anchor0Y,
        anchor0X * u + control0X * t,
        anchor0Y * u + control0Y * t,
        anchor0X * (u * u) + control0X * (2 * u * t) + control1X * (t * t),
        anchor0Y * (u * u) + control0Y * (2 * u * t) + control1Y * (t * t),
        pointOnCurve.dx,
        pointOnCurve.dy,
      ),
      Cubic2D(
        // TODO: should calculate once and share the result
        pointOnCurve.dx,
        pointOnCurve.dy,
        control0X * (u * u) + control1X * (2 * u * t) + anchor1X * (t * t),
        control0Y * (u * u) + control1Y * (2 * u * t) + anchor1Y * (t * t),
        control1X * u + anchor1X * t,
        control1Y * u + anchor1Y * t,
        anchor1X,
        anchor1Y,
      ),
    );
  }

  /// Utility function to reverse the control/anchor points for this curve.
  Cubic2D reverse() =>
      Cubic2D(anchor1X, anchor1Y, control1X, control1Y, control0X, control0Y, anchor0X, anchor0Y);

  /// Operator overload to enable adding Cubic objects together, like "c0 + c1"
  Cubic2D operator +(Cubic2D other) => Cubic2D(
    anchor0X + other.anchor0X,
    anchor0Y + other.anchor0Y,
    control0X + other.control0X,
    control0Y + other.control0Y,
    control1X + other.control1X,
    control1Y + other.control1Y,
    anchor1X + other.anchor1X,
    anchor1Y + other.anchor1Y,
  );

  /// Operator overload to enable multiplying Cubics by a scalar value x, like "c0 * x"
  Cubic2D operator *(num other) => Cubic2D(
    anchor0X * other,
    anchor0Y * other,
    control0X * other,
    control0Y * other,
    control1X * other,
    control1Y * other,
    anchor1X * other,
    anchor1Y * other,
  );

  /// Operator overload to enable dividing Cubics by a scalar value x, like "c0 / x"
  Cubic2D operator /(num other) => Cubic2D(
    anchor0X / other,
    anchor0Y / other,
    control0X / other,
    control0Y / other,
    control1X / other,
    control1Y / other,
    anchor1X / other,
    anchor1Y / other,
  );

  @override
  String toString() {
    return "anchor0: ($anchor0X, $anchor0Y) control0: ($control0X, $control0Y), control1: ($control1X, $control1Y), anchor1: ($anchor1X, $anchor1Y)";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cubic2D &&
          other.runtimeType == runtimeType &&
          anchor0X == other.anchor0X &&
          anchor0Y == other.anchor0Y &&
          control0X == other.control0X &&
          control0Y == other.control0Y &&
          control1X == other.control1X &&
          control1Y == other.control1Y &&
          anchor1X == other.anchor1X &&
          anchor1Y == other.anchor1Y;

  @override
  int get hashCode => Object.hash(
    anchor0X,
    anchor0Y,
    control0X,
    control0Y,
    control1X,
    control1Y,
    anchor1X,
    anchor1Y,
  );

  /// Transforms the points in this [Cubic] with the given [ktPointTransformer] and returns a new
  /// [Cubic]
  ///
  /// @param f The [ktPointTransformer] used to [ktTransform] this [Cubic]
  Cubic2D ktTransformed(ktPointTransformer f) {
    return Cubic2D(
      anchor0X,
      anchor0Y,
      control0X,
      control0Y,
      control1X,
      control1Y,
      anchor1X,
      anchor1Y,
    )..ktTransform(f);
  }

  Cubic2D copyWith({
    double? anchor0X,
    double? anchor0Y,
    double? control0X,
    double? control0Y,
    double? control1X,
    double? control1Y,
    double? anchor1X,
    double? anchor1Y,
  }) {
    return Cubic2D(
      anchor0X ?? this.anchor0X,
      anchor0Y ?? this.anchor0Y,
      control0X ?? this.control0X,
      control0Y ?? this.control0Y,
      control1X ?? this.control1X,
      control1Y ?? this.control1Y,
      anchor1X ?? this.anchor1X,
      anchor1Y ?? this.anchor1Y,
    );
  }

  /// Generates a bezier curve that is a straight line between the given anchor points. The
  /// control points lie 1/3 of the distance from their respective anchor points.
  factory Cubic2D.straightLine(double x0, double y0, double x1, double y1) {
    return Cubic2D(
      x0,
      y0,
      lerpDouble(x0, x1, 1 / 3)!,
      lerpDouble(y0, y1, 1 / 3)!,
      lerpDouble(x0, x1, 2 / 3)!,
      lerpDouble(y0, y1, 2 / 3)!,
      x1,
      y1,
    );
  }

  // TODO: consider a more general function (maybe in addition to this) that allows
  // caller to get a list of curves surpassing 180 degrees
  /// Generates a bezier curve that approximates a circular arc, with p0 and p1 as the starting
  /// and ending anchor points. The curve generated is the smallest of the two possible arcs
  /// around the entire 360-degree circle. Arcs of greater than 180 degrees should use more
  /// than one arc together. Note that p0 and p1 should be equidistant from the center.
  factory Cubic2D.circularArc(
    double centerX,
    double centerY,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    final p0d = Offset(x0 - centerX, y0 - centerY).normalize();
    final p1d = Offset(x1 - centerX, y1 - centerY).normalize();
    final rotatedP0 = p0d.rotate90();
    final rotatedP1 = p1d.rotate90();
    final clockwise = rotatedP0.dotProduct(Offset(x1 - centerX, y1 - centerY)) >= 0;
    final cosa = p0d.dotProduct(p1d);
    /* p0 ~= p1 */
    if (cosa > 0.999) return Cubic2D.straightLine(x0, y0, x1, y1);
    final k =
        Offset(x0 - centerX, y0 - centerY).distance *
        4 /
        3 *
        (sqrt(2 * (1 - cosa)) - sqrt(1 - cosa * cosa)) /
        (1 - cosa) *
        (clockwise ? 1.0 : -1.0);
    return Cubic2D(
      x0,
      y0,
      x0 + rotatedP0.dx * k,
      y0 + rotatedP0.dy * k,
      x1 - rotatedP1.dx * k,
      y1 - rotatedP1.dy * k,
      x1,
      y1,
    );
  }

  /// Generates an empty Cubic defined at (x0, y0)
  @internal
  Cubic2D.empty(double x0, double y0) : this(x0, y0, x0, y0, x0, y0, x0, y0);

  void ktTransformOnePoint(ktPointTransformer f, int ix) {
    switch (ix) {
      case 0:
        final r = f(anchor0X, anchor0Y);
        anchor0X = r.x;
        anchor0Y = r.y;
      case 2:
        final r = f(control0X, control0Y);
        control0X = r.x;
        control0Y = r.y;
      case 4:
        final r = f(control1X, control1Y);
        control1X = r.x;
        control1Y = r.y;
      case 6:
        final r = f(anchor1X, anchor1Y);
        anchor1X = r.x;
        anchor1Y = r.y;
      default:
        throw ArgumentError("Invalid index $ix for Cubic2D transform");
    }
  }

  /// Transforms (as in moves, rotates, scales, etc.) the points in this [Cubic] with the given
  /// [PointTransformer] [f].
  ///
  /// Not to be confused with [transform] which maps the parameter t to a point on the curve.
  void ktTransform(ktPointTransformer f) {
    final a = f(anchor0X, anchor0Y);
    final b = f(control0X, control0Y);
    final c = f(control1X, control1Y);
    final d = f(anchor1X, anchor1Y);
    anchor0X = a.x;
    anchor0Y = a.y;
    control0X = b.x;
    control0Y = b.y;
    control1X = c.x;
    control1Y = c.y;
    anchor1X = d.x;
    anchor1Y = d.y;
  }

  Cubic2D lerp(Cubic2D c1, Cubic2D c2, double t) {
    return Cubic2D(
      lerpDouble(c1.anchor0X, c2.anchor0X, t)!,
      lerpDouble(c1.anchor0Y, c2.anchor0Y, t)!,
      lerpDouble(c1.control0X, c2.control0X, t)!,
      lerpDouble(c1.control0Y, c2.control0Y, t)!,
      lerpDouble(c1.control1X, c2.control1X, t)!,
      lerpDouble(c1.control1Y, c2.control1Y, t)!,
      lerpDouble(c1.anchor1X, c2.anchor1X, t)!,
      lerpDouble(c1.anchor1Y, c2.anchor1Y, t)!,
    );
  }
}

typedef ktTransformResult = ({double x, double y});

/// Interface for a function that can transform (rotate/scale/translate/etc.) points.
///
/// Transform the point given the x and y parameters, returning the transformed point as a
/// [ktTransformResult]
typedef ktPointTransformer = ktTransformResult Function(double x, double y);

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
