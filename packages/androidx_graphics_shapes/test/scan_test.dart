import 'package:androidx_graphics_shapes/scan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("initial element is first", () {
    final iterable = const Iterable<void>.empty().scan(#hi, (_, _) => throw Never);
    expect(iterable, containsAllInOrder([#hi]));
  });

  test("length is original length + 1", () {
    final iterable = Iterable<dynamic>.generate(500).scan(null, (_, _) => throw Never);
    expect(iterable, hasLength(501));
  });

  test("accumulate sum scan", () {
  const myList = [2, 5, 1, 3, 6];
    final scanned = myList.scan(0, (acc, curr) {
      return acc + curr;
    }).toList();
    expect(scanned, containsAllInOrder([0, 2, 7, 8, 11, 17]));
  });
}
