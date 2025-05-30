A port of the [AndroidX Graphics-Shapes library](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/) which implements shape morphing for 2D Cubic Beziers; which is required for the expressive shape animations of M3.

## Features

- Cubic Beziers as a Curve2D subclass
- Intelligent morphing between Cubic Beziers
- Rudimentary SVG parsing for Cubic Beziers
- Corner radii

## Getting started

Despite the name, this package is entirely independent of Android and can be used in any Flutter project.
In theory Dart could be supported, but to make usage with Flutter more convenient it uses Flutter exclusive data structures such as `Offset` and `ShapeBorder`.

## Usage

See the [m3_expressive_shapes](https://pub.dev/packages/m3_expressive_shapes) package for an implementation of the Material 3 Expressive shapes using this package.

## Additional information

The port has been mostly done by hand, copying the original code and the rewriting it in Dart.
It differs in some ways from the original though; it uses where possible existing Dart and Flutter idioms and data structures,
and it does not try to have an immutable API like the original.

## Licensing

The original code is licensed under the following license:

```
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
```

and can be found in the [AndroidX Graphics-Shapes repository](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:graphics/graphics-shapes/).

The Dart port has been licensed under the license found in [LICENSE.md].

