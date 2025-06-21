// Ported from Morph.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Morph.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:ui';

import 'package:androidx_graphics_shapes/src/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'cubic.dart';
import 'feature_mapping.dart';
import 'features.dart';
import 'polygon_measure.dart';
import 'rounded_polygon.dart';

/// This class is used to animate between start and end polygons objects.
///
/// Morphing between arbitrary objects can be problematic because it can be difficult to determine
/// how the points of a given shape map to the points of some other shape. [Morph] simplifies the
/// problem by only operating on [RoundedPolygon] objects, which are known to have similar,
/// contiguous structures. For one thing, the shape of a polygon is contiguous from start to end
/// (compared to an arbitrary Path object, which could have one or more `moveTo` operations in the
/// shape). Also, all edges of a polygon shape are represented by [Cubic] objects, thus the start and
/// end shapes use similar operations. Two Polygon shapes then only differ in the quantity and
/// placement of their curves. The morph works by determining how to map the curves of the two shapes
/// together (based on proximity and other information, such as distance to polygon vertices and
/// concavity), and splitting curves when the shapes do not have the same number of curves or when
/// the curve placement within the shapes is very different.
class Morph {
  Morph(RoundedPolygon start, RoundedPolygon end) : _start = start, _end = end;

  final RoundedPolygon _start;
  final RoundedPolygon _end;

  /// The structure which holds the actual shape being morphed. It contains all cubics necessary to
  /// represent the start and end shapes (the original cubics in the shapes may be cut to align the
  /// start/end shapes), matched one to one in each Pair.
  @internal
  List<(Cubic2D, Cubic2D)> get morphMatch => _morphMatch;

  late final List<(Cubic2D, Cubic2D)> _morphMatch = match(_start, _end);

  /// Calculates the axis-aligned bounds of the object.
  ///
  /// @param approximate when true, uses a faster calculation to create the bounding box based on
  ///   the min/max values of all anchor and control points that make up the shape. Default value
  ///   is true.
  /// @param bounds a buffer to hold the results. If not supplied, a temporary buffer will be
  ///   created.
  /// @return The axis-aligned bounding box for this object, where the rectangles left, top, right,
  ///   and bottom values will be stored in entries 0, 1, 2, and 3, in that order.
  Rect calculateBounds({bool approximate = true}) {
    final startBounds = _start.calculateBounds(approximate: approximate);
    final endBounds = _end.calculateBounds(approximate: approximate);
    return startBounds.expandToInclude(endBounds);
  }

  /// Like [calculateBounds], this function calculates the axis-aligned bounds of the object and
  /// returns that rectangle. But this function determines the max dimension of the shape (by
  /// calculating the distance from its center to the start and midpoint of each curve) and returns
  /// a square which can be used to hold the object in any rotation. This function can be used, for
  /// example, to calculate the max size of a UI element meant to hold this shape in any rotation.
  ///
  /// @param bounds a buffer to hold the results. If not supplied, a temporary buffer will be
  ///   created.
  /// @return The axis-aligned max bounding box for this object, where the rectangles left, top,
  ///   right, and bottom values will be stored in entries 0, 1, 2, and 3, in that order.
  Rect calculateMaxBounds() {
    final startBounds = _start.calculateMaxBounds();
    final endBounds = _end.calculateMaxBounds();
    return startBounds.expandToInclude(endBounds);
  }

  /// Returns a representation of the morph object at a given [progress] value as a list of Cubics.
  /// Note that this function causes a new list to be created and populated, so there is some
  /// overhead.
  ///
  /// @param progress a value from 0 to 1 that determines the morph's current shape, between the
  ///   start and end shapes provided at construction time. A value of 0 results in the start
  ///   shape, a value of 1 results in the end shape, and any value in between results in a shape
  ///   which is a linear interpolation between those two shapes. The range is generally [0..1] and
  ///   values outside could result in undefined shapes, but values close to (but outside) the
  ///   range can be used to get an exaggerated effect (e.g., for a bounce or overshoot animation).
  List<Cubic2D> asCubics(double progress) {
    final List<Cubic2D> res = List.empty(growable: true);
    // The first/last mechanism here ensures that the final anchor point in the shape
    // exactly matches the first anchor point. There can be rendering artifacts introduced
    // by those points being slightly off, even by much less than a pixel
    Cubic2D? firstCubic;
    Cubic2D? lastCubic;
    for (final match in _morphMatch) {
      final cubic = Cubic2D.lerp(match.$1, match.$2, progress);
      firstCubic ??= cubic;
      if (lastCubic != null) res.add(lastCubic);
      lastCubic = cubic;
    }
    if (lastCubic != null && firstCubic != null) {
      res.add(
        Cubic2D(
          lastCubic.anchor0X,
          lastCubic.anchor0Y,
          lastCubic.control0X,
          lastCubic.control0Y,
          lastCubic.control1X,
          lastCubic.control1Y,
          firstCubic.anchor0X,
          firstCubic.anchor0Y,
        ),
      );
    }

    return res;
  }

  /// Returns a representation of the morph object at a given [progress] value, iterating over the
  /// cubics and calling the callback. This function is faster than [asCubics], since it doesn't
  /// allocate new [Cubic] instances, but to do this it reuses the same [MutableCubic] instance
  /// during iteration.
  ///
  /// @param progress a value from 0 to 1 that determines the morph's current shape, between the
  ///   start and end shapes provided at construction time. A value of 0 results in the start
  ///   shape, a value of 1 results in the end shape, and any value in between results in a shape
  ///   which is a linear interpolation between those two shapes. The range is generally [0..1] and
  ///   values outside could result in undefined shapes, but values close to (but outside) the
  ///   range can be used to get an exaggerated effect (e.g., for a bounce or overshoot animation).
  /// @param mutableCubic An instance of [MutableCubic] that will be used to set each cubic in
  ///   time.
  /// @param callback The function to be called for each Cubic
  @pragma("vm:prefer-inline")
  void forEachCubic({
    required double progress,
    Cubic2D? mutableCubic,
    required void Function(Cubic2D) callback,
  }) {
    mutableCubic ??= Cubic2D.empty(0, 0);
    for (final match in morphMatch) {
      mutableCubic.lerpInto(match.$1, match.$2, progress);
      callback(mutableCubic);
    }
  }

  /// [match], called at Morph construction time, creates the structure used to animate between
  /// the start and end shapes. The technique is to match geometry (curves) between the shapes
  /// when and where possible, and to create new/placeholder curves when necessary (when one of
  /// the shapes has more curves than the other). The result is a list of pairs of Cubic
  /// curves. Those curves are the matched pairs: the first of each pair holds the geometry of
  /// the start shape, the second holds the geometry for the end shape. Changing the progress
  /// of a Morph object simply interpolates between all pairs of curves for the morph shape.
  ///
  /// Curves on both shapes are matched by running the [Measurer] to determine where the points
  /// are in each shape (proportionally, along the outline), and then running [featureMapper]
  /// which decides how to map (match) all of the curves with each other.
  @internal
  static List<(Cubic2D, Cubic2D)> match(RoundedPolygon p1, RoundedPolygon p2) {
    if (kDebugMode) {
      for (int polyIndex = 0; polyIndex < 2; polyIndex++) {
        _log.fine(
          (polyIndex == 0 ? "Initial start:\n" : "Initial end:\n") +
              (polyIndex == 0 ? p1 : p2).features
                  .map(
                    (feature) =>
                        "${feature.runtimeType} - ${switch (feature) {
                          Corner(convex: true) => "Convex - ",
                          Corner(convex: false) => "Concave - ",
                          Edge() => "Edge - ",
                          _ => "",
                        }}${feature.cubics.join("|")}",
                  )
                  .join("\n"),
        );
      }
    }

    // Measure polygons, returns lists of measured cubics for each polygon, which
    // we then use to match start/end curves
    final measuredPolygon1 = MeasuredPolygon.measurePolygon(const LengthMeasurer(), p1);
    final measuredPolygon2 = MeasuredPolygon.measurePolygon(const LengthMeasurer(), p2);

    // features1 and 2 will contain the list of corners (just the inner circular curve)
    // along with the progress at the middle of those corners. These measurement values
    // are then used to compare and match between the two polygons
    final features1 = measuredPolygon1.features;
    final features2 = measuredPolygon2.features;

    // Map features: doubleMapper is the result of mapping the features in each shape to the
    // closest feature in the other shape.
    // Given a progress in one of the shapes it can be used to find the corresponding
    // progress in the other shape (in both directions)
    final doubleMapper = featureMapper(features1, features2);

    // cut point on poly2 is the mapping of the 0 point on poly1
    final polygon2CutPoint = doubleMapper.map(0);
    _log.fine("polygon2CutPoint = $polygon2CutPoint");

    // Cut and rotate.
    // Polygons start at progress 0, and the featureMapper has decided that we want to match
    // progress 0 in the first polygon to `polygon2CutPoint` on the second polygon.
    // So we need to cut the second polygon there and "rotate it", so as we walk through
    // both polygons we can find the matching.
    // The resulting bs1/2 are MeasuredPolygons, whose MeasuredCubics start from
    // outlineProgress=0 and increasing until outlineProgress=1
    final bs1 = measuredPolygon1;
    final bs2 = measuredPolygon2.cutAndShift(polygon2CutPoint);

    if (kDebugMode) {
      for (int index = 0; index < bs1.length; index++) {
        _log.fine("start $index: ${bs1.elementAtOrNull(index)}");
      }
      for (int index = 0; index < bs2.length; index++) {
        _log.fine("End $index: ${bs2.elementAtOrNull(index)}");
      }
    }

    // Match
    // Now we can compare the two lists of measured cubics and create a list of pairs
    // of cubics [ret], which are the start/end curves that represent the Morph object
    // and the start and end shapes, and which can be interpolated to animate the
    // between those shapes.
    final ret = List<(Cubic2D, Cubic2D)>.empty(growable: true);
    // i1/i2 are the indices of the current cubic on the start (1) and end (2) shapes
    var i1 = 0;
    var i2 = 0;
    // b1, b2 are the current measured cubic for each polygon
    var b1 = bs1.elementAtOrNull(i1++);
    var b2 = bs2.elementAtOrNull(i2++);
    // Iterate until all curves are accounted for and matched
    while (b1 != null && b2 != null) {
      // Progresses are in shape1's perspective
      // b1a, b2a are ending progress values of current measured cubics in [0,1] range
      final b1a = (i1 == bs1.length) ? 1.0 : b1.endOutlineProgress;
      final b2a = (i2 == bs2.length)
          ? 1.0
          : doubleMapper.mapBack((b2.endOutlineProgress + polygon2CutPoint) % 1.0);
      final minb = min(b1a, b2a);
      _log.fine("$b1a $b2a | $minb");
      // min b is the progress at which the curve that ends first ends.
      // If both curves ends roughly there, no cutting is needed, we have a match.
      // If one curve extends beyond, we need to cut it.
      final MeasuredCubic? seg1, newb1;
      if (b1a > minb + angleEpsilon) {
        _log.fine("Cut 1");
        (seg1, newb1) = b1.cutAtProgress(minb);
      } else {
        seg1 = b1;
        newb1 = bs1.elementAtOrNull(i1++);
      }
      final MeasuredCubic? seg2, newb2;
      if (b2a > minb + angleEpsilon) {
        _log.fine("Cut 2");
        (seg2, newb2) = b2.cutAtProgress((doubleMapper.map(minb) - polygon2CutPoint) % 1.0);
      } else {
        seg2 = b2;
        newb2 = bs2.elementAtOrNull(i2++);
      }
      _log.fine("Match: $seg1 -> $seg2");
      ret.add((seg1.cubic, seg2.cubic));
      b1 = newb1;
      b2 = newb2;
    }
    if (b1 != null || b2 != null) {
      throw StateError("Expected both Polygon's Cubic to be fully matched");
    }

    if (kDebugMode) {
      // Export as SVG path.
      String showPoint(Offset point) {
        return "${(point.dx * 100).toStringAsFixed(3)} ${(point.dy * 100).toStringAsFixed(3)}";
      }

      for (int listIx = 0; listIx < 2; listIx++) {
        final points = ret.map((it) => listIx == 0 ? it.$1 : it.$2);
        _log.fine(
          "M ${showPoint(points.first.anchor0)} ${points.map((it) => "C ${showPoint(it.control0)}, ${showPoint(it.control1)}, ${showPoint(it.anchor1)}").join(" ")} Z",
        );
      }
    }
    return ret;
  }
}

final _log = Logger("Morph");

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
