// Ported from CornerRounding.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/CornerRounding.kt
// See original license at the end of this file.

/// CornerRounding defines the amount and quality around a given vertex of a shape. [radius] defines
/// the radius of the circle which forms the basis of the rounding for the vertex. [smoothing]
/// defines the amount by which the curve is extended from the circular arc around the corner to the
/// edge between vertices.
///
/// Each corner of a shape can be thought of as either: <em>
/// <li> unrounded (with a corner radius of 0 and no smoothing) </li>
/// <li> rounded with only a circular arc (with smoothing of 0). In this case, the rounding around
///   the corner follows an approximated circular arc between the edges to adjacent vertices. </li>
/// <li> rounded with three curves: There is an inner circular arc and two symmetric flanking curves.
///   The flanking curves determine the curvature from the inner curve to the edges, with a value of
///   0 (no smoothing) meaning that it is purely a circular curve and a value of 1 meaning that the
///   flanking curves are maximized between the inner curve and the edges. </em>
class CornerRounding {
  const CornerRounding({this.radius = 0, this.smoothing = 0})
    : assert(radius >= 0 && smoothing >= 0 && smoothing <= 1);

  /// A value of 0 or greater, representing the radius of the circle which defines the
  ///   inner rounding arc of the corner.
  ///
  /// A value of 0 indicates that the corner is sharp, or completely unrounded. A positive value is the requested size of the radius. Note that this
  ///   radius is an absolute size that should relate to the overall size of its shape. Thus if the
  ///   shape is in screen coordinate size, the radius should be sized appropriately. If the shape is
  ///   in some canonical form (bounds of (-1,-1) to (1,1), for example, which is the default when
  ///   creating a [RoundedPolygon] from a number of vertices), then the radius should be relative to
  ///   that size. The radius will be scaled if the shape itself is transformed, since it will produce
  ///   curves which round the corner and thus get transformed along with the overall shape.
  final double radius;

  /// The amount by which the arc is "smoothed" by extending the curve from the inner
  ///   circular arc to the edge between vertices.
  ///
  /// A value of 0 (no smoothing) indicates that the
  ///   corner is rounded by only a circular arc; there are no flanking curves.
  ///
  /// A value of 1 indicates
  ///   that there is no circular arc in the center; the flanking curves on either side meet at the
  ///   middle.
  final double smoothing;

  /// [Unrounded] has a rounding radius of zero, producing a sharp corner at a vertex.
  static const unrounded = const CornerRounding();
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
