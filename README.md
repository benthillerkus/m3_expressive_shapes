[![codecov](https://codecov.io/gh/benthillerkus/m3_expressive_shapes/graph/badge.svg?token=BI0aUtvgn3)](https://codecov.io/gh/benthillerkus/m3_expressive_shapes)

## m3_expressive_shapes

A Flutter port of the morphing shapes from Android's implementation Material 3 _Expressive_.

This repository has two packages:
- [androidx_graphics_shapes](packages/androidx_graphics_shapes) with a port of the underlying library
- and [m3_expressive_shapes](packages/m3_expressive_shapes) with presets for the _expressive_ shapes from the Material Design specification.

## Alternative

@kekland made a similar port: https://github.com/kekland/m3_expressive_shapes

## Development

This package uses [pre-commit](https://pre-commit.com/) for managing git hooks and assumes you installed Flutter through [puro](http://puro.dev).

Not being able to run the hooks isn't dramatic, but the CI will reject unformatted code, so you should run `dart format .` in some way locally before committing.
