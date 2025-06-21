// Ported from PolygonMeasure.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/PolygonMeasure.kt
// See original license at the end of this file.

import "dart:collection";
import "dart:ui";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import 'package:meta/meta.dart';

import "cubic.dart";
import "feature_mapping.dart";
import "features.dart";
import "rounded_polygon.dart";
import "scan.dart";
import "utils.dart";

@internal
class MeasuredPolygon extends DelegatingList<MeasuredCubic> {
  final Measurer _measurer;
  List<MeasuredCubic> get _cubics => this;
  @internal
  final List<ProgressableFeature> features;

  MeasuredPolygon._(
    Measurer measurer,
    List<ProgressableFeature> features,
    List<Cubic2D> cubics,
    Float32List outlineProgress,
  ) : _measurer = measurer,
      features = UnmodifiableListView(features),
      super([]) {
    if (outlineProgress.length != cubics.length + 1) {
      throw ArgumentError.value(
        outlineProgress,
        "outlineProgress",
        "Outline progress size is expected to be the cubics size (${cubics.length}) + 1 (actual: ${outlineProgress.length})",
      );
    }
    if (outlineProgress.first != 0) {
      throw ArgumentError.value(
        outlineProgress.first,
        "outlineProgress",
        "First outline progress value is expected to be zero",
      );
    }
    if (outlineProgress.last != 1) {
      throw ArgumentError.value(
        outlineProgress.last,
        "outlineProgress",
        "Last outline progress value is expected to be one",
      );
    }

    if (kDebugMode) {
      _log.fine("CTOR: cubics = ${cubics.join()}\nCTOR: op = ${outlineProgress.join()}");
    }
    final measuredCubics = <MeasuredCubic>[];
    var startOutlineProgress = 0.0;
    for (int index = 0; index < cubics.length; index++) {
      // Filter out "empty" cubics
      if ((outlineProgress[index + 1] - outlineProgress[index]) > distanceEpsilon) {
        measuredCubics.add(
          MeasuredCubic(this, cubics[index], startOutlineProgress, outlineProgress[index + 1]),
        );
        // The next measured cubic will start exactly where this one ends.
        startOutlineProgress = outlineProgress[index + 1];
      }
    }
    // We could have removed empty cubics at the end. Ensure the last measured cubic ends at 1f
    measuredCubics[measuredCubics.length - 1].updateProgressRange(endOutlineProgress: 1);
    addAll(measuredCubics);
  }

  /// Finds the point in the input list of measured cubics that pass the given outline progress,
  /// and generates a new MeasuredPolygon (equivalent to this), that starts at that point. This
  /// usually means cutting the cubic that crosses the outline progress (unless the cut is at one
  /// of its ends) For example, given outline progress 0.4f and measured cubics on these outline
  /// progress ranges:
  ///
  /// c1 [0 -> 0.2] c2 [0.2 -> 0.5] c3 [0.5 -> 1.0]
  ///
  /// c2 will be cut in two, at the given outline progress, we can name these c2a [0.2 -> 0.4] and
  /// c2b [0.4 -> 0.5]
  ///
  /// The return then will have measured cubics [c2b, c3, c1, c2a], and they will have their
  /// outline progress ranges adjusted so the new list starts at 0. c2b [0 -> 0.1] c3 [0.1 -> 0.6]
  /// c1 [0.6 -> 0.8] c2a [0.8 -> 1.0]
  MeasuredPolygon cutAndShift(double cuttingPoint) {
    if (cuttingPoint < 0 || cuttingPoint > 1) {
      throw ArgumentError.value(
        cuttingPoint,
        "cuttingPoint",
        "Cutting point is expected to be between 0 and 1",
      );
    }
    if (cuttingPoint < distanceEpsilon) return this;

    // Find the index of cubic we want to cut
    final targetIndex = _cubics.indexWhere(
      (it) => cuttingPoint >= it.startOutlineProgress && cuttingPoint <= it.endOutlineProgress,
    );
    final target = _cubics[targetIndex];
    if (kDebugMode) {
      for (final (index, cubic) in _cubics.indexed) {
        _log.fine("cut&Shift | cubic #$index : $cubic ");
      }

      _log.fine("cut&Shift, cuttingPoint = $cuttingPoint, target = ($targetIndex) $target");
    }
    // Cut the target cubic.
    // b1, b2 are two resulting cubics after cut
    final (b1, b2) = target.cutAtProgress(cuttingPoint);
    _log.fine("Split | $target -> $b1 & $b2");

    // Construct the list of the cubics we need:
    // * The second part of the target cubic (after the cut)
    // * All cubics after the target, until the end + All cubics from the start, before the
    //   target cubic
    // * The first part of the target cubic (before the cut)
    final retCubics = [
      b2.cubic,
      for (int i = 1; i < _cubics.length; i++) _cubics[(i + targetIndex) % _cubics.length].cubic,
      b1.cubic,
    ];

    // Construct the array of outline progress.
    // For example, if we have 3 cubics with outline progress [0 .. 0.3], [0.3 .. 0.8] &
    // [0.8 .. 1.0], and we cut + shift at 0.6:
    // 0.  0123456789
    //     |--|--/-|-|
    // The outline progresses will start at 0 (the cutting point, that shifs to 0.0),
    // then 0.8 - 0.6 = 0.2, then 1 - 0.6 = 0.4, then 0.3 - 0.6 + 1 = 0.7,
    // then 1 (the cutting point again),
    // all together: (0.0, 0.2, 0.4, 0.7, 1.0)
    final retOutlineProgress = Float32List(_cubics.length + 2)
      ..[0] = 0.0
      ..[_cubics.length + 1] = 1.0;
    retOutlineProgress.setAll(
      1,
      Iterable.generate(
        _cubics.length,
        (index) =>
            (_cubics[(targetIndex + index) % _cubics.length]._endOutlineProgress - cuttingPoint) %
            1,
      ),
    );

    // Shift the feature's outline progress too.
    final newFeatures = [
      for (final feature in features)
        ProgressableFeature(feature.feature, (feature.progress - cuttingPoint) % 1),
    ];

    // Filter out all empty cubics (i.e. start and end anchor are (almost) the same point.)
    return MeasuredPolygon._(_measurer, newFeatures, retCubics, retOutlineProgress);
  }

  @internal
  factory MeasuredPolygon.measurePolygon(Measurer measurer, RoundedPolygon polygon) {
    final cubics = <Cubic2D>[];
    final featureToCubic = <(Feature, int)>[];

    // Get the cubics from the polygon, at the same time, extract the features and keep a
    // reference to the representative cubic we will use.
    for (final feature in polygon.features) {
      for (int cubicIndex = 0; cubicIndex < feature.cubics.length; cubicIndex++) {
        if (feature is Corner && cubicIndex == feature.cubics.length ~/ 2) {
          featureToCubic.add((feature, cubics.length));
        }
        cubics.add(feature.cubics[cubicIndex]);
      }
    }
    // TODO(performance): Make changes to satisfy the lint warnings for unnecessary
    //  iterators creation.
    final measures = cubics
        .scan<double>(0, (measure, cubic) {
          final it = measurer.measureCubic(cubic);
          if (it < 0) {
            throw ArgumentError.value(
              it,
              "cubic",
              "Measured cubic is expected to be greater or equal to zero",
            );
          }
          return measure + it;
        })
        .toList(growable: false);
    final totalMeasure = measures.last;

    // Equivalent to `measures.map { it / totalMeasure }` but without Iterator allocation.
    final outlineProgress = Float32List(measures.length);
    outlineProgress.setAll(0, measures.map((measure) => measure / totalMeasure));

    _log.fine("Total size: $totalMeasure");

    final features = [
      for (final feature in featureToCubic)
        ProgressableFeature(feature.$1, () {
          final double a = outlineProgress[feature.$2];
          final double b = outlineProgress[feature.$2 + 1];
          final double c = a + b;
          final double d = c / 2;
          return d % 1;
        }()),
    ];

    return MeasuredPolygon._(measurer, features, cubics, outlineProgress);
  }
}

/// A MeasuredCubic holds information about the cubic itself, the feature (if any) associated
/// with it, and the outline progress values (start and end) for the cubic. This information is
/// used to match cubics between shapes that lie at similar outline progress positions along
/// their respective shapes (after matching features and shifting).
///
/// Outline progress is a value in [0..1) that represents the distance traveled along the overall
/// outline path of the shape.
@internal
class MeasuredCubic {
  MeasuredCubic(this.polygon, this.cubic, double startOutlineProgress, double endOutlineProgress)
    : assert(startOutlineProgress >= 0.0 && startOutlineProgress <= 1.0),
      assert(endOutlineProgress >= 0.0 && endOutlineProgress <= 1.0),
      assert(endOutlineProgress >= startOutlineProgress),
      _startOutlineProgress = startOutlineProgress,
      _endOutlineProgress = endOutlineProgress;

  final Cubic2D cubic;

  final MeasuredPolygon polygon;

  late final measuredSize = polygon._measurer.measureCubic(cubic);

  double _startOutlineProgress;
  double _endOutlineProgress;

  double get startOutlineProgress => _startOutlineProgress;

  double get endOutlineProgress => _endOutlineProgress;

  @internal
  void updateProgressRange({double? startOutlineProgress, double? endOutlineProgress}) {
    startOutlineProgress ??= _startOutlineProgress;
    endOutlineProgress ??= _endOutlineProgress;

    if (endOutlineProgress < startOutlineProgress) {
      throw ArgumentError.value(
        endOutlineProgress,
        "endOutlineProgress",
        "endOutlineProgress is expected to be equal or greater than startOutlineProgress",
      );
    }
    _startOutlineProgress = startOutlineProgress;
    _endOutlineProgress = endOutlineProgress;
  }

  /// Cut this MeasuredCubic into two MeasuredCubics at the given outline progress value.
  (MeasuredCubic, MeasuredCubic) cutAtProgress(double cutOutlineProgress) {
    // Floating point errors further up can cause cutOutlineProgress to land just
    // slightly outside of the start/end progress for this cubic, so we limit it
    // to those bounds to avoid further errors later
    final boundedCutOutlineProgress = cutOutlineProgress.clamp(
      startOutlineProgress,
      endOutlineProgress,
    );
    final outlineProgressSize = endOutlineProgress - startOutlineProgress;
    final progressFromStart = boundedCutOutlineProgress - startOutlineProgress;

    // Note that in earlier parts of the computation, we have empty MeasuredCubics (cubics
    // with progressSize == 0f), but those cubics are filtered out before this method is
    // called.
    final relativeProgress = progressFromStart / outlineProgressSize;
    final t = polygon._measurer.findCubicCutPoint(cubic, relativeProgress * measuredSize);
    if (t < 0 || t > 1) {
      throw ArgumentError.value(
        t,
        "cubicCutPoint",
        "Cubic cut point is expected to be between 0 and 1",
      );
    }

    _log.fine(
      "cutAtProgress: progress = $boundedCutOutlineProgress / "
      "this = [$startOutlineProgress .. $endOutlineProgress] / "
      "ps = $progressFromStart / rp = $relativeProgress / t = $t",
    );

    // c1/c2 are the two new cubics, then we return MeasuredCubics created from them
    final (c1, c2) = cubic.split(t);
    return (
      MeasuredCubic(polygon, c1, startOutlineProgress, boundedCutOutlineProgress),
      MeasuredCubic(polygon, c2, boundedCutOutlineProgress, endOutlineProgress),
    );
  }

  @override
  String toString() {
    return "MeasuredCubic(outlineProgress="
        "[$startOutlineProgress .. $endOutlineProgress], "
        "size=$measuredSize, cubic=$cubic)";
  }
}

/// Interface for measuring a cubic. Implementations can use whatever algorithm desired to produce
/// these measurement values.
@internal
abstract interface class Measurer {
  const Measurer();

  /// Returns size of given cubic, according to however the implementation wants to measure the
  /// size (angle, length, etc). It has to be greater or equal to 0.
  double measureCubic(Cubic2D c);

  /// Given a cubic and a measure that should be between 0 and the value returned by measureCubic
  /// (If not, it will be capped), finds the parameter t of the cubic at which that measure is
  /// reached.
  double findCubicCutPoint(Cubic2D c, double m);
}

/// Approximates the arc lengths of cubics by splitting the arc into segments and calculating their
/// sizes. The more segments, the more accurate the result will be to the true arc length. The
/// default implementation has at least 98.5% accuracy on the case of a circular arc, which is the
/// worst case for our standard shapes.
@internal
class LengthMeasurer implements Measurer {
  const LengthMeasurer();

  // The minimum number needed to achieve up to 98.5% accuracy from the true arc length
  // See PolygonMeasureTest.measureCircle
  static const double _segments = 3;

  @override
  double measureCubic(Cubic2D c) {
    return _closestProgressTo(c, double.infinity).$2;
  }

  @override
  double findCubicCutPoint(Cubic2D c, double m) {
    return _closestProgressTo(c, m).$1;
  }

  (double, double) _closestProgressTo(Cubic2D cubic, double threshold) {
    var total = 0.0;
    var remainder = threshold;
    var prev = Offset(cubic.anchor0X, cubic.anchor0Y);

    for (int i = 1; i <= _segments; i++) {
      final progress = i / _segments;
      final point = cubic.transform(progress);
      final segment = (point - prev).distance;

      if (segment >= remainder) {
        return (progress - (1.0 - remainder / segment) / _segments, threshold);
      }

      remainder -= segment;
      total += segment;
      prev = point;
    }

    return (1.0, total);
  }
}

final _log = Logger("PolygonMeasure");

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
