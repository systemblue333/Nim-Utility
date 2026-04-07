import std/macros
import ../dataformat/dataformat

type
  slicearray*[len: static int, T] = object
    data*: ptr UncheckedArray[T]

proc toSliceArray*[N: static int, T](a: array[N, T], starts, ends: static int): auto {.inline.} =
  static:
    doAssert N > starts, "starts must smaller than N."
    doAssert N > ends, "ends must smaller than N."
    doAssert 0 <= starts, "starts must bigger than 0."

  slicearray[ends - starts + 1, T](data: cast[ptr UncheckedArray[T]](addr a[starts]))

template `[]`*[L: static int, T](s: slicearray[L, T], i: static int): T =
  static:
    doAssert i >= 0 and i < L, "Index out of bounds (Getter)"
  s.data[i]

template `[] =`*[L: static int, T](s: slicearray[L, T], i: static int, value: T): void =
  static:
    doAssert i >= 0 and i < L, "Index out of bounds (Getter)"
  s.data[i] = value

template `[]`*[L: static int, T](s: slicearray[L, T], i: int): T =
  when not(defined(danger)):
    doAssert i >= 0 and i < L, "Index out of bounds (Getter)"
  s.data[i]

template `[] =`*[L: static int, T](s: slicearray[L, T], i: int, value: T): void =
  when not(defined(danger)):
    doAssert i >= 0 and i < L, "Index out of bounds (Getter)"
  s.data[i] = value

iterator items*[L: static int, T](s: slicearray[L, T]): T =
  for i in static(0 ..< L):
    yield s.data[i]

iterator mitems*[L: static int, T](s: var slicearray[L, T]): var T =
  for i in static(0 ..< L):
    yield s.data[i]

template `$`*[L: static int, T](s: slicearray[L, T]): string =
  var output: string = "["
  for i in static(0 ..< L):
    output.add $s.data[i]
    if i < L - 1:
      output.add ", "
    output.add "]"
