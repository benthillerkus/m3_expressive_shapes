// Ported from Features.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Features.kt
// See original license at the end of this file.

// TODO: b/374764251 Introduce an IgnorableFeature?

import 'dart:core';

import 'package:androidx_graphics_shapes/src/utils.dart';
import 'package:meta/meta.dart';

import 'cubic.dart';

/// While a polygon's shape can be drawn solely using a list of [Cubic2D] objects representing its raw
/// curves and lines, features add an extra layer of context to groups of cubics. Features group
/// cubics into (straight) edges, convex corners, or concave corners. For example, rounding a
/// rectangle adds many cubics around its edges, but the rectangle's overall number of corners
/// remains the same. [Morph] therefore uses this grouping for several reasons:
/// - Noise Reduction: Grouping cubics reduces the amount of noise introduced by individual cubics
///   (as seen in the rounded rectangle example).
/// - Mapping Base: The grouping serves as the base set for [Morph]'s mapping process.
/// - Curve Type Mapping: [Morph] maps similar curve types (convex, concave) together. Note that
///   edges or features created with [buildIgnorableFeature] are ignored in the default mapping.
///
/// By using features, you can manipulate polygon shapes with more context and control.
abstract class Feature {
  const Feature(this.cubics);

  final List<Cubic2D> cubics;

  /// Group a list of [Cubic2D] objects to a feature that should be ignored in the default
  /// [Morph] mapping. The feature can have any indentation.
  ///
  /// Sometimes, it's helpful to ignore certain features when morphing shapes. This is because
  /// only the features you mark as important will be smoothly transitioned between the start
  /// and end shapes. Additionally, the default morph algorithm will try to match convex
  /// corners to convex corners and concave to concave. Marking features as ignorable will
  /// influence this matching. For example, given a 12-pointed star, marking all concave
  /// corners as ignorable will create a [Morph] that only considers the outer corners of the
  /// star. As a result, depending on the morphed to shape, the animation may have fewer
  /// intersections and rotations. Another example for the other way around is a [Morph]
  /// between a pointed up triangle to a square. Marking the square's top edge as a convex
  /// corner matches it to the triangle's upper corner. Instead of moving triangle's upper
  /// corner to one of rectangle's corners, the animation now splits the triangle to match
  /// squares' outer corners.
  ///
  /// @param cubics The list of raw cubics describing the feature's shape
  /// @throws [ArgumentError] for lists of empty cubics or non-continuous cubics
  factory Feature.buildIgnorableFeature(List<Cubic2D> cubics) => _validated(Edge(cubics));

  /// Group a [Cubic2D] object to an edge (neither inward or outward identification in a shape).
  ///
  /// @param cubic The raw cubic describing the edge's shape
  /// @throws [ArgumentError] for lists of empty cubics or non-continuous cubics
  factory Feature.buildEdge(Cubic2D cubic) => Edge([cubic]);

  /// Group a list of [Cubic2D] objects to a convex corner (outward indentation in a shape).
  ///
  /// @param cubics The list of raw cubics describing the corner's shape
  /// @throws [ArgumentError] for lists of empty cubics or non-continuous cubics
  factory Feature.buildConvexCorner(List<Cubic2D> cubics) =>
      _validated(Corner(cubics, convex: true));

  /// Group a list of [Cubic2D] objects to a concave corner (inward indentation in a shape).
  ///
  /// @param cubics The list of raw cubics describing the corner's shape
  /// @throws [ArgumentError] for lists of empty cubics or non-continuous cubics
  factory Feature.buildConcaveCorner(List<Cubic2D> cubics) =>
      _validated(Corner(cubics, convex: false));

  static Feature _validated(Feature feature) {
    if (feature.cubics.isEmpty) {
      throw ArgumentError("Features need at least one cubic.");
    }

    if (!Feature._isContinuous(feature)) {
      throw ArgumentError(
        "Feature must be continuous, with the anchor points of all cubics "
        "matching the anchor points of the preceding and succeeding cubics",
      );
    }

    return feature;
  }

  static bool _isContinuous(Feature feature) {
    var prevCubic = feature.cubics.first;
    for (var index = 1; index < feature.cubics.length; index++) {
      final cubic = feature.cubics[index];
      if ((cubic.anchor0X - prevCubic.anchor1X).abs() > distanceEpsilon ||
          (cubic.anchor0Y - prevCubic.anchor1Y).abs() > distanceEpsilon) {
        return false;
      }

      prevCubic = cubic;
    }
    return true;
  }

  /// Transforms the points in this [Feature] with the given [OffsetMover] and returns a new
  /// [Feature]
  ///
  /// @param f The [OffsetMover] used to transform this [Feature]
  Feature moved(OffsetMover f);

  /// Returns a new [Feature] with the points that define the shape of this [Feature] in reversed
  /// order.
  Feature reversed();

  /// Whether this Feature gets ignored in the Morph mapping. See [buildIgnorableFeature] for more
  /// details.
  bool get isIgnorableFeature;

  /// Whether this Feature is an Edge with no inward or outward indentation.
  bool get isEdge;

  /// Whether this Feature is a convex corner (outward indentation in a shape).
  bool get isConvexCorner;

  /// Whether this Feature is a concave corner (inward indentation in a shape).
  bool get isConcaveCorner;
}

/// Edges have only a list of the cubic curves which make up the edge. Edges lie between corners
/// and have no vertex or concavity; the curves are simply straight lines (represented by Cubic
/// curves).
@internal
class Edge extends Feature {
  const Edge(super.cubics);

  @override
  Edge moved(OffsetMover f) => Edge([for (final cubic in cubics) cubic.moved(f)]);

  @override
  Edge reversed() {
    final reversedCubics = cubics.reversed.map((cubic) => cubic.reverse()).toList();

    return Edge(reversedCubics);
  }

  @override
  String toString() => "Edge";

  @override
  final bool isIgnorableFeature = true;

  @override
  final bool isEdge = true;

  @override
  final bool isConvexCorner = false;

  @override
  final bool isConcaveCorner = false;
}

/// Corners contain the list of cubic curves which describe how the corner is rounded (or not),
/// and a flag indicating whether the corner is convex. A regular polygon has all convex corners,
/// while a star polygon generally (but not necessarily) has both convex (outer) and concave
/// (inner) corners.
@internal
class Corner extends Feature {
  const Corner(super.cubics, {this.convex = true});

  final bool convex;
  @override
  Corner moved(OffsetMover f) {
    return Corner([for (final cubic in cubics) cubic.moved(f)], convex: convex);
  }

  @override
  Corner reversed() {
    final reversedCubics = cubics.reversed.map((cubic) => cubic.reverse()).toList();

    // TODO: b/369320447 - Revert flag negation when [RoundedPolygon] ignores orientation
    // for setting the flag
    return Corner(reversedCubics, convex: !convex);
  }

  @override
  String toString() {
    return "Corner: cubics=${cubics.join(", ")} convex=$convex";
  }

  @override
  final bool isIgnorableFeature = false;

  @override
  final bool isEdge = false;

  @override
  bool get isConvexCorner => convex;

  @override
  bool get isConcaveCorner => !convex;
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
