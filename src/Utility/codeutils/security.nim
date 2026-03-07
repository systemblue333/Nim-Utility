import posix

# declaring secured type
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

# general zerofill for pointer
proc zerofill*(address: pointer, u: int, size: int): void {.inline.} =
  # checking nil and size
  if address != nil and size > 0:
    # casting pointer to UnchekcedArray[uint8]
    var pInput: ptr UncheckedArray[uint8] = cast[ptr UncheckedArray[uint8]](address)
    # loop for zerofill number
    for i in 0 ..< u:
      # loop for size
      for j in 0 ..< size:
        # doing zerofill with 0xFF is because 0 can be often data but max does not
        pInput[j] = 0xFF'u8

    # check support compiler
    when defined(gcc) or defined(clang) or defined(vcc):
      # block compiler to optimize and remove zerofill code by reading address
      {.emit: """asm volatile ("" : : "g"(`address`) : "memory");""".}

  return

# zerofill for string
proc zerofill*(str: var string, u: int): void {.inline.} =
  # loop for zerofill number
  for i in 0 ..< u:
    # loop for size
    for j in 0 ..< str.len:
      str[j] = 'z'

  # get address
  var address: ptr char = addr str[0]

  # block compiler to optimize and remove zerofill code by reading address
  {.emit: """asm volatile ("" : : "g"(`address`) : "memory");""".}

  return

# SecureString destory
proc `=destroy`*(s: var SecureString): void =
  # check nil
  if s.data != nil:
    # zerofill
    zerofill(s.data, 1, s.capacity)

    # unlock memory
    discard posix.munlock(s.data, s.capacity)

    # dealloc memory
    deallocShared(s.data)

    # set memory to nil
    s.data = nil

# SecureSeq destory
proc `=destroy`*[T](s: var SecureSeq[T]): void {.inline.} =
  # check nil
  if s.data != nil:
    # zerofill
    zerofill(s.data, 1, s.capacity * sizeof(T))

    # unlock memory
    discard posix.munlock(s.data, s.capacity * sizeof(T))

    # dealloc memory
    deallocShared(s.data)

    # set memory to nil
    s.data = nil

# SecureArray destroy
proc `=destroy`*[N: static[int], T](s: var SecureArray[N, T]): void {.inline.} =
  zerofill(addr s, 1, sizeof(s))

# allocate new SecureString wtih length
template newSecureString*(cap: Natural): SecureString =
  var output: SecureString
  let size = if cap == 0: 16 else: cap
  # allocating memory
  output.data = cast[ptr UncheckedArray[char]](allocShared0(size))
  # lock memory
  discard posix.mlock(output.data, size)
  # initialize length and capacity
  output.length = 0
  output.capacity = size

  # returning
  output

# allocate new SecureString with capacity
template newSecureSeq*[T](cap: Natural): SecureSeq[T] =
  var output: SecureSeq[T]
  # allocating memory
  output.data = cast[ptr UncheckedArray[T]](allocShared0(cap * sizeof(T)))
  # lock memory
  discard posix.mlock(output.data, cap * sizeof(T))
  # initialize length and capacity
  output.length = 0
  output.capacity = cap

  # returning
  output

# initialize SecureSeq by seq
proc toSecureSeq*[T](input: seq[T]): SecureSeq[T] =
  # allocate memory
  result = newSecureSeq[T](input.len * 2)
  # initialize SecureSeq by input
  if input.len > 0:
    copyMem(result.data, addr input[0], input.len * sizeof(T))
    result.length = input.len

# initialize SecureString by string
proc toSecureString*(input: string): SecureString =
  # allocate memory
  result = newSecureString(input.len * 2)
  # initialize SecureSTring by input
  if input.len > 0:
    copyMem(result.data, addr input[0], input.len)
    result.length = input.len

# --- SecureString Utils ---

# slicing for SecureString
template `[]`*(s: SecureString, slice: HSlice[int, int]): openArray[char] =
  let a: int = slice.a
  let b: int = slice.b

  assert a >= 0 and b < s.len, "out of bounds"

  toOpenArray(s.data, a, b)

# backwards slicing for SecureString
template `[]`*[T](s: SecureString, slice: HSlice[int, BackwardsIndex]): openArray[char] =
  let a: int = slice.a
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# double backwards slicing for SecureString
template `[]`*[T](s: SecureString, slice: HSlice[BackwardsIndex, BackwardsIndex]): openArray[char] =
  let a: int = s.len - slice.a.int
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# read indexing for SecureString
template `[]`*(input: SecureString, i: int): char =
  input.data[i]

# write indexing for SecureString
template `[]=`*(output: var SecureString, i: int, input: char) =
  output.data[i] = input

# backwards indexing for SecureString
template `[]`*(s: SecureString, i: BackwardsIndex): char =
  s.data[s.len - i.int]

# backwards write indexing SecureString
template `[]=`*(s: var SecureString, i: BackwardsIndex, value: char) =
  s.data[s.len - i.int] = value

# get length for SecureString
template len*(s: SecureString): int =
  s.length

# print SecureString
template `$`*(s: SecureString): string =
  var output: string = newString(s.length)
  if s.len > 0:
    copyMem(addr result[0], s.data, s.length)

# items for SecureString
iterator items*(s: SecureString): char =
  for i in 0 ..< s.length:
    yield s.data[i]

# mutable items for SecureString
iterator mitems*(s: var SecureString): var char =
  for i in 0 ..< s.length:
    yield s.data[i]

# add char to SecureString
proc add*(output: var SecureString, input: char) {.inline.} =
  # check length + 1 is bigger then capacity
  if output.length + 1 > output.capacity:
    # set new capacity
    let newCap = if output.capacity == 0: 16 else: output.capacity * 2
    # allocate new memory
    let newData = cast[ptr UncheckedArray[char]](allocShared0(newCap))
    # lock new memory
    discard posix.mlock(newData, newCap)

    # check output's data is nil
    if output.data != nil:
      # copy memory
      if output.len > 0: copyMem(newData, output.data, output.length)
      # zerofill output's data
      zerofill(output.data, 1, output.capacity)
      # unlock memory(data)
      discard posix.munlock(output.data, output.capacity)
      # deallocate memory(data)
      deallocShared(output.data)

    # initialize output
    output.data = newData
    output.capacity = newCap

  # add input
  output.data[output.length] = input
  # increase output's length
  inc output.length

# add openArray[char] to SecureString
proc add*(output: var SecureString, input: openArray[char]) {.inline.} =
  # set needed length
  let needed = output.length + input.len
  if needed > output.capacity:
    # set capacity
    let newCap = if output.capacity == 0: 16 else: output.capacity * 2
    # allocate new memory
    let newData = cast[ptr UncheckedArray[char]](allocShared0(newCap))
    # lock new memory
    discard posix.mlock(newData, newCap)

    # check nil
    if output.data != nil:
      # copy memory
      if output.length > 0: copyMem(newData, output.data, output.length)
      # zeorfill output's data
      zerofill(output.data, 1, output.capacity)
      # unlock memory(data)
      discard posix.munlock(output.data, output.capacity)
      # deallocate memory(data)
      deallocShared(output.data)

    # initialize output
    output.data = newData
    output.capacity = newCap

  # copy memory
  if input.len > 0:
    copyMem(addr output.data[output.length], addr input[0], input.len)
    output.length = needed

# --- SecureSeq Utils ---

# slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[int, int]): openArray[T] =
  let a: int = slice.a
  let b: int = slice.b

  assert a >= 0 and b < s.len, "out of bounds"

  toOpenArray(s.data, a, b)

# backwards slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[int, BackwardsIndex]): openArray[T] =
  let a: int = slice.a
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# double backwards slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[BackwardsIndex, BackwardsIndex]): openArray[T] =
  let a: int = s.len - slice.a.int
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# read indexing for SecureSeq
template `[]`*[T](s: SecureSeq[T], i: int): T =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i]

# get length for SecureSeq
template `len`*[T](s: SecureSeq[T]): int =
  s.length

# write indexing for SecureSeq
template `[]=`*[T](s: var SecureSeq[T], i: int, value: T) =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i] = value

# backwards indexing for SecureSeq
template `[]`*[T](s: SecureSeq[T], i: BackwardsIndex): T =
  s.data[s.len - i.int]

# backwards write indexing for SecureSeq
template `[]=`*[T](s: var SecureSeq[T], i: BackwardsIndex, value: T) =
  s.data[s.len - i.int] = value

# items for SecureSeq
iterator items*[T](s: SecureSeq[T]): T =
  for i in 0 ..< s.len:
    yield s.data[i]

# mutable items for SecureSeq
iterator mitems*[T](s: var SecureSeq[T]): var T =
  for i in 0 ..< s.len:
    yield s.data[i]

# secure resize logic
template secureResize[T](output: var SecureSeq[T], newRequiredCap: int) =
  # set new capacity
  let newCap = newRequiredCap * 2
  # allocate new data
  let newData = cast[ptr UncheckedArray[T]](allocShared0(newCap * sizeof(T)))

  # check nil and length
  if s.data != nil and output.length > 0:
    # copy memory
    copyMem(newData, output.data, output.length * sizeof(T))
    # zerofill memory
    zerofill(output.data, 1, output.capacity * sizeof(T))
    # unlock old memory
    discard posix.munlock(output.data, output.capacity)
    # deallocate memory
    deallocShared(output.data)

  # initialize output
  output.data = newData
  output.capacity = newCap

# add variables for SecureSeq
proc add*[T](output: var SecureSeq[T], input: sink T) {.inline.} =
  if output.length + 1 > output.capacity:
    output.secureResize(output.len + 1)

  output.data[output.length] = input
  inc output.length

# add openArray[T] for SecureSeq
proc add*[T](output: var SecureSeq[T], input: openArray[T]) {.inline.} =
  let needed = output.length + input.len
  if needed > output.capacity:
    output.secureResize(needed)

  if input.len > 0:
    copyMem(addr output.data[output.length], addr input[0], input.len * sizeof(T))
    output.length = needed

# high for SecureSeq
template high*[T](x: SecureSeq[T]): int =
  x.length - 1

# low for SecureSeq
template low*[T](x: SecureSeq[T]): int =
  0

# print SecureSeq
template `$`*[T](input: SecureSeq[T]): string =
  var output: string = "@["
  for i in 0 ..< input.length:
    output.add($input.data[i])
    if i < input.length - 1: output.add(", ")
  ouptut.add("]")

# --- SecureArray Utils ---

# len for SecureArray
template len*[N, T](x: SecureArray[N, T]): int =
  N

# read indexing for SecureArray
template `[]`*[N, T](x: SecureArray[N, T], i: int): T =
  array[N, T](x)[i]

# write indexing for SecureArray
template `[]=`*[N, T](x: var SecureArray[N, T], i: int, value: T) =
  array[N, T](x)[i] = value

# slicing for SecureString
template `[]`*[N, T](s: SecureArray[N, T], slice: HSlice[int, int]): openArray[T] =
  let a: int = slice.a
  let b: int = slice.b

  assert a >= 0 and b < s.len, "out of bounds"

  toOpenArray(array[N, T](s), a, b)

# backwards slicing for SecureString
template `[]`*[N, T](s: SecureArray[N, T], slice: HSlice[int, BackwardsIndex]): openArray[T] =
  let a: int = slice.a
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(array[N, T](s), a, b)

# double backwards slicing for SecureString
template `[]`*[N, T](s: SecureArray[N, T], slice: HSlice[BackwardsIndex, BackwardsIndex]): openArray[T] =
  let a: int = s.len - slice.a.int
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(array[N, T](s), a, b)

# items for SecureArray
iterator items*[N, T](x: SecureArray[N, T]): T =
  for item in array[N, T](x):
    yield item

# mutable items for SecureArray
iterator mitems*[N, T](x: var SecureArray[N, T]): var T =
  for item in array[N, T](x).mitems:
    yield item

# high for SecureArray
template high*[N, T](x: SecureArray[N, T]): int =
  array[N, T](x).high

# low for SecureArray
template low*[N, T](x: SecureArray[N, T]): int =
  array[N, T](x).low
