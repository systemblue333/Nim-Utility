import posix
import autoopt

# declaring secured type
type
  SecureSeq*[T] = object
    data*: ptr UncheckedArray[T]
    length*: int
    capacity*: int
  SecureString* = SecureSeq[char]
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
      str[j] = 0xFF.char

  # get address
  var address: ptr char = addr str[0]

  # block compiler to optimize and remove zerofill code by reading address
  {.emit: """asm volatile ("" : : "g"(`address`) : "memory");""".}

  return

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

# allocate new SecureString with capacity
template newSecureSeq*[T](cap: Natural): SecureSeq[T] {.autoSizeOpt.} =
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
  

# allocate new SecureString wtih length
template newSecureString*(cap: Natural): SecureString {.autoSizeOpt.} =
  var output: SecureString = newSecureSeq[char](cap)
  output

# initialize SecureSeq by seq
proc toSecureSeq*[T](input: openArray[T]): SecureSeq[T] =
  # allocate memory
  result = newSecureSeq[T](input.len * 2)
  # initialize SecureSeq by input
  if input.len > 0:
    copyMem(result.data, addr input[0], input.len * sizeof(T))
    result.length = input.len

  return result

# initialize SecureString by string
proc toSecureString*(input: string): SecureString =
  # allocate memory
  result = newSecureString(input.len * 2)
  # initialize SecureSTring by input
  if input.len > 0:
    copyMem(result.data, addr input[0], input.len)
    result.length = input.len

  return result

# --- SecureString Utils ---

# --- SecureSeq Utils ---

# slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[int, int]): openArray[T] {.autoSizeOpt.} =
  let a: int = slice.a
  let b: int = slice.b

  assert a >= 0 and b < s.len, "out of bounds"

  toOpenArray(s.data, a, b)

# backwards slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[int, BackwardsIndex]): openArray[T] {.autoSizeOpt.} =
  let a: int = slice.a
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# double backwards slicing for SecureSeq
template `[]`*[T](s: SecureSeq[T], slice: HSlice[BackwardsIndex, BackwardsIndex]): openArray[T] {.autoSizeOpt.} =
  let a: int = s.len - slice.a.int
  let b: int = s.len - slice.b.int
  assert a >= 0 and b < s.len, "Out of bounds"
  toOpenArray(s.data, a, b)

# read indexing for SecureSeq
template `[]`*[T](s: SecureSeq[T], i: int): T {.autoSizeOpt.} =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i]

# get length for SecureSeq
template `len`*[T](s: SecureSeq[T]): int {.autoSizeOpt.} =
  s.length

# write indexing for SecureSeq
template `[]=`*[T](s: var SecureSeq[T], i: int, value: T) {.autoSizeOpt.} =
  assert i >= 0 and i < s.len, "Out of bounds"
  s.data[i] = value

# backwards indexing for SecureSeq
template `[]`*[T](s: SecureSeq[T], i: BackwardsIndex): T {.autoSizeOpt.} =
  s.data[s.len - i.int]

# backwards write indexing for SecureSeq
template `[]=`*[T](s: var SecureSeq[T], i: BackwardsIndex, value: T) {.autoSizeOpt.} =
  s.data[s.len - i.int] = value

# items for SecureSeq
iterator items*[T](s: SecureSeq[T]): T =
  for i in 0 ..< s.len:
    yield s.data[i]

# mutable items for SecureSeq
iterator mitems*[T](s: var SecureSeq[T]): var T =
  for i in 0 ..< s.len:
    yield s.data[i]

# SecureSeq items
iterator items*[T](args: varargs[SecureSeq[T]]): SecureSeq[T] =
  for i in 0 ..< args.len:
    yield args[i]

# SecureSeq addr
template addr*[T](s: SecureSeq[T], i: int): ptr T =
  assert i >= 0 and i < s.length, "Out of bounds"
  addr(s.data[i])

# SeucreSeq addr for backwords index
template addr*[T](s: SecureSeq[T], i: BackwardsIndex): ptr T =
  addr(s.data[s.len - i.int])

template contains*[T](s: SecureSeq[T], item: T): bool =
  var res = false
  for i in 0 ..< s.len:
    if s.data[i] == item:
      res = true
      break
  res

# secure resize logic
template secureResize[T](output: var SecureSeq[T], newRequiredCap: int) {.autoSizeOpt.} =
  # set new capacity
  let newCap = newRequiredCap * 2
  # allocate new data
  let newData = cast[ptr UncheckedArray[T]](allocShared0(newCap * sizeof(T)))

  # check nil and length
  if output.data != nil and output.length > 0:
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

# set length for SecureSeq
proc setLen*[T](s: var SecureSeq[T], newLen: Natural) {.inline.} =
  if newLen > s.capacity:
    s.secureResize(newLen)
  
  if newLen < s.length:
    # Optional: zero out the removed part for security?
    # Since it's a SecureSeq, we should probably zero it out immediately.
    let diff = s.length - newLen
    zerofill(addr s.data[newLen], 1, diff * sizeof(T))
  
  s.length = newLen

template `==`*[T](a, b: SecureSeq[T]): bool =
  if a.len != b.len: false
  elif a.len == 0: true
  else:
    var res = true
    for i in 0 ..< a.len:
      if not (a.data[i] == b.data[i]):
        res = false
        break
    res

template `<`*[T](a, b: SecureSeq[T]): bool =
  let minLen = min(a.len, b.len)
  var res = 0
  for i in 0 ..< minLen:
    if a.data[i] < b.data[i]:
      res = -1; break
    elif b.data[i] < a.data[i]:
      res = 1; break
  if res != 0: res < 0 else: a.len < b.len

template `>`*[T](a, b: SecureSeq[T]): bool = 
  b < a

template `<=`*[T](a, b: SecureSeq[T]): bool = 
  not (b < a)

template `>=`*[T](a, b: SecureSeq[T]): bool = 
  not (a < b)

# high for SecureSeq
template high*[T](x: SecureSeq[T]): int {.autoSizeOpt.} =
  x.length - 1

# low for SecureSeq
template low*[T](x: SecureSeq[T]): int {.autoSizeOpt.} =
  0

# print SecureSeq
template `$`*[T](input: SecureSeq[T]): string {.autoSizeOpt.} =
  var output: string = "@["
  for i in 0 ..< input.length:
    output.add($input.data[i])
    if i < input.length - 1: output.add(", ")
  output.add("]")

proc `<`*[T](a, b: SecureSeq[T]): bool =
  let minLen = min(a.len, b.len)
  for i in 0 ..< minLen:
    if a[i] < b[i]: return true
    if b[i] < a[i]: return false
  return a.len < b.len

proc `>`*[T](a, b: SecureSeq[T]): bool =
  return b < a

# print SecureString
proc `$`*(s: SecureString): string =
  var output: string = newString(s.length)
  if s.len > 0:
    copyMem(addr output[0], s.data, s.length)

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

template addr*[N, T](s: SecureArray[N, T], i: int): ptr T =
  assert i >= 0 and i < N, "Out of bounds"
  addr(cast[array[N, T]](s)[i])
