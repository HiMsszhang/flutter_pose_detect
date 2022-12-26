// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:collection/collection.dart';

void main() {
  // queue that prioritizes longer strings
  final queue = PriorityQueue<int>((a, b) => (a.compareTo(b)));
  queue
    ..add(7)
    ..add(1)
    ..add(2)
    ..add(4)
    ..add(3)
    ..add(10);
  queue.removeFirst();

  print(queue.unorderedElements);
  print(queue);
  print(ProductInformation(-1, 2, 30));
}

class ProductInformation {
  ProductInformation(this.price, this.importance, this.type)
      : assert(price > 0),
        assert(importance > 0 || importance <= 5),
        assert(type > 0);

  final int price;
  final int importance;
  final int type;
}

getMaxSatisfaction(int money, int productLength) {
  if (money > 32000 || productLength > 60) return;
  List<ProductInformation> productList = [];
  for (var i = 0; i < productLength; i++) {
    // productList.add(ProductInformation());
    // addProductInformation();
  }
}

addProductInformation(int price, int importance, int type) {
  if (price > 10000) return;
  return ProductInformation(price, importance, type);
}

/// An [Iterator] that iterates a list-like [Iterable].
///
/// All iterations is done in terms of [Iterable.length] and
/// [Iterable.elementAt]. These operations are fast for list-like
/// iterables.
class ListIterator<E> implements Iterator<E> {
  final Iterable<E> _iterable;
  final int _length;
  int _index;
  E? _current;

  ListIterator(Iterable<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  @override
  E get current => _current as E;

  Iterable<E> get iterable => _iterable;

  set current(E e) => _current = e;

  void setCurrentIterator(E e) {
    _iterable.elementAt(_index) == e;
  }

  @override
  @pragma("vm:prefer-inline")
  bool moveNext() {
    int length = _iterable.length;
    if (_length != length) {
      throw ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

extension SetIterator<E> on Iterable<E> {
  E current(E e) => e;
}
