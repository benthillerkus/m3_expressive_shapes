// Ported from RoundedPolygon.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/RoundedPolygon.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:typed_data';

import 'package:androidx_graphics_shapes/point.dart';
import 'package:androidx_graphics_shapes/utils.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'corner_rounding.dart';
import 'cubic.dart';
import 'features.dart';

final Logger _log = Logger("RoundedPolygon");

/// The RoundedPolygon class allows simple construction of polygonal shapes with optional rounding at
/// the vertices. Polygons can be constructed with either the number of vertices desired or an
/// ordered list of vertices.
class RoundedPolygon {
  RoundedPolygon._(this.features, this.center) {
    _initCubics();

    var prevCubic = cubics[cubics.length - 1];
    _log.fine("Cubic-1 = $prevCubic");
    for (final (index, cubic) in cubics.indexed) {
      _log.fine("Cubic = $cubic");
      if ((cubic.anchor0X - prevCubic.anchor1X).abs() > distanceEpsilon ||
          (cubic.anchor0Y - prevCubic.anchor1Y).abs() > distanceEpsilon) {
        _log.fine("Ix: $index | (${cubic.anchor0X},${cubic.anchor0Y}) vs $prevCubic");
        throw ArgumentError.value(
          features,
          "features",
          "RoundedPolygon must be contiguous, with the anchor points of all curves "
              "matching the anchor points of the preceding and succeeding cubics",
        );
      }
      prevCubic = cubic;
    }
  }

  final List<Feature> features;
  final Offset center;

  /// A flattened version of the [Feature]s, as a [List<Cubic2D>].
  late final List<Cubic2D> cubics;

  double get centerX => center.dx;
  double get centerY => center.dy;

  void _initCubics() {
    cubics = [];
    // The first/last mechanism here ensures that the final anchor point in the shape
    // exactly matches the first anchor point. There can be rendering artifacts introduced
    // by those points being slightly off, even by much less than a pixel
    Cubic2D? firstCubic;
    Cubic2D? lastCubic;
    List<Cubic2D>? firstFeatureSplitStart;
    List<Cubic2D>? firstFeatureSplitEnd;
    if (features.isNotEmpty && features[0].cubics.length == 3) {
      final centerCubic = features[0].cubics[1];
      final (start, end) = centerCubic.split(.5);
      firstFeatureSplitStart = [features[0].cubics[0], start];
      firstFeatureSplitEnd = [end, features[0].cubics[2]];
    }
    // iterating one past the features list size allows us to insert the initial split
    // cubic if it exists
    for (int i = 0; i <= features.length; i++) {
      final List<Cubic2D> featureCubics;
      if (i == 0 && firstFeatureSplitEnd != null) {
        featureCubics = firstFeatureSplitEnd;
      } else if (i == features.length) {
        if (firstFeatureSplitStart != null) {
          featureCubics = firstFeatureSplitStart;
        } else {
          break;
        }
      } else {
        featureCubics = features[i].cubics;
      }
      for (int j = 0; j < featureCubics.length; j++) {
        // Skip zero-length curves; they add nothing and can trigger rendering artifacts
        final cubic = featureCubics[j];
        if (!cubic.zeroLength) {
          if (lastCubic != null) cubics.add(lastCubic);
          lastCubic = cubic;
          firstCubic ??= cubic;
        } else {
          if (lastCubic != null) {
            // Dropping several zero-ish length curves in a row can lead to
            // enough discontinuity to throw an exception later, even though the
            // distances are quite small. Account for that by making the last
            // cubic use the latest anchor point, always.
            lastCubic.anchor1X = cubic.anchor1X;
            lastCubic.anchor1Y = cubic.anchor1Y;
          }
        }
      }
    }
    if (lastCubic != null && firstCubic != null) {
      cubics.add(
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
    } else {
      // Empty / 0-sized polygon.
      cubics.add(Cubic2D(centerX, centerY, centerX, centerY, centerX, centerY, centerX, centerY));
    }
  }

  /// Transforms (scales/translates/etc.) this [RoundedPolygon] with the given [PointTransformer]
  /// and returns a new [RoundedPolygon]. This is a low level API and there should be more platform
  /// idiomatic ways to transform a [RoundedPolygon] provided by the platform specific wrapper.
  ///
  /// [f] The [ktPointTransformer] used to transform this [RoundedPolygon]
  RoundedPolygon ktTransformed(ktPointTransformer f) {
    final center = this.center.ktTransformed(f);
    final it = <Feature>[];

    for (int i = 0; i < features.length; i++) {
      it.add(features[i].ktTransformed(f));
    }

    return RoundedPolygon._(it, center);
  }

  /// Creates a new RoundedPolygon, moving and resizing this one, so it's completely inside the
  /// (0, 0) -> (1, 1) square, centered if there extra space in one direction
  RoundedPolygon normalized() {
    final bounds = calculateBounds();
    final width = bounds.right - bounds.left;
    final height = bounds.bottom - bounds.top;
    final side = max(width, height);
    // Center the shape if bounds are not a square
    final offsetX = (side - width) / 2 - bounds.left;
    final offsetY = (side - height) / 2 - bounds.top;
    return ktTransformed((x, y) => (x: (x + offsetX) / side, y: (y + offsetY) / side));
  }

  @override
  String toString() =>
      "[RoundedPolygon. Cubics = ${cubics.join(", ")} || Features = ${features.join(", ")} || Center = ($centerX, $centerY)]";

  /// Like [calculateBounds], this function calculates the axis-aligned bounds of the object and
  /// returns that rectangle. But this function determines the max dimension of the shape (by
  /// calculating the distance from its center to the start and midpoint of each curve) and returns
  /// a square which can be used to hold the object in any rotation. This function can be used, for
  /// example, to calculate the max size of a UI element meant to hold this shape in any rotation.
  ///
  /// Returns the axis-aligned max bounding box for this object, where the rectangles left, top,
  ///   right, and bottom values will be stored in entries 0, 1, 2, and 3, in that order.
  Float32x4 calculateMaxBounds() {
    var maxDistSquared = 0.0;
    for (final cubic in cubics) {
      final anchorDistance =
          pow(cubic.anchor0X - centerX, 2) + pow(cubic.anchor0Y - centerY, 2); // distance squared
      final middlePoint = cubic.transform(.5);
      final middleDistance =
          pow(middlePoint.dx - centerX, 2) + pow(middlePoint.dy - centerY, 2); // distance squared
      maxDistSquared = max(maxDistSquared, max(anchorDistance as double, middleDistance as double));
    }
    final distance = sqrt(maxDistSquared);
    return Float32x4(
      centerX - distance,
      centerY - distance,
      centerX + distance,
      centerY + distance,
    );
  }

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
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final cubic in cubics) {
      final bounds = cubic.calculateBounds(approximate: approximate);
      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoundedPolygon) return false;

    return features == other.features;
  }

  @override
  int get hashCode => features.hashCode;

  /// This constructor takes the number of vertices in the resulting polygon. These vertices are
  /// positioned on a virtual circle around a given center with each vertex positioned [radius]
  /// distance from that center, equally spaced (with equal angles between them). If no radius is
  /// supplied, the shape will be created with a default radius of 1, resulting in a shape whose
  /// vertices lie on a unit circle, with width/height of 2. That default polygon will probably need to
  /// be rescaled using [transformed] into the appropriate size for the UI in which it will be drawn.
  ///
  /// The [rounding] and [perVertexRounding] parameters are optional. If not supplied, the result will
  /// be a regular polygon with straight edges and unrounded corners.
  ///
  /// @param numVertices The number of vertices in this polygon.
  /// @param radius The radius of the polygon, in pixels. This radius determines the initial size of
  ///   the object, but it can be transformed later by using the [transformed] function.
  /// @param centerX The X coordinate of the center of the polygon, around which all vertices will be
  ///   placed. The default center is at (0,0).
  /// @param centerY The Y coordinate of the center of the polygon, around which all vertices will be
  ///   placed. The default center is at (0,0).
  /// @param rounding The [CornerRounding] properties of all vertices. If some vertices should have
  ///   different rounding properties, then use [perVertexRounding] instead. The default rounding value
  ///   is [CornerRounding.Unrounded], meaning that the polygon will use the vertices themselves in the
  ///   final shape and not curves rounded around the vertices.
  /// @param perVertexRounding The [CornerRounding] properties of every vertex. If this parameter is
  ///   not null, then it must have [numVertices] elements. If this parameter is null, then the polygon
  ///   will use the [rounding] parameter for every vertex instead. The default value is null.
  /// @throws IllegalArgumentException If [perVertexRounding] is not null and its size is not equal to
  ///   [numVertices].
  /// @throws IllegalArgumentException [numVertices] must be at least 3.
  factory RoundedPolygon.fromNumVerts(
    int numVertices, {
    double radius = 1,
    double centerX = 0,
    double centerY = 0,
    CornerRounding rounding = CornerRounding.unrounded,
    List<CornerRounding>? perVertexRounding,
  }) => RoundedPolygon.fromVertices(
    _verticesFromNumVerts(numVertices, radius, centerX, centerY),
    rounding: rounding,
    perVertexRounding: perVertexRounding,
    centerX: centerX,
    centerY: centerY,
  );

  /// Creates a copy of the given [RoundedPolygon]
  factory RoundedPolygon.copy(RoundedPolygon source) =>
      RoundedPolygon._(source.features, source.center);

  /// This function takes the vertices (either supplied or calculated, depending on the constructor
  /// called), plus [CornerRounding] parameters, and creates the actual [RoundedPolygon] shape,
  /// rounding around the vertices (or not) as specified. The result is a list of [Cubic] curves which
  /// represent the geometry of the final shape.
  ///
  /// @param vertices The list of vertices in this polygon specified as pairs of x/y coordinates in
  ///   this FloatArray. This should be an ordered list (with the outline of the shape going from each
  ///   vertex to the next in order of this list), otherwise the results will be undefined.
  /// @param rounding The [CornerRounding] properties of all vertices. If some vertices should have
  ///   different rounding properties, then use [perVertexRounding] instead. The default rounding value
  ///   is [CornerRounding.Unrounded], meaning that the polygon will use the vertices themselves in the
  ///   final shape and not curves rounded around the vertices.
  /// @param perVertexRounding The [CornerRounding] properties of all vertices. If this parameter is
  ///   not null, then it must have the same size as [vertices]. If this parameter is null, then the
  ///   polygon will use the [rounding] parameter for every vertex instead. The default value is null.
  /// @param centerX The X coordinate of the center of the polygon, around which all vertices will be
  ///   placed. The default center is at (0,0).
  /// @param centerY The Y coordinate of the center of the polygon, around which all vertices will be
  ///   placed. The default center is at (0,0).
  /// @throws IllegalArgumentException if the number of vertices is less than 3 (the [vertices]
  ///   parameter has less than 6 Floats). Or if the [perVertexRounding] parameter is not null and the
  ///   size doesn't match the number vertices.
  // TODO(performance): Update the map calls to more efficient code that doesn't allocate Iterators
  //  unnecessarily.
  factory RoundedPolygon.fromVertices(
    Float32List vertices, {
    CornerRounding rounding = CornerRounding.unrounded,
    List<CornerRounding>? perVertexRounding,
    double centerX = double.nan,
    double centerY = double.nan,
  }) {
    if (vertices.length < 6) {
      throw ArgumentError.value(vertices, "vertices", "Polygons must have at least 3 vertices");
    }
    if (vertices.length.isOdd) {
      throw ArgumentError.value(vertices, "vertices", "The vertices array should have even size");
    }
    if (perVertexRounding != null && perVertexRounding.length * 2 != vertices.length) {
      throw ArgumentError.value(
        perVertexRounding,
        "perVertexRounding",
        "perVertexRounding list should be either null or "
            "the same size as the number of vertices (vertices.size / 2)",
      );
    }
    final corners = <List<Cubic2D>>[];
    final n = vertices.length ~/ 2;
    final roundedCorners = <_RoundedCorner>[];
    for (int i = 0; i < n; i++) {
      final vtxRounding = perVertexRounding?[i] ?? rounding;
      final int prevIndex = ((i + n - 1) % n) * 2;
      final int nextIndex = ((i + 1) % n) * 2;
      roundedCorners.add(
        _RoundedCorner(
          Offset(vertices[prevIndex], vertices[prevIndex + 1]),
          Offset(vertices[i * 2], vertices[i * 2 + 1]),
          Offset(vertices[nextIndex], vertices[nextIndex + 1]),
          rounding: vtxRounding,
        ),
      );
    }

    // For each side, check if we have enough space to do the cuts needed, and if not split
    // the available space, first for round cuts, then for smoothing if there is space left.
    // Each element in this list is a pair, that represent how much we can do of the cut for
    // the given side (side i goes from corner i to corner i+1), the elements of the pair are:
    // first is how much we can use of expectedRoundCut, second how much of expectedCut
    final cutAdjusts = List.generate(growable: false, n, (ix) {
      final expectedRoundCut =
          roundedCorners[ix].expectedRoundCut + roundedCorners[(ix + 1) % n].expectedRoundCut;
      final expectedCut = roundedCorners[ix].expectedCut + roundedCorners[(ix + 1) % n].expectedCut;
      final vtxX = vertices[ix * 2];
      final vtxY = vertices[ix * 2 + 1];
      final nextVtxX = vertices[((ix + 1) % n) * 2];
      final nextVtxY = vertices[((ix + 1) % n) * 2 + 1];
      final sideSize = Offset(vtxX - nextVtxX, vtxY - nextVtxY).distance;

      // Check expectedRoundCut first, and ensure we fulfill rounding needs first for
      // both corners before using space for smoothing
      if (expectedRoundCut > sideSize) {
        // Not enough room for fully rounding, see how much we can actually do.
        return (sideSize / expectedRoundCut, 0.0);
      } else if (expectedCut > sideSize) {
        // We can do full rounding, but not full smoothing.
        return (1.0, (sideSize - expectedRoundCut) / (expectedCut - expectedRoundCut));
      } else {
        // There is enough room for rounding & smoothing.
        return const (1.0, 1.0);
      }
    });
    // Create and store list of beziers for each [potentially] rounded corner
    for (int i = 0; i < n; i++) {
      // allowedCuts[0] is for the side from the previous corner to this one,
      // allowedCuts[1] is for the side from this corner to the next one.
      final allowedCuts = <double>[];
      for (int delta = 0; delta < 2; delta++) {
        final (roundCutRatio, cutRatio) = cutAdjusts[(i + n - 1 + delta) % n];
        allowedCuts.add(
          roundedCorners[i].expectedRoundCut * roundCutRatio +
              (roundedCorners[i].expectedCut - roundedCorners[i].expectedRoundCut) * cutRatio,
        );
      }
      corners.add(roundedCorners[i].getCubics(allowedCuts[0], allowedCuts[1]));
    }
    // Finally, store the calculated cubics. This includes all of the rounded corners
    // from above, along with new cubics representing the edges between those corners.
    final tempFeatures = <Feature>[];
    for (int i = 0; i < n; i++) {
      // Note that these indices are for pairs of values (points), they need to be
      // doubled to access the xy values in the vertices float array
      final prevVtxIndex = (i + n - 1) % n;
      final nextVtxIndex = (i + 1) % n;
      final currVertex = Offset(vertices[i * 2], vertices[i * 2 + 1]);
      final prevVertex = Offset(vertices[prevVtxIndex * 2], vertices[prevVtxIndex * 2 + 1]);
      final nextVertex = Offset(vertices[nextVtxIndex * 2], vertices[nextVtxIndex * 2 + 1]);
      final $convex = convex(prevVertex, currVertex, nextVertex);
      tempFeatures.add(Corner(corners[i], convex: $convex));
      tempFeatures.add(
        Edge([
          Cubic2D.straightLine(
            corners[i].last.anchor1X,
            corners[i].last.anchor1Y,
            corners[(i + 1) % n].first.anchor0X,
            corners[(i + 1) % n].first.anchor0Y,
          ),
        ]),
      );
    }

    return RoundedPolygon.fromFeatures(tempFeatures, centerX: centerX, centerY: centerY);
  }

  /// This constructor takes a list of [Feature] objects that define the polygon's shape and curves. By
  /// specifying the features directly, the summarization of [Cubic2D] objects to curves can be precisely
  /// controlled. This affects [Morph]'s default mapping, as curves with the same type (convex or
  /// concave) are mapped with each other. For example, if you have a convex curve in your start
  /// polygon, [Morph] will map it to another convex curve in the end polygon.
  ///
  /// The [centerX] and [centerY] parameters are optional. If not supplied, they will be estimated by
  /// calculating the average of all cubic anchor points.
  ///
  /// [features] The [Feature]s that describe the characteristics of each outline segment of the
  ///   polygon.
  /// [centerX] The X coordinate of the center of the polygon, around which all vertices will be
  ///   placed. If none provided, the center will be averaged.
  /// [centerY] The Y coordinate of the center of the polygon, around which all vertices will be
  ///   placed. If none provided, the center will be averaged.
  /// Throws [ArgumentError] when [features] specifies less than 2 features which is not enough to describe a
  ///   closed shape.
  factory RoundedPolygon.fromFeatures(
    List<Feature> features, {
    double centerX = double.nan,
    double centerY = double.nan,
  }) {
    if (features.length < 2) {
      throw ArgumentError.value(
        features,
        "features",
        "RoundedPolygon must have at least 2 features",
      );
    }
    if (!centerX.isNaN && !centerY.isNaN)
      return RoundedPolygon._(features, Offset(centerX, centerY));

    final vertices = <double>[];
    for (final feature in features) {
      for (final cubic in feature.cubics) {
        vertices.add(cubic.anchor0X);
        vertices.add(cubic.anchor0Y);
      }
    }
    final calculatedCenter = calculateCenter(Float32List.fromList(vertices));
    final cX = (centerX.isNaN) ? calculatedCenter.dx : centerX;
    final cY = (centerY.isNaN) ? calculatedCenter.dy : centerY;

    return RoundedPolygon._(features, Offset(cX, cY));
  }
}

/// Calculates an estimated center position for the polygon, returning it. This function should only
/// be called if the center is not already calculated or provided. The Polygon constructor which
/// takes `numVertices` calculates its own center, since it knows exactly where it is centered, at
/// (0, 0).
///
/// Note that this center will be transformed whenever the shape itself is transformed. Any
/// transforms that occur before the center is calculated will be taken into account automatically
/// since the center calculation is an average of the current location of all cubic anchor points.
@internal
Offset calculateCenter(Float32List vertices) {
  var cumulativeX = 0.0;
  var cumulativeY = 0.0;
  var index = 0;
  while (index < vertices.length) {
    cumulativeX += vertices[index++];
    cumulativeY += vertices[index++];
  }
  return Offset(cumulativeX / (vertices.length / 2), cumulativeY / (vertices.length / 2));
}

/// Private utility class that holds the information about each corner in a polygon. The shape of the
/// corner can be returned by calling the [getCubics] function, which will return a list of curves
/// representing the corner geometry. The shape of the corner depends on the [rounding] constructor
/// parameter.
///
/// If rounding is null, there is no rounding; the corner will simply be a single point at [p1]. This
/// point will be represented by a [Cubic] of length 0 at that point.
///
/// If rounding is not null, the corner will be rounded either with a curve approximating a circular
/// arc of the radius specified in [rounding], or with three curves if [rounding] has a nonzero
/// smoothing parameter. These three curves are a circular arc in the middle and two symmetrical
/// flanking curves on either side. The smoothing parameter determines the curvature of the flanking
/// curves.
///
/// This is a class because we usually need to do the work in 2 steps, and prefer to keep state
/// between: first we determine how much we want to cut to comply with the parameters, then we are
/// given how much we can actually cut (because of space restrictions outside this corner)
///
/// @param p0 the vertex before the one being rounded
/// @param p1 the vertex of this rounded corner
/// @param p2 the vertex after the one being rounded
/// @param rounding the optional parameters specifying how this corner should be rounded
class _RoundedCorner {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final CornerRounding? rounding;

  late final Offset d1;
  late final Offset d2;
  late final double cornerRadius;
  late final double smoothing;
  late final double cosAngle;
  late final double sinAngle;
  late final double expectedRoundCut;

  _RoundedCorner(this.p0, this.p1, this.p2, {this.rounding}) {
    final v01 = p0 - p1;
    final v21 = p2 - p1;
    final d01 = v01.distance;
    final d21 = v21.distance;
    if (d01 > 0.0 && d21 > 0.0) {
      d1 = v01 / d01;
      d2 = v21 / d21;
      cornerRadius = rounding?.radius ?? 0.0;
      smoothing = rounding?.smoothing ?? 0.0;

      // cosine of angle at p1 is dot product of unit vectors to the other two vertices
      cosAngle = d1.dotProduct(d2);

      // identity: sin^2 + cos^2 = 1
      // sinAngle gives us the intersection
      sinAngle = sqrt(1 - pow(cosAngle, 2));
      // How much we need to cut, as measured on a side, to get the required radius
      // calculating where the rounding circle hits the edge
      // This uses the identity of tan(A/2) = sinA/(1 + cosA), where tan(A/2) = radius/cut
      expectedRoundCut = (sinAngle > 1e-3) ? cornerRadius * (cosAngle + 1) / sinAngle : 0.0;
    } else {
      // One (or both) of the sides is empty, not much we can do.
      d1 = Offset.zero;
      d2 = Offset.zero;
      cornerRadius = 0;
      smoothing = 0;
      cosAngle = 0;
      sinAngle = 0;
      expectedRoundCut = 0;
    }
  }

  /// smoothing changes the actual cut. 0 is same as expectedRoundCut, 1 doubles it
  double get expectedCut => (1 + smoothing) * expectedRoundCut;

  /// the center of the circle approximated by the rounding curve (or the middle of the three
  /// curves if smoothing is requested). The center is the same as p0 if there is no rounding.
  Offset center = Offset.zero;

  List<Cubic2D> getCubics(double allowedCut0, [double? allowedCut1]) {
    allowedCut1 ??= allowedCut0;
    // We use the minimum of both cuts to determine the radius, but if there is more space
    // in one side we can use it for smoothing.
    final allowedCut = min(allowedCut0, allowedCut1);
    // Nothing to do, just use lines, or a point
    if (expectedRoundCut < distanceEpsilon ||
        allowedCut < distanceEpsilon ||
        cornerRadius < distanceEpsilon) {
      center = p1;
      return [Cubic2D.straightLine(p1.dx, p1.dy, p1.dx, p1.dy)];
    }
    // How much of the cut is required for the rounding part.
    final actualRoundCut = min(allowedCut, expectedRoundCut);
    // We have two smoothing values, one for each side of the vertex
    // Space is used for rounding values first. If there is space left over, then we
    // apply smoothing, if it was requested
    final actualSmoothing0 = _calculateActualSmoothingValue(allowedCut0);
    final actualSmoothing1 = _calculateActualSmoothingValue(allowedCut1);
    // Scale the radius if needed
    final actualR = cornerRadius * actualRoundCut / expectedRoundCut;
    // Distance from the corner (p1) to the center
    final centerDistance = sqrt(pow(actualR, 2) + pow(actualRoundCut, 2));
    // Center of the arc we will use for rounding
    center = p1 + ((d1 + d2) / 2).normalize() * centerDistance;
    final circleIntersection0 = p1 + d1 * actualRoundCut;
    final circleIntersection2 = p1 + d2 * actualRoundCut;
    final flanking0 = _computeFlankingCurve(
      actualRoundCut: actualRoundCut,
      actualSmoothingValues: actualSmoothing0,
      corner: p1,
      sideStart: p0,
      circleSegmentIntersection: circleIntersection0,
      otherCircleSegmentIntersection: circleIntersection2,
      circleCenter: center,
      actualR: actualR,
    );
    final flanking2 = _computeFlankingCurve(
      actualRoundCut: actualRoundCut,
      actualSmoothingValues: actualSmoothing1,
      corner: p1,
      sideStart: p2,
      circleSegmentIntersection: circleIntersection2,
      otherCircleSegmentIntersection: circleIntersection0,
      circleCenter: center,
      actualR: actualR,
    ).reverse();
    return [
      flanking0,
      Cubic2D.circularArc(
        center.dx,
        center.dy,
        flanking0.anchor1X,
        flanking0.anchor1Y,
        flanking2.anchor0X,
        flanking2.anchor0Y,
      ),
      flanking2,
    ];
  }

  /// If allowedCut (the amount we are able to cut) is greater than the expected cut (without
  /// smoothing applied yet), then there is room to apply smoothing and we calculate the actual
  /// smoothing value here.
  double _calculateActualSmoothingValue(double allowedCut) {
    if (allowedCut > expectedCut) {
      return smoothing;
    } else if (allowedCut > expectedRoundCut) {
      return smoothing * (allowedCut - expectedRoundCut) / (expectedCut - expectedRoundCut);
    } else {
      return 0;
    }
  }

  /// Compute a Bezier to connect the linear segment defined by corner and sideStart with the
  /// circular segment defined by circleCenter, circleSegmentIntersection,
  /// otherCircleSegmentIntersection and actualR. The bezier will start at the linear segment and
  /// end on the circular segment.
  ///
  /// @param actualRoundCut How much we are cutting of the corner to add the circular segment (this
  ///   is before smoothing, that will cut some more).
  /// @param actualSmoothingValues How much we want to smooth (this is the smooth parameter,
  ///   adjusted down if there is not enough room).
  /// @param corner The point at which the linear side ends
  /// @param sideStart The point at which the linear side starts
  /// @param circleSegmentIntersection The point at which the linear side and the circle intersect.
  /// @param otherCircleSegmentIntersection The point at which the opposing linear side and the
  ///   circle intersect.
  /// @param circleCenter The center of the circle.
  /// @param actualR The radius of the circle.
  /// @return a Bezier cubic curve that connects from the (cut) linear side and the (cut) circular
  ///   segment in a smooth way.
  Cubic2D _computeFlankingCurve({
    required double actualRoundCut,
    required double actualSmoothingValues,
    required Offset corner,
    required Offset sideStart,
    required Offset circleSegmentIntersection,
    required Offset otherCircleSegmentIntersection,
    required Offset circleCenter,
    required double actualR,
  }) {
    // sideStart is the anchor, 'anchor' is actual control point
    final sideDirection = (sideStart - corner).normalize();
    final curveStart = corner + sideDirection * actualRoundCut * (1 + actualSmoothingValues);
    // We use an approximation to cut a part of the circle section proportional to 1 - smooth,
    // When smooth = 0, we take the full section, when smooth = 1, we take nothing.
    // TODO: revisit this, it can be problematic as it approaches 180 degrees
    final p = Offset.lerp(
      circleSegmentIntersection,
      (circleSegmentIntersection + otherCircleSegmentIntersection) / 2.0,
      actualSmoothingValues,
    )!;
    // The flanking curve ends on the circle
    final curveEnd =
        circleCenter + Offset(p.dx - circleCenter.dx, p.dy - circleCenter.dy).normalize() * actualR;
    // The anchor on the circle segment side is in the intersection between the tangent to the
    // circle in the circle/flanking curve boundary and the linear segment.
    final circleTangent = (curveEnd - circleCenter).rotate90();
    final anchorEnd =
        _lineIntersection(sideStart, sideDirection, curveEnd, circleTangent) ??
        circleSegmentIntersection;
    // From what remains, we pick a point for the start anchor.
    // 2/3 seems to come from design tools?
    final anchorStart = (curveStart + anchorEnd * 2.0) / 3.0;
    return Cubic2D.fromOffsets(curveStart, anchorStart, anchorEnd, curveEnd);
  }

  /// Returns the intersection point of the two lines d0->d1 and p0->p1, or null if the lines do
  /// not intersect
  Offset? _lineIntersection(Offset p0, Offset d0, Offset p1, Offset d1) {
    final rotatedD1 = d1.rotate90();
    final den = d0.dotProduct(rotatedD1);
    if (den.abs() < distanceEpsilon) return null;
    final num = (p1 - p0).dotProduct(rotatedD1);
    // Also check the relative value. This is equivalent to abs(den/num) < distanceEpsilon,
    // but avoid doing a division
    if (den.abs() < distanceEpsilon * num.abs()) return null;
    final k = num / den;
    return p0 + d0 * k;
  }
}

Float32List _verticesFromNumVerts(int numVertices, double radius, double centerX, double centerY) {
  final result = Float32List(numVertices * 2);
  var arrayIndex = 0;
  for (int i = 0; i < numVertices; i++) {
    final vertex =
        Offset.fromDirection(pi / numVertices * 2 * i, radius) + Offset(centerX, centerY);
    result[arrayIndex++] = vertex.dx;
    result[arrayIndex++] = vertex.dy;
  }
  return result;
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
