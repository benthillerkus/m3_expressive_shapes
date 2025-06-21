// Ported from Shapes.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/Shapes.kt
// See original license at the end of this file.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'corner_rounding.dart';
import 'rounded_polygon.dart';

/// {@template androidx.shapes.circle}
/// Creates a circular shape, approximating the rounding of the shape around the underlying polygon
/// vertices.
///
/// [numVertices] The number of vertices in the underlying polygon with which to approximate the
///   circle, default value is 8
///
/// [radius] optional radius for the circle, default value is 1.0
///
/// [centerX] X coordinate of optional center for the circle, default value is 0
///
/// [centerY] Y coordinate of optional center for the circle, default value is 0
///
/// Throws [ArgumentError] [numVertices] must be at least 3
/// {@endtemplate}
RoundedPolygon circle({
  int numVertices = 8,
  double radius = 1.0,
  double centerX = 0.0,
  double centerY = 0.0,
}) {
  if (numVertices < 3) {
    throw ArgumentError.value(
      numVertices,
      "numVertices",
      "Circle must have at least three vertices",
    );
  }

  // Half of the angle between two adjacent vertices on the polygon
  final theta = pi / numVertices;
  // Radius of the underlying RoundedPolygon object given the desired radius of the circle
  final polygonRadius = radius / cos(theta);

  return RoundedPolygon.fromNumVerts(
    numVertices,
    rounding: CornerRounding(radius),
    radius: polygonRadius,
    centerX: centerX,
    centerY: centerY,
  );
}

/// {@template androidx.shapes.rectangle}
/// Creates a rectangular shape with the given width/height around the given center. Optional
/// rounding parameters can be used to create a rounded rectangle instead.
///
/// As with all [RoundedPolygon] objects, if this shape is created with default dimensions and
/// center, it is sized to fit within the 2x2 bounding box around a center of (0, 0) and will need to
/// be scaled and moved using [RoundedPolygon.transformed] to fit the intended area in a UI.
///
/// @param width The width of the rectangle, default value is 2
/// @param height The height of the rectangle, default value is 2
/// @param rounding The [CornerRounding] properties of every vertex. If some vertices should have
///   different rounding properties, then use [perVertexRounding] instead. The default rounding value
///   is [CornerRounding.Unrounded], meaning that the polygon will use the vertices themselves in the
///   final shape and not curves rounded around the vertices.
/// @param perVertexRounding The [CornerRounding] properties of every vertex. If this parameter is
///   not null, then it must be of size 4 for the four corners of the shape. If this parameter is
///   null, then the polygon will use the [rounding] parameter for every vertex instead. The default
///   value is null.
/// @param centerX The X coordinate of the center of the rectangle, around which all vertices will be
///   placed equidistantly. The default center is at (0,0).
/// @param centerY The Y coordinate of the center of the rectangle, around which all vertices will be
///   placed equidistantly. The default center is at (0,0).
/// {@endtemplate}
RoundedPolygon rectangle({
  double width = 2,
  double height = 2,
  CornerRounding rounding = CornerRounding.unrounded,
  List<CornerRounding>? perVertexRounding,
  double centerX = 0,
  double centerY = 0,
}) {
  final left = centerX - width / 2;
  final top = centerY - height / 2;
  final right = centerX + width / 2;
  final bottom = centerY + height / 2;

  return RoundedPolygon.fromVertices(
    Float32List.fromList([right, bottom, left, bottom, left, top, right, top]),
    rounding: rounding,
    perVertexRounding: perVertexRounding,
    centerX: centerX,
    centerY: centerY,
  );
}

/// {@template androidx.shapes.star}
/// Creates a star polygon, which is like a regular polygon except every other vertex is on either an
/// inner or outer radius. The two radii specified in the constructor must both both nonzero. If the
/// radii are equal, the result will be a regular (not star) polygon with twice the number of
/// vertices specified in [numVerticesPerRadius].
///
/// @param numVerticesPerRadius The number of vertices along each of the two radii.
/// @param radius Outer radius for this star shape, must be greater than 0. Default value is 1.
/// @param innerRadius Inner radius for this star shape, must be greater than 0 and less than or
///   equal to [radius]. Note that equal radii would be the same as creating a [RoundedPolygon]
///   directly, but with 2 * [numVerticesPerRadius] vertices. Default value is .5.
/// @param rounding The [CornerRounding] properties of every vertex. If some vertices should have
///   different rounding properties, then use [perVertexRounding] instead. The default rounding value
///   is [CornerRounding.Unrounded], meaning that the polygon will use the vertices themselves in the
///   final shape and not curves rounded around the vertices.
/// @param innerRounding Optional rounding parameters for the vertices on the [innerRadius]. If null
///   (the default value), inner vertices will use the [rounding] or [perVertexRounding] parameters
///   instead.
/// @param perVertexRounding The [CornerRounding] properties of every vertex. If this parameter is
///   not null, then it must have the same size as 2 * [numVerticesPerRadius]. If this parameter is
///   null, then the polygon will use the [rounding] parameter for every vertex instead. The default
///   value is null.
/// @param centerX The X coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @param centerY The Y coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @throws IllegalArgumentException if either [radius] or [innerRadius] are <= 0 or
///   [innerRadius] > [radius].
/// {@endtemplate}
RoundedPolygon star(
  int numVerticesPerRadius, {
  double radius = 1,
  double innerRadius = .5,
  CornerRounding rounding = CornerRounding.unrounded,
  CornerRounding? innerRounding,
  List<CornerRounding>? perVertexRounding,
  double centerX = 0,
  double centerY = 0,
}) {
  if (radius <= 0 || innerRadius <= 0) {
    throw ArgumentError.value(
      radius,
      "radius, innerRadius",
      "Star radii must both be greater than 0 (radius: $radius, innerRadius: $innerRadius)",
    );
  }
  if (innerRadius >= radius) {
    throw ArgumentError.value(
      innerRadius,
      "innerRadius",
      "innerRadius ($innerRadius) must be less than radius ($radius)",
    );
  }

  var pvRounding = perVertexRounding;
  // If no per-vertex rounding supplied and caller asked for inner rounding,
  // create per-vertex rounding list based on supplied outer/inner rounding parameters
  if (pvRounding == null && innerRounding != null) {
    pvRounding = Iterable<int>.generate(
      numVerticesPerRadius,
    ).expand((i) => [rounding, innerRounding]).toList();
  }

  // Star polygon is just a polygon with all vertices supplied (where we generate
  // those vertices to be on the inner/outer radii)
  return RoundedPolygon.fromVertices(
    _starVerticesFromNumVerts(numVerticesPerRadius, radius, innerRadius, centerX, centerY),
    rounding: rounding,
    perVertexRounding: pvRounding,
    centerX: centerX,
    centerY: centerY,
  );
}

/// {@template androidx.shapes.pill}
/// A pill shape consists of a rectangle shape bounded by two semicircles at either of the long ends
/// of the rectangle.
///
/// @param width The width of the resulting shape.
/// @param height The height of the resulting shape.
/// @param smoothing the amount by which the arc is "smoothed" by extending the curve from the
///   circular arc on each endcap to the edge between the endcaps. A value of 0 (no smoothing)
///   indicates that the corner is rounded by only a circular arc.
/// @param centerX The X coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @param centerY The Y coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @throws IllegalArgumentException if either [width] or [height] are <= 0.
/// {@endtemplate}
RoundedPolygon pill({
  double width = 2,
  double height = 1,
  double smoothing = 0,
  double centerX = 0,
  double centerY = 0,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value(
      width,
      "width, height",
      "Pill shapes must have positive width and height",
    );
  }

  final wHalf = width / 2;
  final hHalf = height / 2;
  return RoundedPolygon.fromVertices(
    Float32List.fromList([
      wHalf + centerX,
      hHalf + centerY,
      -wHalf + centerX,
      hHalf + centerY,
      -wHalf + centerX,
      -hHalf + centerY,
      wHalf + centerX,
      -hHalf + centerY,
    ]),
    rounding: CornerRounding(min(wHalf, hHalf), smoothing: smoothing),
    centerX: centerX,
    centerY: centerY,
  );
}

/// {@template androidx.shapes.pillStar}
/// A pillStar shape is like a [pill] except it has inner and outer radii along its pill-shaped
/// outline, just like a [star] has inner and outer radii along its circular outline. The parameters
/// for a [pillStar] are similar to those of a [star] except, like [pill], it has a [width] and
/// [height] to determine the general shape of the underlying pill. Also, there is a subtle
/// complication with the way that inner and outer vertices proceed along the circular ends of the
/// shape, depending on the magnitudes of the [rounding], [innerRounding], and [innerRadiusRatio]
/// parameters. For example, a shape with outer vertices that lie along the curved end outline will
/// necessarily have inner vertices that are closer to each other, because of the curvature of that
/// part of the shape. Conversely, if the inner vertices are lined up along the pill outline at the
/// ends, then the outer vertices will be much further apart from each other.
///
/// The default approach, reflected by the default value of [vertexSpacing], is to use the average of
/// the outer and inner radii, such that each set of vertices falls equally to the other side of the
/// pill outline on the curved ends. Depending on the values used for the various rounding and radius
/// parameters, you may want to change that value to suit the look you want. A value of 0 for
/// [vertexSpacing] is equivalent to aligning the inner vertices along the circular curve, and a
/// value of 1 is equivalent to aligning the outer vertices along that curve.
///
/// @param width The width of the resulting shape.
/// @param height The height of the resulting shape.
/// @param numVerticesPerRadius The number of vertices along each of the two radii.
/// @param innerRadiusRatio Inner radius ratio for this star shape, must be greater than 0 and less
///   than or equal to 1. Note that a value of 1 would be similar to creating a [pill], but with more
///   vertices. The default value is .5.
/// @param rounding The [CornerRounding] properties of every vertex. If some vertices should have
///   different rounding properties, then use [perVertexRounding] instead. The default rounding value
///   is [CornerRounding.Unrounded], meaning that the polygon will use the vertices themselves in the
///   final shape and not curves rounded around the vertices.
/// @param innerRounding Optional rounding parameters for the vertices on the [innerRadiusRatio]. If
///   null (the default value), inner vertices will use the [rounding] or [perVertexRounding]
///   parameters instead.
/// @param perVertexRounding The [CornerRounding] properties of every vertex. If this parameter is
///   not null, then it must have the same size as 2 * [numVerticesPerRadius]. If this parameter is
///   null, then the polygon will use the [rounding] parameter for every vertex instead. The default
///   value is null.
/// @param vertexSpacing This factor determines how the vertices on the circular ends are laid out
///   along the outline. A value of 0 aligns spaces the inner vertices the same as those along the
///   straight edges, with the outer vertices then being spaced further apart. A value of 1 does the
///   opposite, with the outer vertices spaced the same as the vertices on the straight edges. The
///   default value is .5, which takes the average of these two extremes.
/// @param startLocation A value from 0 to 1 which determines how far along the perimeter of this
///   shape to start the underlying curves of which it is comprised. This is not usually needed or
///   noticed by the user. But if the caller wants to manually and gradually stroke the path when
///   drawing it, it might matter where that path outline begins and ends. The default value is 0.
/// @param centerX The X coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @param centerY The Y coordinate of the center of the polygon, around which all vertices will be
///   placed. The default center is at (0,0).
/// @throws IllegalArgumentException if either [width] or [height] are <= 0 or if [innerRadiusRatio]
///   is outside the range of (0, 1].
/// {@endtemplate}
RoundedPolygon pillStar({
  double width = 2,
  double height = 1,
  int numVerticesPerRadius = 8,
  double innerRadiusRatio = .5,
  CornerRounding rounding = CornerRounding.unrounded,
  CornerRounding? innerRounding,
  List<CornerRounding>? perVertexRounding,
  double vertexSpacing = 0.5,
  double startLocation = 0,
  double centerX = 0,
  double centerY = 0,
}) {
  if (innerRadiusRatio <= 0 || innerRadiusRatio >= 1) {
    throw ArgumentError.value(innerRadiusRatio, "innerRadiusRatio", "must be between 0 and 1");
  }
  if (vertexSpacing < 0 || vertexSpacing > 1) {
    throw ArgumentError.value(vertexSpacing, "vertexSpacing", "must be between 0 and 1");
  }
  if (startLocation < 0 || startLocation > 1) {
    throw ArgumentError.value(startLocation, "startLocation", "must be between 0 and 1");
  }
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value(
      width,
      "width, height",
      "Pill shapes must have positive width ($width) and height ($height)",
    );
  }
  if (innerRadiusRatio <= 0 || innerRadiusRatio > 1) {
    throw ArgumentError.value(
      innerRadiusRatio,
      "innerRadiusRatio",
      "innerRadius must be between 0 and 1",
    );
  }

  var pvRounding = perVertexRounding;
  // If no per-vertex rounding supplied and caller asked for inner rounding,
  // create per-vertex rounding list based on supplied outer/inner rounding parameters
  if (pvRounding == null && innerRounding != null) {
    pvRounding = Iterable<int>.generate(
      numVerticesPerRadius,
    ).expand((i) => [rounding, innerRounding]).toList();
  }
  return RoundedPolygon.fromVertices(
    _pillStarVerticesFromNumVerts(
      numVerticesPerRadius,
      width,
      height,
      innerRadiusRatio,
      vertexSpacing,
      startLocation,
      centerX,
      centerY,
    ),
    rounding: rounding,
    perVertexRounding: pvRounding,
    centerX: centerX,
    centerY: centerY,
  );
}

Float32List _pillStarVerticesFromNumVerts(
  int numVerticesPerRadius,
  double width,
  double height,
  double innerRadius,
  double vertexSpacing,
  double startLocation,
  double centerX,
  double centerY,
) {
  // The general approach here is to get the perimeter of the underlying pill outline,
  // then the t value for each vertex as we walk that perimeter. This tells us where
  // on the outline to place that vertex, then we figure out where to place the vertex
  // depending on which "section" it is in. The possible sections are the vertical edges
  // on the sides, the circular sections on all four corners, or the horizontal edges
  // on the top and bottom. Note that either the vertical or horizontal edges will be
  // of length zero (whichever dimension is smaller gets only circular curvature for the
  // pill shape).
  final endcapRadius = min(width, height);
  final double vSegLen = max(height - width, 0);
  final double hSegLen = max(width - height, 0);
  final vSegHalf = vSegLen / 2;
  final hSegHalf = hSegLen / 2;
  // vertexSpacing is used to position the vertices on the end caps. The caller has the choice
  // of spacing the inner (0) or outer (1) vertices like those along the edges, causing the
  // other vertices to be either further apart (0) or closer (1). The default is .5, which
  // averages things. The magnitude of the inner and rounding parameters may cause the caller
  // to want a different value.
  final circlePerimeter = pi * 2 * endcapRadius * lerpDouble(innerRadius, 1.0, vertexSpacing)!;
  // perimeter is circle perimeter plus horizontal and vertical sections of inner rectangle,
  // whether either (or even both) might be of length zero.
  final perimeter = 2 * hSegLen + 2 * vSegLen + circlePerimeter;

  // The sections array holds the t start values of that part of the outline. We use these to
  // determine which section a given vertex lies in, based on its t value, as well as where
  // in that section it lies.
  final sections = Float32List(11);
  sections[0] = 0.0;
  sections[1] = vSegLen / 2;
  sections[2] = sections[1] + circlePerimeter / 4;
  sections[3] = sections[2] + hSegLen;
  sections[4] = sections[3] + circlePerimeter / 4;
  sections[5] = sections[4] + vSegLen;
  sections[6] = sections[5] + circlePerimeter / 4;
  sections[7] = sections[6] + hSegLen;
  sections[8] = sections[7] + circlePerimeter / 4;
  sections[9] = sections[8] + vSegLen / 2;
  sections[10] = perimeter;

  // "t" is the length along the entire pill outline for a given vertex. With vertices spaced
  // evenly along this contour, we can determine for any vertex where it should lie.
  final tPerVertex = perimeter / (2 * numVerticesPerRadius);
  // separate iteration for inner vs outer, unlike the other shapes, because
  // the vertices can lie in different quadrants so each needs their own calculation
  var inner = false;
  // Increment section index as we walk around the pill contour with our increasing t values
  var currSecIndex = 0;
  // secStart/End are used to determine how far along a given vertex is in the section
  // in which it lands
  var secStart = 0.0;
  var secEnd = sections[1];
  // t value is used to place each vertex. 0 is on the positive x axis,
  // moving into section 0 to begin with. startLocation, a value from 0 to 1, varies the location
  // anywhere on the perimeter of the shape
  var t = startLocation * perimeter;
  // The list of vertices to be returned
  final result = Float32List(numVerticesPerRadius * 4);
  var arrayIndex = 0;
  final rect = Rect.fromLTRB(-hSegHalf, -vSegHalf, hSegHalf, vSegHalf);
  // Each iteration through this loop uses the next t value as we walk around the shape
  for (int i = 0; i < numVerticesPerRadius * 2; i++) {
    // t could start (and end) after 0; extra boundedT logic makes sure it does the right
    // thing when crossing the boundar past 0 again
    final boundedT = t % perimeter;
    if (boundedT < secStart) currSecIndex = 0;
    while (boundedT >= sections[(currSecIndex + 1) % sections.length]) {
      currSecIndex = (currSecIndex + 1) % sections.length;
      secStart = sections[currSecIndex];
      secEnd = sections[(currSecIndex + 1) % sections.length];
    }

    // find t in section and its proportion of that section's total length
    final tInSection = boundedT - secStart;
    final tProportion = tInSection / (secEnd - secStart);

    // The vertex placement in a section varies depending on whether it is on one of the
    // semicircle endcaps or along one of the straight edges. For the endcaps, we use
    // tProportion to get the angle along that circular cap and add
    // the starting angle for that section. For the edges we use a straight linear calculation
    // given tProportion and the start/end t values for that edge.
    final currRadius = inner ? (endcapRadius * innerRadius) : endcapRadius;
    final vertex = switch (currSecIndex) {
      0 => Offset(currRadius, tProportion * vSegHalf),
      1 => Offset.fromDirection(tProportion * pi / 2, currRadius) + rect.bottomRight,
      2 => Offset(hSegHalf - tProportion * hSegLen, currRadius),
      3 => Offset.fromDirection(pi / 2 + (tProportion * pi / 2), currRadius) + rect.bottomLeft,
      4 => Offset(-currRadius, vSegHalf - tProportion * vSegLen),
      5 => Offset.fromDirection(pi + (tProportion * pi / 2), currRadius) + rect.topLeft,
      6 => Offset(-hSegHalf + tProportion * hSegLen, -currRadius),
      7 => Offset.fromDirection(pi * 1.5 + (tProportion * pi / 2), currRadius) + rect.topRight,
      // 8
      _ => Offset(currRadius, -vSegHalf + tProportion * vSegHalf),
    };
    result[arrayIndex++] = vertex.dx + centerX;
    result[arrayIndex++] = vertex.dy + centerY;
    t += tPerVertex;
    inner = !inner;
  }
  return result;
}

Float32List _starVerticesFromNumVerts(
  int numVerticesPerRadius,
  double radius,
  double innerRadius,
  double centerX,
  double centerY,
) {
  final result = Float32List(numVerticesPerRadius * 4);
  var arrayIndex = 0;
  for (int i = 0; i < numVerticesPerRadius; i++) {
    var vertex = Offset.fromDirection(pi / numVerticesPerRadius * 2 * i, radius);
    result[arrayIndex++] = vertex.dx + centerX;
    result[arrayIndex++] = vertex.dy + centerY;
    vertex = Offset.fromDirection(pi / numVerticesPerRadius * (2 * i + 1), innerRadius);
    result[arrayIndex++] = vertex.dx + centerX;
    result[arrayIndex++] = vertex.dy + centerY;
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
