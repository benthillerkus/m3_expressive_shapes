// Ported from PolygonValidation.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/PolygonValidation.kt
// See original license at the end of this file.

import 'package:androidx_graphics_shapes/rounded_polygon.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

// TODO: b/372000685 b/372003785 b/372004969
//  Make class public as soon as all validations
//  are implemented and mention in [RoundedPolygon] constructor

/// Utility class to fix invalid [RoundedPolygon]s that will otherwise break [Morph]s in one way or
/// another, as [RoundedPolygon] assumes correct input. Correct input meaning:
/// - Closed geometry
/// - Clockwise orientation of points
/// - No self-intersections
/// - No holes
/// - Single Polygon
@internal
class PolygonValidator {
  // TODO: b/372000685 b/372003785 b/372004969
  // Update docs when other validations are implemented
  /// Validates whether this [RoundedPolygon]'s orientation is clockwise and fixes it if
  /// necessary.
  ///
  /// @param polygon The [RoundedPolygon] to validate
  /// @return A new [RoundedPolygon] with fixed orientation, or the same [RoundedPolygon] as
  ///   given when it was already valid
  static RoundedPolygon fix(RoundedPolygon polygon) {
    var result = polygon;

    log.fine("Validating polygon...");

    if (_isCWOriented(polygon)) {
      log.fine("Passed clockwise validation!");
    } else {
      log.fine("Polygon is oriented anti-clockwise, fixing orientation...");
      result = _fixCWOrientation(polygon);
    }

    return result;
  }

  static bool _isCWOriented(RoundedPolygon polygon) {
    double signedArea = 0;

    for (final cubic in polygon.cubics) {
      signedArea += (cubic.anchor1X - cubic.anchor0X) * (cubic.anchor1Y + cubic.anchor0Y);
    }

    return signedArea < 0;
  }

  static RoundedPolygon _fixCWOrientation(RoundedPolygon polygon) {
    // Persist first feature to stay a Corner
    final reversedFeatures = [
      polygon.features.first.reversed(),
      for (final feature in polygon.features.skip(1).toList().reversed) feature.reversed(),
    ];

    return RoundedPolygon.fromFeatures(
      reversedFeatures,
      centerX: polygon.centerX,
      centerY: polygon.centerY,
    );
  }
}

final log = Logger("PolygonValidation");

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
