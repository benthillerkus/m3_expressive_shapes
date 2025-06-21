// Ported from FeatureMapping.kt in https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/FeatureMapping.kt
// See original license at the end of this file.

import 'dart:core';
import 'dart:ui';

import 'package:androidx_graphics_shapes/src/utils.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'features.dart';
import 'float_mapping.dart';

/// MeasuredFeatures contains a list of all features in a polygon along with the [0..1] progress at
/// that feature
typedef MeasuredFeatures = List<ProgressableFeature>;

@internal
class ProgressableFeature {
  const ProgressableFeature(this.feature, this.progress);

  final Feature feature;
  final double progress;

  @override
  String toString() => "ProgressableFeature(feature=$feature, progress=$progress)";
}

/// featureMapper creates a mapping between the "features" (rounded corners) of two shapes
DoubleMapper featureMapper(MeasuredFeatures features1, MeasuredFeatures features2) {
  // We only use corners for this mapping.
  final filteredFeatures1 = [
    for (final f in features1)
      if (f.feature is Corner) f,
  ];
  final filteredFeatures2 = [
    for (final f in features2)
      if (f.feature is Corner) f,
  ];

  final featureProgressMapping = doMapping(filteredFeatures1, filteredFeatures2);

  _log.fine(featureProgressMapping.map((it) => "${it.$1} -> ${it.$2}").join(", "));

  final res = DoubleMapper(featureProgressMapping);
  {
    final N = 10;
    _log.fine(
      "Map: ${List.generate(growable: false, N, (i) => res.map(i / N).toStringAsPrecision(3)).join(", ")}\nMb : ${List.generate(growable: false, N, (i) => res.mapBack(i / N).toStringAsPrecision(3)).join(", ")}",
    );
  }
  return res;
}

@internal
@immutable
class DistanceVertex {
  const DistanceVertex(this.distance, this.f1, this.f2);

  final double distance;
  final ProgressableFeature f1;
  final ProgressableFeature f2;

  @override
  String toString() => "DistanceVertex(distance=$distance, f1=${f1.progress}, f2=${f2.progress})";
}

/// Returns a mapping of the features between features1 and features2. The return is a list of pairs
/// in which the first element is the progress of a feature in features1 and the second element is
/// the progress of the feature in features2 that we mapped it to. The list is sorted by the first
/// element. To do this:
/// 1) Compute the distance for all pairs of features in (features1 x features2),
/// 2) Sort ascending by by such distance
/// 3) Try to add them, from smallest distance to biggest, ensuring that: a) The features we are
///    mapping haven't been mapped yet. b) We are not adding a crossing in the mapping. Since the
///    mapping is sorted by the first element of each pair, this means that the second elements of
///    each pair are monotonically increasing, except maybe one time (Counting all pair of
///    consecutive elements, and the last element to first element).
List<(double, double)> doMapping(
  List<ProgressableFeature> features1,
  List<ProgressableFeature> features2,
) {
  _log.fine("Shape1 progresses: ${features1.map((it) => it.progress).join(",")}");
  _log.fine("Shape2 progresses: ${features2.map((it) => it.progress).join(",")}");
  final distanceVertexList = <DistanceVertex>[
    for (final f1 in features1)
      for (final f2 in features2)
        if (featureDistSquared(f1.feature, f2.feature) case final d when d != double.infinity)
          DistanceVertex(d, f1, f2),
  ]..sort((a, b) => a.distance.compareTo(b.distance));

  // Special cases.
  if (distanceVertexList.isEmpty) return identityMapping;
  if (distanceVertexList.length == 1) {
    final it = distanceVertexList.first;
    final f1 = it.f1.progress;
    final f2 = it.f2.progress;
    return [(f1, f2), ((f1 + 0.5) % 1.0, (f2 + 0.5) % 1.0)];
  }
  final helper = _MappingHelper();
  for (final it in distanceVertexList) {
    helper.addMapping(it.f1, it.f2);
  }
  return helper.mapping;
}

const identityMapping = [(0.0, 0.0), (0.5, 0.5)];

class _MappingHelper {
  // List of mappings from progress in the start shape to progress in the end shape.
  // We keep this list sorted by the first element.
  final mapping = <(double, double)>[];

  // Which features in the start shape have we used and which in the end shape.
  final _usedF1 = <ProgressableFeature>{};
  final _usedF2 = <ProgressableFeature>{};

  void addMapping(ProgressableFeature f1, ProgressableFeature f2) {
    // We don't want to map the same feature twice.
    if (_usedF1.contains(f1) || _usedF2.contains(f2)) return;

    // Ret is sorted, find where we need to insert this new mapping
    final int insertionIndex;
    try {
      insertionIndex = mapping.map((e) => e.$1).insertionIndex(f1.progress);
    } on ArgumentError {
      throw StateError("There can't be two features with the same progress: f1: $f1");
    }
    final n = mapping.length;

    // We can always add the first 1 element
    if (n >= 1) {
      final (before1, before2) = mapping[(insertionIndex + n - 1) % n];
      final (after1, after2) = mapping[insertionIndex % n];

      // We don't want features that are way too close to each other, that will make the
      // DoubleMapper unstable
      if (progressDistance(f1.progress, before1) < distanceEpsilon ||
          progressDistance(f1.progress, after1) < distanceEpsilon ||
          progressDistance(f2.progress, before2) < distanceEpsilon ||
          progressDistance(f2.progress, after2) < distanceEpsilon) {
        return;
      }

      // When we have 2 or more elements, we need to ensure we are not adding extra crossings.
      if (n > 1 && !progressInRange(f2.progress, before2, after2)) return;
    }

    // All good, we can add the mapping.
    mapping.insert(insertionIndex, (f1.progress, f2.progress));
    _usedF1.add(f1);
    _usedF2.add(f2);
  }
}

extension InsertionIndexExt<T extends Comparable<T>> on Iterable<T> {
  /// Returns the index at which the element should be inserted to keep the list sorted.
  ///
  /// Throws an [ArgumentError] if [element] is already in the list.
  int insertionIndex(T element) {
    int index = 0;
    int cmp;
    for (final e in this) {
      cmp = element.compareTo(e);
      if (cmp == 0) {
        throw ArgumentError.value(
          element,
          "element",
          "Element already exists in the iterable at index $index",
        );
      }
      if (cmp < 0) return index;
      index++;
    }
    return index;
  }
}

/// Returns distance along overall shape between two Features on the two different shapes. This
/// information is used to determine how to map features (and the curves that make up those
/// features).
@internal
double featureDistSquared(Feature f1, Feature f2) {
  // TODO: We might want to enable concave-convex matching in some situations. If so, the
  //  approach below will not work
  if (f1 is Corner && f2 is Corner && f1.convex != f2.convex) {
    // Simple hack to force all features to map only to features of the same concavity, by
    // returning an infinitely large distance in that case
    _log.fine("*** Feature distance ∞ for convex-vs-concave corners");
    return double.infinity;
  }
  return (featureRepresentativePoint(f1) - featureRepresentativePoint(f2)).distanceSquared;
}

// TODO: b/378441547 - Move to explicit parameter / expose?
@internal
Offset featureRepresentativePoint(Feature feature) {
  return (feature.cubics.first.anchor0 + feature.cubics.last.anchor1) / 2;
}

final _log = Logger("FeatureMapping");

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
