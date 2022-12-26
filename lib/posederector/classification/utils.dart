import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';

import 'point_3d.dart';

/// Utility methods for operations on {@link PointF3D}.
PointF3D add(PointF3D a, PointF3D b) {
  return PointF3D.from(a.getX() + b.getX(), a.getY() + b.getY(), a.getZ() + b.getZ());
}

PointF3D subtract(PointF3D b, PointF3D a) {
  return PointF3D.from(a.getX() - b.getX(), a.getY() - b.getY(), a.getZ() - b.getZ());
}

PointF3D multiply(PointF3D a, double multiple) {
  return PointF3D.from(a.getX() * multiple, a.getY() * multiple, a.getZ() * multiple);
}

PointF3D multiplyP(PointF3D a, PointF3D multiple) {
  return PointF3D.from(a.getX() * multiple.getX(), a.getY() * multiple.getY(), a.getZ() * multiple.getZ());
}

PointF3D average(PointF3D a, PointF3D b) {
  return PointF3D.from((a.getX() + b.getX()) * 0.5, (a.getY() + b.getY()) * 0.5, (a.getZ() + b.getZ()) * 0.5);
}

double l2Norm2D(PointF3D point) {
  return hypot(point.getX(), point.getY());
}

double maxAbs(PointF3D point) {
  List<double> pointList = [point.getX().abs(), point.getY().abs(), point.getZ().abs()];
  return pointList.reduce(max);
}

double sumAbs(PointF3D point) {
  return point.getX().abs() + point.getY().abs() + point.getZ().abs();
}

List<PointF3D> addAll(List<PointF3D> pointsList, PointF3D p) {
  List<PointF3D> list = [];
  for (PointF3D pointF3D in pointsList) {
    list.add(add(pointF3D, p));
  }
  return list;
}

List<PointF3D> subtractAll(PointF3D p, List<PointF3D> pointsList) {
  List<PointF3D> list = [];
  for (PointF3D pointF3D in pointsList) {
    list.add(subtract(p, pointF3D));
  }
  return list;
}

List<PointF3D> multiplyAll(List<PointF3D> pointsList, double multiple) {
  List<PointF3D> list = [];
  for (PointF3D pointF3D in pointsList) {
    list.add(multiply(pointF3D, multiple));
  }
  return list;
}

List<PointF3D> multiplyAllP(List<PointF3D> pointsList, PointF3D multiple) {
  List<PointF3D> list = [];
  for (PointF3D pointF3D in pointsList) {
    list.add(multiplyP(pointF3D, multiple));
  }
  return list;
}

double hypot(double x, double y) {
  var first = x.abs();
  var second = y.abs();

  if (y > x) {
    first = y.abs();
    second = x.abs();
  }

  if (first == 0.0) {
    return second;
  }

  final t = second / first;
  return first * sqrt(1 + t * t);
}

List<List<T>> splitList<T>(List<T> list, int len) {
  if (len <= 1) {
    return [list];
  }
  List<List<T>> result = [];
  int index = 1;
  while (true) {
    if (index * len < list.length) {
      List<T> temp = list.skip((index - 1) * len).take(len).toList();
      result.add(temp);
      index++;
      continue;
    }
    List<T> temp = list.skip((index - 1) * len).toList();
    result.add(temp);
    break;
  }
  return result;
}

class MyPriorityQueue<E> implements PriorityQueue<E> {
  /// Initial capacity of a queue when created, or when added to after a
  /// [clear].
  ///
  /// Number can be any positive value. Picking a size that gives a whole
  /// number of "tree levels" in the heap is only done for aesthetic reasons.
  /// The comparison being used to compare the priority of elements.
  final Comparator<E> comparison;

  /// List implementation of a heap.
  late List<E?> _queue;

  /// Number of elements in queue.
  ///
  /// The heap is implemented in the first [_length] entries of [_queue].
  int _length = 0;

  /// Modification count.
  ///
  /// Used to detect concurrent modifications during iteration.
  int _modificationCount = 0;

  final int initialCapacity;

  /// Create a new priority queue.
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  MyPriorityQueue(this.initialCapacity, [int Function(E, E)? comparison]) : comparison = comparison ?? defaultCompare {
    _queue = List<E?>.filled(initialCapacity, null);
  }

  E _elementAt(int index) => _queue[index] ?? (null as E);

  @override
  void add(E element) {
    _modificationCount++;
    _add(element);
  }

  @override
  void addAll(Iterable<E> elements) {
    var modified = 0;
    for (var element in elements) {
      modified = 1;
      _add(element);
    }
    _modificationCount += modified;
  }

  @override
  void clear() {
    _modificationCount++;
    _queue = const [];
    _length = 0;
  }

  @override
  bool contains(E object) => _locate(object) >= 0;

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation is performed in the order they occur
  /// in the underlying heap structure.
  ///
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  @override
  Iterable<E> get unorderedElements => _UnorderedElementsIterable<E>(this);

  @override
  E get first {
    if (_length == 0) throw StateError('No element');
    return _elementAt(0);
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @override
  bool remove(E element) {
    var index = _locate(element);
    if (index < 0) return false;
    _modificationCount++;
    var last = _removeLast();
    if (index < _length) {
      var comp = comparison(last, element);
      if (comp <= 0) {
        _bubbleUp(last, index);
      } else {
        _bubbleDown(last, index);
      }
    }
    return true;
  }

  /// Removes all the elements from this queue and returns them.
  ///
  /// The returned iterable has no specified order.
  /// The operation does not copy the elements,
  /// but instead keeps them in the existing heap structure,
  /// and iterates over that directly.
  @override
  Iterable<E> removeAll() {
    _modificationCount++;
    var result = _queue;
    var length = _length;
    _queue = const [];
    _length = 0;
    return result.take(length).cast();
  }

  @override
  E removeFirst() {
    if (_length == 0) throw StateError('No element');
    _modificationCount++;
    var result = _elementAt(0);
    var last = _removeLast();
    if (_length > 0) {
      _bubbleDown(last, 0);
    }
    return result;
  }

  @override
  List<E> toList() => _toUnorderedList()..sort(comparison);

  @override
  Set<E> toSet() {
    var set = SplayTreeSet<E>(comparison);
    for (var i = 0; i < _length; i++) {
      set.add(_elementAt(i));
    }
    return set;
  }

  @override
  List<E> toUnorderedList() => _toUnorderedList();

  List<E> _toUnorderedList() => [for (var i = 0; i < _length; i++) _elementAt(i)];

  /// Returns some representation of the queue.
  ///
  /// The format isn't significant, and may change in the future.
  @override
  String toString() {
    return _queue.take(_length).toString();
  }

  /// Add element to the queue.
  ///
  /// Grows the capacity if the backing list is full.
  void _add(E element) {
    if (_length == _queue.length) _grow();
    _bubbleUp(element, _length++);
  }

  /// Find the index of an object in the heap.
  ///
  /// Returns -1 if the object is not found.
  ///
  /// A matching object, `o`, must satisfy that
  /// `comparison(o, object) == 0 && o == object`.
  int _locate(E object) {
    if (_length == 0) return -1;
    // Count positions from one instead of zero. This gives the numbers
    // some nice properties. For example, all right children are odd,
    // their left sibling is even, and the parent is found by shifting
    // right by one.
    // Valid range for position is [1.._length], inclusive.
    var position = 1;
    // Pre-order depth first search, omit child nodes if the current
    // node has lower priority than [object], because all nodes lower
    // in the heap will also have lower priority.
    do {
      var index = position - 1;
      var element = _elementAt(index);
      var comp = comparison(element, object);
      if (comp <= 0) {
        if (comp == 0 && element == object) return index;
        // Element may be in subtree.
        // Continue with the left child, if it is there.
        var leftChildPosition = position * 2;
        if (leftChildPosition <= _length) {
          position = leftChildPosition;
          continue;
        }
      }
      // Find the next right sibling or right ancestor sibling.
      do {
        while (position.isOdd) {
          // While position is a right child, go to the parent.
          position >>= 1;
        }
        // Then go to the right sibling of the left-child.
        position += 1;
      } while (position > _length); // Happens if last element is a left child.
    } while (position != 1); // At root again. Happens for right-most element.
    return -1;
  }

  E _removeLast() {
    var newLength = _length - 1;
    var last = _elementAt(newLength);
    _queue[newLength] = null;
    _length = newLength;
    return last;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has higher priority than the
  /// parent, swap it with the parent.
  void _bubbleUp(E element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _elementAt(parentIndex);
      if (comparison(element, parent) > 0) break;
      _queue[index] = parent;
      index = parentIndex;
    }
    _queue[index] = element;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has lower priority than either child,
  /// swap it with the highest priority child.
  void _bubbleDown(E element, int index) {
    var rightChildIndex = index * 2 + 2;
    while (rightChildIndex < _length) {
      var leftChildIndex = rightChildIndex - 1;
      var leftChild = _elementAt(leftChildIndex);
      var rightChild = _elementAt(rightChildIndex);
      var comp = comparison(leftChild, rightChild);
      int minChildIndex;
      E minChild;
      if (comp < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }
      comp = comparison(element, minChild);
      if (comp <= 0) {
        _queue[index] = element;
        return;
      }
      _queue[index] = minChild;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }
    var leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _length) {
      var child = _elementAt(leftChildIndex);
      var comp = comparison(element, child);
      if (comp > 0) {
        _queue[index] = child;
        index = leftChildIndex;
      }
    }
    _queue[index] = element;
  }

  /// Grows the capacity of the list holding the heap.
  ///
  /// Called when the list is full.
  void _grow() {
    var newCapacity = _queue.length * 2 + 1;
    if (newCapacity < initialCapacity) newCapacity = initialCapacity;
    var newQueue = List<E?>.filled(newCapacity, null);
    newQueue.setRange(0, _length, _queue);
    _queue = newQueue;
  }
}

/// Implementation of [MyPriorityQueue.unorderedElements].
class _UnorderedElementsIterable<E> extends Iterable<E> {
  final MyPriorityQueue<E> _queue;

  _UnorderedElementsIterable(this._queue);

  @override
  Iterator<E> get iterator => _UnorderedElementsIterator<E>(_queue);
}

class _UnorderedElementsIterator<E> implements Iterator<E> {
  final MyPriorityQueue<E> _queue;
  final int _initialModificationCount;
  E? _current;
  int _index = -1;

  _UnorderedElementsIterator(this._queue) : _initialModificationCount = _queue._modificationCount;

  @override
  bool moveNext() {
    if (_initialModificationCount != _queue._modificationCount) {
      throw ConcurrentModificationError(_queue);
    }
    var nextIndex = _index + 1;
    if (0 <= nextIndex && nextIndex < _queue.length) {
      _current = _queue._queue[nextIndex];
      _index = nextIndex;
      return true;
    }
    _current = null;
    _index = -2;
    return false;
  }

  @override
  E get current => _index < 0 ? throw StateError('No element') : (_current ?? null as E);
}

/// A [Comparator] that asserts that its first argument is comparable.
///
/// The function behaves just like [List.sort]'s
/// default comparison function. It is entirely dynamic in its testing.
///
/// Should be used when optimistically comparing object that are assumed
/// to be comparable.
/// If the elements are known to be comparable, use [compareComparable].
int defaultCompare(Object? value1, Object? value2) => (value1 as Comparable<Object?>).compareTo(value2);
