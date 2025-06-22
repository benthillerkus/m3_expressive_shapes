import 'dart:ui';

import 'package:flutter/painting.dart';

class TriangleBorder extends ShapeBorder {
  const TriangleBorder({Paint? paint, this.width = 8}) : _paint = paint;

  final Paint? _paint;
  final double width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsetsGeometry.all(width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..moveTo(rect.center.dx, rect.top - width)
      ..lineTo(rect.right + width * rect.width / rect.height, rect.bottom + width)
      ..lineTo(rect.left - width * rect.width / rect.height, rect.bottom + width)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..moveTo(rect.left + rect.width / 2, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final inner = getInnerPath(rect);
    final outer = getOuterPath(rect);
    final path = outer
      ..fillType = PathFillType.evenOdd
      ..addPath(inner, Offset.zero);
    canvas.drawPath(path, _paint ?? Paint());
  }

  @override
  ShapeBorder scale(double t) {
    return TriangleBorder(paint: _paint, width: width * t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is TriangleBorder) {
      return TriangleBorder(paint: _paint, width: lerpDouble(width, b.width, t)!);
    }
    return super.lerpTo(b, t);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is TriangleBorder) {
      return TriangleBorder(paint: _paint, width: lerpDouble(a.width, width, t)!);
    }
    return super.lerpFrom(a, t);
  }
}
