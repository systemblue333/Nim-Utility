import posix

type
  SecureSeq*[T] = object
    data: ptr UncheckedArray[T]
    length: int
    capacity: int
  SecureString* = object
    data: ptr UncheckedArray[char]
    length: int
    capacity: int
  SecureArray*[N: static[int], T] = distinct array[N, T]

proc zerofill*(address: pointer, u: int, size: int): void {.inline.} =
  if address != nil and size > 0:

    var pInput: ptr UncheckedArray[uint8] = cast[ptr UncheckedArray[uint8]](address)
    for i in 0 ..< u:
      for j in 0 ..< size:
        pInput[j] = 0xFF'u8

    when defined(gcc) or defined(clang) or defined(vcc):
      {.emit: """asm volatile ("" : : "g"(`address`) : "memory");""".}

  return

proc zerofill*(str: var string, u: int): void {.inline.} =

  for i in 0 ..< u:
    for j in 0 ..< str.len:
      str[j] = 'z'

  var address: ptr char = addr str[0]

  {.emit: """asm volatile ("" : : "g"(`address`) : "memory");""".}

  return

proc `=destroy`*(s: var SecureString): void =
  if s.data != nil:
    zerofill(s.data, 1, s.capacity)
    discard posix.munlock(s.data, s.capacity)
    deallocShared(s.data)
    s.data = nil

proc `=destroy`*[T](s: var SecureSeq[T]): void {.inline.} =
  if s.data != nil:
    zerofill(s.data, 1, s.capacity * sizeof(T))
    discard posix.munlock(s.data, s.capacity * sizeof(T))
    deallocShared(s.data)
    s.data = nil

proc `=destroy`*[N: static[int], T](s: var SecureArray[N, T]): void {.inline.} =
  zerofill(addr s, 1, sizeof(s))

template newSecureString*(initialLen: Natural): SecureString =
  var s: SecureString
  let size = if initialLen == 0: 16 else: initialLen
  s.data = cast[ptr UncheckedArray[char]](allocShared0(size))
  discard posix.mlock(s.data, size)
  s.length = 0
  s.capacity = size
  s

template newSecureSeq*[T](cap: Natural): SecureSeq[T] =
  var ret: SecureSeq[T]
  ret.data = cast[ptr UncheckedArray[T]](allocShared0(cap * sizeof(T)))
  discard posix.mlock(ret.data, cap * sizeof(T))
  ret.length = 0
  ret.capacity = cap
  ret

proc toSecureSeq*[T](src: seq[T]): SecureSeq[T] =
  result = newSecureSeq[T](src.len * 2)
  if src.len > 0:
    copyMem(result.data, addr src[0], src.len * sizeof(T))
    result.length = src.len

proc toSecureString*(src: string): SecureString =
  result = newSecureString(src.len * 2)
  if src.len > 0:
    copyMem(result.data, addr src[0], src.len)
    result.length = src.len

template `[]`*(s: SecureString, i: int): char =
  s.data[i]

template `[]=`*(s: var SecureString, i: int, v: char) =
  s.data[i] = v

template len*(s: SecureString): int = s.length

proc `$`*(s: SecureString): string =
  result = newString(s.length)
  if s.len > 0:
    copyMem(addr result[0], s.data, s.length)

iterator items*(s: SecureString): char =
  for i in 0 ..< s.length:
    yield s.data[i]

iterator mitems*(s: var SecureString): var char =
  for i in 0 ..< s.length:
    yield s.data[i]

proc add*(s: var SecureString, c: char) {.inline.} =
  if s.length + 1 > s.capacity:
    let newCap = if s.capacity == 0: 16 else: s.capacity * 2
    let newData = cast[ptr UncheckedArray[char]](allocShared0(newCap))
    discard posix.mlock(newData, newCap)

    if s.data != nil:
      if s.len > 0: copyMem(newData, s.data, s.length)
      zerofill(s.data, 1, s.capacity)
      discard posix.munlock(s.data, s.capacity)
      deallocShared(s.data)

    s.data = newData
    s.capacity = newCap

  s.data[s.length] = c
  inc s.length

proc add*(s: var SecureString, vals: openArray[char]) {.inline.} =
  let needed = s.length + vals.len
  if needed > s.capacity:
    let newCap = if s.capacity == 0: 16 else: s.capacity * 2
    let newData = cast[ptr UncheckedArray[char]](allocShared0(newCap))
    discard posix.mlock(newData, newCap)

    if s.data != nil:
      if s.length > 0: copyMem(newData, s.data, s.length)
      zerofill(s.data, 1, s.capacity)
      discard posix.munlock(s.data, s.capacity)
      deallocShared(s.data)

    s.data = newData
    s.capacity = newCap

  if vals.len > 0:
    copyMem(addr s.data[s.length], addr vals[0], vals.len)
    s.length = needed

template `[]`*[T](s: SecureSeq[T], i: int): T =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i]

template `len`*[T](s: SecureSeq[T]): int =
  s.length

template `[]=`*[T](s: var SecureSeq[T], i: int, value: T) =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i] = value

iterator items*[T](s: SecureSeq[T]): T =
  for i in 0 ..< s.len:
    yield s.data[i]

iterator mitems*[T](s: var SecureSeq[T]): var T =
  for i in 0 ..< s.len:
    yield s.data[i]

template secureResize[T](s: var SecureSeq[T], newRequiredCap: int) =
  let newCap = newRequiredCap * 2
  let newData = cast[ptr UncheckedArray[T]](allocShared0(newCap * sizeof(T)))

  if s.data != nil and s.length > 0:
    copyMem(newData, s.data, s.length * sizeof(T))

    zerofill(s.data, 1, s.capacity * sizeof(T))
    discard posix.munlock(s.data, s.capacity)
    deallocShared(s.data)

  s.data = newData
  s.capacity = newCap

proc add*[T](s: var SecureSeq[T], val: sink T) {.inline.} =
  if s.length + 1 > s.capacity:
    s.secureResize(s.len + 1)

  s.data[s.length] = val
  inc s.length

proc add*[T](s: var SecureSeq[T], vals: openArray[T]) {.inline.} =
  let needed = s.length + vals.len
  if needed > s.capacity:
    s.secureResize(needed)

  if vals.len > 0:
    copyMem(addr s.data[s.length], addr vals[0], vals.len * sizeof(T))
    s.length = needed

template high*[T](x: SecureSeq[T]): int =
  x.length - 1

template low*[T](x: SecureSeq[T]): int =
  0

proc `$`*[T](s: SecureSeq[T]): string =
  result = "@["
  for i in 0 ..< s.length:
    result.add($s.data[i])
    if i < s.length - 1: result.add(", ")
  result.add("]")

template len*[N, T](x: SecureArray[N, T]): int = N

template `[]`*[N, T](x: SecureArray[N, T], i: int): T =
  array[N, T](x)[i]

template `[]=`*[N, T](x: var SecureArray[N, T], i: int, value: T) =
  array[N, T](x)[i] = value

iterator items*[N, T](x: SecureArray[N, T]): T =
  for item in array[N, T](x):
    yield item

iterator mitems*[N, T](x: var SecureArray[N, T]): var T =
  for item in array[N, T](x).mitems:
    yield item

template high*[N, T](x: SecureArray[N, T]): int =
  array[N, T](x).high

template low*[N, T](x: SecureArray[N, T]): int =
  array[N, T](x).low
