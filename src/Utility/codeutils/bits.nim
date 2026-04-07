{.experimental: "strictNotNil".}
import errorutils
import std/bitops
import std/endians

type
  # defien BitUtils error enum
  BitsUtilsError* = enum
    TooBigN = 0
    NotSameSize = 1
    DifferentSize = 2
  # BigUint(bigger then uint8)
  BigUint = concept u
    u is (uint16|uint32|uint64)
  # uint(every unsigned int)
  Uint = concept u
    u is (uint8|uint16|uint32|uint64)

# decode uint8 array to bigger uint(uint16/uint32/uint64) array by little endian
template decodeLEC[N1: static[int], N2: static[int], T2: BigUint](input: lent array[N1, uint8], output: var array[N2, T2]): void =
  # check uint8 array size and bigger uint array size are same in compile time
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  # set size of T2 as constant
  const step: int = sizeof(T2)

  # loop for input length(doing it with static is for optimize by deploying it in compile time)
  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl (b * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) array to uint8 array by little endian
template encodeLEC[N1: static[int], T1: BigUint, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
  # check bigger uint array and uint8 array size are same in compile time
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  # set size of T1 as constant
  const step: int = sizeof(T1)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N1):
    let value: T1 = input[i]
    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

# decode uint8 array to bigger uint(uint16/uint32/uint64) array by big endian
template decodeBEC[N1: static[int], N2: static[int], T2: BigUint](input: lent array[N1, uint8], output: var array[N2, T2]): void =
  # check uint8 array size and bigger uint array size are same in compile time
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  # set size of T2 as constant
  const step: int = sizeof(T2)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl ((sizeof(T2) - 1 - b) * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) array to uint8 array by big endian
template encodeBEC[N1: static[int], T1: BigUint, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
  # check bigger uint array size and uint8 array size are same in compile time
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  # set size of T1 as constant
  const step: int = sizeof(T1)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N1):
    let value: T1 = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by little endian
template decodeLEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check uint8 openArray size and bigger uint openArray size are same
  if input.len * sizeof(uint8) != output.len * sizeof(T):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success(when void, there's no value)
    result = Result[void, BitsUtilsError](kind: Success)

    # set size of T as constant
    const step: int = sizeof(T)

   # loop for input length
    for i in 0 ..< output.len:
      var value: T = 0
      let startIndex: int = i * step

      # decode logic
      for b in static(0 ..< step):
        value = value or (input[startIndex + b].T shl (b * 8))

      output[i] = value

  result

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by little endian
template encodeLEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check bigger uint openArray size and uint8 openArray size are same
  if input.len * sizeof(T) != output.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)

    # set size of T as constant
    const step: int = sizeof(T)

    # loop for input length
    for i in 0 ..< input.len:
      let value: T = input[i]

      # encode logic
      for b in static(0 ..< step):
        output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

  result

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by big endian
template decodeBEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check uint8 openArray size and bigger uint openArray size are same
  if input.len * sizeof(uint8) != output.len * sizeof(T):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)

    # set size of T as constant
    const step: int = sizeof(T)

    # loop for input length
    for i in 0 ..< output.len:
      var value: T = 0
      let startIndex: int = i * step

      # decode logic
      for b in static(0 ..< step):
        value = value or (input[startIndex + b].T shl ((step - 1 - b) * 8))

      output[i] = value

  result

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by big endian
template encodeBEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check bigger uint openArray size and uint8 openArray size are same
  if input.len * sizeof(T) != output.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)

    # set size of T as constant
    const step: int = sizeof(T)

    # loop for input length
    for i in 0 ..< input.len:
      let value: T = input[i]

      # encode logic
      for b in static(0 ..< step):
        output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

  result

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by little endian
template decodeLEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    var value: T = 0

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[i * step + b].T shl (b * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by little endian
template encodeLEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    let value: T = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by big endian
template decodeBEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    var value: T = 0

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[i * step + b].T shl ((step - 1 - b) * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by big endian
template encodeBEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    let value: T = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

# generic leftRotate core
template leftRotateC[T: SomeInteger](value: lent T, shift: lent T): T =
  ((value shl shift) or (value shr (T(sizeof(T) * 8) - shift)))

# generic leftRotate core
template rightRotateC[T: SomeInteger](value: lent T, shift: lent T): T =
  ((value shr shift) or (value shl (T(sizeof(T) * 8) - shift)))

# Little Endian Encode
template toBytesLEC*[T: BigUint, N: static[int]](input: lent T, output: var array[N, uint8]): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(input)
  # loop for encoding
  for i in static(0 ..< N):
    output[i] = uint8((input shr (i * 8)) and 0xFF)

# Big Endian Encode
template toBytesBEC*[T: BigUint, N: static[int]](input: lent T, output: var array[N, uint8]): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(input)
  # loop for encoding
  for i in static(0 ..< N):
    output[i] = uint8((input shr ((N - 1 - i) * 8)) and 0xFF)

# Little Endian Decode
template fromBytesLEC*[T: BigUint, N: static[int]](input: lent array[N, uint8], output: var T): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(output)
  output = 0
  # loop for decoding
  for i in static(0 ..< N):
    output = output or (T(input[i]) shl (i * 8))

# Big Endian Decode
template fromBytesBEC*[T: BigUint, N: static[int]](input: lent array[N, uint8], output: var T): void =
  static: doAssert N == sizeof(ret)
  output = 0
  # loop for decoding
  for i in static(0 ..< N):
    output = output or (T(input[i]) shl ((N - 1 - i) * 8))

# Little Endian Encode
template toBytesLEC*[T: BigUint](input: lent T, output: var openArray[uint8]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check input and output size are same
  if sizeof(T) != output.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)
    # loop for encoding
    for i in 0 ..< output.len:
      output[i] = uint8((input shr (i * 8)) and 0xFF)

  result

# Big Endian Encode
template toBytesBEC*[T: BigUint](input: lent T, output: var openArray[uint8]): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check input and output size are same
  if sizeof(T) != output.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)

    # decoding logic
    for i in 0 ..< output.len:
      output[i] = uint8((input shr ((output.len - 1 - i) * 8)) and 0xFF)

  result

# Little Endian Decode
template fromBytesLEC*[T: BigUint](input: lent openArray[uint8], output: var T): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check input and output size are same
  if sizeof(T) != input.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)
    # initialize output
    output = 0

    # decoding logic
    for i in static(0 ..< sizeof(output)):
      output = output or (T(input[i]) shl (i * 8))
  result

# Big Endian Decode
template fromBytesBEC*[T: BigUint](input: lent openArray[uint8], output: var T): Result[void, BitsUtilsError] =
  # pre-declaring result
  var result: Result[void, BitsUtilsError]
  # check input and output size are same
  if sizeof(T) != input.len * sizeof(uint8):
    # return Failure and Error
    result = Result[void, BitsUtilsError](kind: Failure, error: DifferentSize)
  else:
    # return Success
    result = Result[void, BitsUtilsError](kind: Success)
    # initialize output
    output = 0
    # decoding logic
    for i in static(0 ..< sizeof(output)):
      output = output or (T(input[i]) shl ((sizeof(output) - 1 - i) * 8))

  result

# bit reflection for uint8
template bitref8C(n: lent uint8): uint8 =
  var x = n
  x = (x shr 4) or (x shl 4)
  x = ((x shr 2) and 0x33'u8) or ((x shl 2) and 0xCC'u8)
  x = ((x shr 1) and 0x55'u8) or ((x shl 1) and 0xAA'u8)
  x

# bit reflection for uint16
template bitref16C(n: lent uint16): uint16 =
  var x = n
  x = (x shr 8) or (x shl 8)
  x = ((x shr 4) and 0x0F0F'u16) or ((x shl 4) and 0xF0F0'u16)
  x = ((x shr 2) and 0x3333'u16) or ((x shl 2) and 0xCCCC'u16)
  x = ((x shr 1) and 0x5555'u16) or ((x shl 1) and 0xAAAA'u16)
  x

# bit reflection for uint32
template bitref32C(n: lent uint32): uint32 =
  var x = n
  x = (x shr 16) or (x shl 16)
  x = ((x shr 8) and 0x00FF00FF'u32) or ((x shl 8) and 0xFF00FF00'u32)
  x = ((x shr 4) and 0x0F0F0F0F'u32) or ((x shl 4) and 0xF0F0F0F0'u32)
  x = ((x shr 2) and 0x33333333'u32) or ((x shl 2) and 0xCCCCCCCC'u32)
  x = ((x shr 1) and 0x55555555'u32) or ((x shl 1) and 0xAAAAAAAA'u32)
  x

# bit reflection for uint64
template bitref64C(n: lent uint64): uint64 =
  var x = n
  x = (x shr 32) or (x shl 32)
  x = ((x shr 16) and 0x0000FFFF0000FFFF'u64) or ((x shl 16) and 0xFFFF0000FFFF0000'u64)
  x = ((x shr 8) and 0x00FF00FF00FF00FF'u64) or ((x shl 8) and 0xFF00FF00FF00FF00'u64)
  x = ((x shr 4) and 0x0F0F0F0F0F0F0F0F'u64) or ((x shl 4) and 0xF0F0F0F0F0F0F0F0'u64)
  x = ((x shr 2) and 0x3333333333333333'u64) or ((x shl 2) and 0xCCCCCCCCCCCCCCCC'u64)
  x = ((x shr 1) and 0x5555555555555555'u64) or ((x shl 1) and 0xAAAAAAAAAAAAAAA'u64)
  x

template extendC[T: SomeUnsignedInt](b: uint8): T =
  var output: T = 0
  for i in static(0 ..< sizeof(T)):
    output = output or (T(b) shl (i * 8))

  output

template shlArrayC[N: static int](input: lent array[N, uint8], bits: int): array[N, uint8] =
  var output: array[N, uint8]
  var check: bool = true
  if bits <= 0:
    check = false
    output = input
  if bits >= N * 8:
    check = false

  if check:
    let byteShift = bits div 8
    let bitShift = bits mod 8

    for i in byteShift ..< N:
      output[i] = input[i - byteShift]

    if bitShift > 0:
      var carry: uint8 = 0
      for i in byteShift ..< N:
        let nextCarray = output[i] shr (8 - bitShift)
        output[i] = (output[i] shl bitShift) or carry
        carry = nextCarry

  output

template shrArrayC[N: static int](input: lent array[N, uint8], bits: int): array[N, uint8] =
  var output: array[N, uint8]
  var check: bool = true
  if bits <= 0:
    check = false
    output = input
  if bits >= N * 8:
    check = false

  if check:
    let byteShift = bits div 8
    let bitShift = bits mod 8

    for i in 0 ..< (N - byteShift):
      output[i] = input[i + byteShift]

    if bitShift > 0:
      var carry: uint8 = 0
      for i in countdown(N - 1 - byteShift,  0):
        let nextCarry = output[i] shl (8 - bitShift)
        output[i] = (output[i] shr bitShift) or carry
        carry = nextCarry

  output

template leftRotateArrayC*[N: static[int]](input: array[N, uint8], bits: int): array[N, uint8] =
  var output: array[N, uint8]
  let n = bits mod (N * 8)
  if n != 0:
    let shiftedLeft: array[N, uint8] = input.shlArrayC(n)
    let shiftedRight: array[N, uint8] = input.shrArrayC(N * 8 - n)

    for i in 0..<N:
      output[i] = shiftedLeft[i] or shiftedRight[i]

  output

template rightRotateArrayC*[N: static[int]](input: array[N, uint8], bits: int): array[N, uint8] =
  var output: array[N, uint8]
  let n = bits mod (N * 8)
  if n != 0:
    let shiftedRight = data.shrArrayC(n)
    let shiftedLeft = data.shlArrayC(N * 8 - n)

    for i in 0..<N:
      output[i] = shiftedRight[i] or shiftedLeft[i]


  output

template swapC[T](input: T): T =
  var output: T

  when sizeof(T) == 2:
    swapEndian16(addr output, addr input)
  elif sizeof(T) == 4:
    swapEndian32(addr output, addr input)
  elif sizeof(T) == 8:
    swapEndian64(addr output, addr input)

  output

template swapC[N: static int, T](input: lent array[N, T], output: var array[N, T]): void =
  for i in static(0 ..< N):
    output[i] = swapC(input[i])

template swapC[T](input: lent openArray[T], output: var openArray[T], length: static int): void =
  for i in static(0 ..< length):
    output[i] = swapC(input[i])

# decode uint8 array to bigger uint(uint16/uint32/uint64) array by little endian
template decodeLEC[N1: static[int], N2: static[int], T2: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T2]): void =
  # check uint8 array size and bigger uint array size are same in compile time
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  # set size of T2 as constant
  const step: int = sizeof(T2)

  # loop for input length(doing it with static is for optimize by deploying it in compile time)
  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl (b * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) array to uint8 array by little endian
template encodeLEC[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
  # check bigger uint array and uint8 array size are same in compile time
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  # set size of T1 as constant
  const step: int = sizeof(T1)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N1):
    let value: T1 = input[i]
    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

# decode uint8 array to bigger uint(uint16/uint32/uint64) array by big endian
template decodeBEC[N1: static[int], N2: static[int], T2: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T2]): void =
  # check uint8 array size and bigger uint array size are same in compile time
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  # set size of T2 as constant
  const step: int = sizeof(T2)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl ((sizeof(T2) - 1 - b) * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) array to uint8 array by big endian
template encodeBEC[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
  # check bigger uint array size and uint8 array size are same in compile time
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  # set size of T1 as constant
  const step: int = sizeof(T1)

  # loop for input length(static is for optimize by deploying it in compile time)
  for i in static(0 ..< N1):
    let value: T1 = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by little endian
template decodeLEC[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    var value: T = 0

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[i * step + b].T shl (b * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by little endian
template encodeLEC[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    let value: T = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

# decode uint8 openArray to bigger uint(uint16/uint32/uint64) openArray by big endian
template decodeBEC[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    var value: T = 0

    # decode logic
    for b in static(0 ..< step):
      value = value or (input[i * step + b].T shl ((step - 1 - b) * 8))

    output[i] = value

# encode bigger uint(uint16/uint32/uint64) openArray to uint8 openArray by big endian
template encodeBEC[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
  # set size of T as constant
  const step: int = sizeof(T)

  # loop for input length
  for i in static(0 ..< length):
    let value: T = input[i]

    # encode logic
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

# Little Endian Encode
template toBytesLEC*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(input[])
  # loop for encoding
  for i in static(0 ..< N):
    output[i] = uint8((input[] shr (i * 8)) and 0xFF)

# Big Endian Encode
template toBytesBEC*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(input[])
  # loop for encoding
  for i in static(0 ..< N):
    output[i] = uint8((input[] shr ((N - 1 - i) * 8)) and 0xFF)

# Little Endian Decode
template fromBytesLEC*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
  # check input and output size are same in compile time
  static: doAssert N == sizeof(output[])
  output[] = 0
  # loop for decoding
  for i in static(0 ..< N):
    output[] = output[] or (T(input[i]) shl (i * 8))

# Big Endian Decode
template fromBytesBEC*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
  static: doAssert N == sizeof(output[])
  output[] = 0
  # loop for decoding
  for i in static(0 ..< N):
    output[] = output[] or (T(input[i]) shl ((N - 1 - i) * 8))

# Little Endian Encode
template toBytesLEC*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
  # loop for encoding
  for i in static(0 ..< outputLen):
    output[i] = uint8((input[] shr (i * 8)) and 0xFF)

# Big Endian Encode
template toBytesBEC*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
  # decoding logic
  for i in static(0 ..< outputLen):
    output[i] = uint8((input[] shr ((outputLen - 1 - i) * 8)) and 0xFF)

# Little Endian Decode
template fromBytesLEC*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
  # initialize output
  output[] = 0

  # decoding logic
  for i in static(0 ..< inputLen):
    output[] = output[] or (T(input[i]) shl (i * 8))

# Big Endian Decode
template fromBytesBEC*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
  # initialize output
  output[] = 0
  # decoding logic
  for i in static(0 ..< inputLen):
    output[] = output[] or (T(input[i]) shl (inputLen - 1 - i) * 8)

# export wrapper
when defined(templateOpt):
  template decodeLE*[N1: static[int], N2: static[int], T](input: lent array[N1, uint8], output: var array[N2, T]): void =
    decodeLEC(input, output)

  template encodeLE*[N1: static[int], T1; N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
    encodeLEC(input, output)

  template decodeBE*[N1: static[int], N2: static[int], T2](input: lent array[N1, uint8], output: var array[N2, T2]): void =
    decodeBEC(input, output)

  template encodeBE*[N1: static[int], T1; N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
    encodeBEC(input, output)

  template decodeLE*[T](input: lent openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
    decodeLEC(input, output)

  template encodeLE*[T](input: lent openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
    encodeLEC(input, output)

  template decodeBE*[T](input: lent openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
    decodeBEC(input, output)

  template encodeBE*[T](input: lent openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
    encodeBEC(input, output)

  template decodeLE*[T](input: lent openArray[uint8], output: var openArray[T], length: static int): void =
    decodeLEC(input, output, length)

  template encodeLE*[T](input: lent openArray[T], output: var openArray[uint8], length: static int): void =
    encodeLEC(input, output, length)

  template decodeBE*[T](input: lent openArray[uint8], output: var openArray[T], length: static int): void =
    decodeBEC(input, output, length)

  template encodeBE*[T](input: lent openArray[T], output: var openArray[uint8], length: static int): void =
    encodeBEC(input, output, length)

  template leftRotate*[T: SomeInteger](input: lent T, bits: int): T =
    rotateLeftBits(input, bits)

  template rightRotate*[T: SomeInteger](input: lent T, bits: int): T =
    rotatateRightBits(input, bits)

  template leftRotate*[N: static int](input: lent array[N, uint8], bits: int): array[N, uint8] =
    leftRotateArrayC(input, bits)

  template rightRotate*[N: static int](input: lent array[N, uint8], bits: int): array[N, uint8] =
    rightRotateC(input, bits)

  template toBytesLE*[T: SomeInteger, N: static[int]](input: lent T, output: var array[N, uint8]): void =
    toBytesLEC(input, output)
    
  template toBytesBE*[T: SomeInteger, N: static[int]](input: lent T, output: var array[N, uint8]): void =
    toBytesBEC(input, output)

  template fromBytesLE*[T: SomeInteger, N: static[int]](input: lent array[N, uint8], output: var T): void =
    fromBytesLEC(input, output)

  template fromBytesBE*[T: SomeINteger, N: static[int]](input: lent array[N, uint8], output: var T): void =
    fromBytesBEC(input, output)

  template toBytesLE*[T: BigUint](input: lent T, output: var openArray[uint8]): Result[void, BitsUtilsError] =
    toBytesLEC(input, output)

  template toBytesBE*[T: BigUint](input: lent T, output: var openArray[uint8]): Result[void, BitsUtilsError] =
    toBytesBEC(input, output)

  template fromBytesLE*[T: BigUint](input: lent openArray[uint8], output: var T): Result[void, BitsUtilsError] =
    fromBytesBEC(input, output)

  template fromBytesBE*[T: BigUint](input: lent openArray[uint8], output: var T): Result[void, BitsUtilsError] =
    fromBytesBEC(input, output)

  template `^=`*[T: SomeInteger](x: var T, y: T): void =
    x = x xor y

  template `&=`*[T: SomeInteger](x: var T, y: T): void =
    x = x and y

  template `|=`*[T: SomeInteger](x: var T, y: T): void =
    x = x or y

  template `<<`*[T: SomeInteger](x: T, y: int): T =
    x shl y

  template `>>`*[T: SomeInteger](x: T, y: int): T =
    x shr y

  template `<<<`*[T: SomeInteger](x: T, y: int): T =
    rotateLeftBits(x, y)

  template `>>>`*[T: SomeInteger](x: T, y: int): T =
    rotateRightBits(x, y)

  template `<<<=`*[T: SomeInteger](x: var T, y: int): void =
    x = rotateLeftBits(x, y)

  template `>>>=`*[T: SomeInteger](x: var T, y: int): void =
    x = rotateRightBits(x, y)

  template `shl`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    shlArrayC(x, y)

  template `shr`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    shrArrayC(x, y)

  template `<<`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    shlArrayC(x, y)

  template `>>`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    shrArrayC(x, y)

  template `<<<`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    leftRotateArrayC(x, y)

  template `>>>`*[N: static int](x: lent array[N, uint8], y: int): array[N, uint8] =
    rightRotateArrayC(x, y)

  template `<<<=`*[N: static int](x: var array[N, uint8], y: int): void =
    x = leftRotateArrayC(x, y)

  template `>>>=`*[N: static int](x: var array[N, uint8], y: int): void =
    x = rightRotateArrayC(x, y)

  template bitref8(n: lent uint8): uint8 =
    bitref8C(n)

  template bitref16(n: lent uint16): uint16 =
    bitref16C(n)

  template bitref32(n: lent uint32): uint32 =
    bitref32C(n)

  template bitref64(n: lent uint64): uint64 =
    bitref64C(n)

  template bitref*[T: Uint](n: lent T): T =
    when sizeof(T) == 1:
      bitref8C(n)
    elif sizeof(T) == 2:
      bitref16C(n)
    elif sizeof(T) == 4:
      bitref32C(n)
    elif sizeof(T) == 8:
      bitref64C(n)

  template extend*[T: SomeUnsignedInt](b: uint8): T =
    extendC(b)

  template swap[T](input: T): T =
    swapC(input)

  template swap[N: static int, T](input: lent array[N, T], output: var array[N, T]): void =
    swapC(input, output)

  template swap[T](input: lent openArray[T], output: var openArray[T], length: static int): void =
    swapC(input, output, length)

  template decodeLE*[N1: static[int], N2: static[int], T: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T]): void =
    decodeLEC(input, output)

  template encodeLE*[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
    encodeLEC(input, output)

  template decodeBE*[N1: static[int], N2: static[int], T2: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T2]): void =
    decodeBEC(input, output)

  template encodeBE*[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
    encodeBEC(input, output)

  template decodeLE*[T](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
    decodeLEC(input, output, length)

  template encodeLE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
    encodeLEC(input, output, length)

  template decodeBE*[T](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
    decodeBEC(input, output, length)

  template encodeBE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
    encodeBEC(input, output, length)

  template fromBytesBE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
    fromBytesBEC(input, output, inputLen)

  template fromBytesLE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
    fromBytesLEC(input, output, inputLen)

  template toBytesBE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
    toBytesBEC(input, output, outputLen)

  template toBytesLE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
    toBytesLEC(input, output, outputLen)

  template fromBytesBE*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
    fromBytesBEC(input, output)

  template fromBytesLE*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
    fromBytesLE(input, output)

  template toBytesBE*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
    toBytesBE(input, output)

  template toBytesLE*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
    toBytesLE(input, output)

else:
  func decodeLE*[N1: static[int], N2: static[int], T: BigUint](input: array[N1, uint8], output: var array[N2, T]): void =
    decodeLEC(input, output)

  func encodeLE*[N1: static[int], T1: BigUint, N2: static[int]](input: array[N1, T1], output: var array[N2, uint8]): void =
    encodeLEC(input, output)

  func decodeBE*[N1: static[int], N2: static[int], T2: BigUint](input: array[N1, uint8], output: var array[N2, T2]): void =
    decodeBEC(input, output)

  func encodeBE*[N1: static[int], T1: BigUint, N2: static[int]](input: array[N1, T1], output: var array[N2, uint8]): void =
    encodeBEC(input, output)

  func decodeLE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
    decodeLEC(input, output)

  func encodeLE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
    encodeLEC(input, output)

  func decodeBE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): Result[void, BitsUtilsError] =
    decodeBEC(input, output)

  func encodeBE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): Result[void, BitsUtilsError] =
    encodeBEC(input, output)

  func decodeLE*[T](input: openArray[uint8], output: var openArray[T], length: static int): void =
    decodeLEC(input, output, length)

  func encodeLE*[T](input: openArray[T], output: var openArray[uint8], length: static int): void =
    encodeLEC(input, output, length)

  func decodeBE*[T](input: openArray[uint8], output: var openArray[T], length: static int): void =
    decodeBEC(input, output, length)

  func encodeBE*[T](input: openArray[T], output: var openArray[uint8], length: static int): void =
    encodeBEC(input, output, length)

  func leftRotate*[T: SomeInteger](input: T, bits: T): T =
    return rotateLeftBits(input, bits)

  func rightRotate*[T: SomeInteger](input: T, bits: T): T =
    return rotateRightBits(input, bits)

  func leftRotate*[N: static int](input: array[N, uint8], bits: int): array[N, uint8] =
    return leftRotateArrayC(input, bits)

  func rightRotate*[N: static int](input: array[N, uint8], bits: int): array[N, uint8] =
    return rotateRightBits(input, bits)

  func toBytesLE*[T: SomeInteger, N: static[int]](input: T, output: var array[N, uint8]): void =
    toBytesLEC(input, output)
    return
    
  func toBytesBE*[T: SomeInteger, N: static[int]](input: T, output: var array[N, uint8]): void =
    toBytesBEC(input, output)
    return

  func fromBytesLE*[T: SomeInteger, N: static[int]](input: array[N, uint8], output: var T): void =
    fromBytesLEC(input, output)
    return 

  func fromBytesBE*[T: SomeINteger, N: static[int]](input: array[N, uint8], output: var T): void =
    fromBytesBEC(input, output)
    return 

  func toBytesLE*[T: BigUint](input: T, output: var openArray[uint8]): Result[void, BitsUtilsError] =
    return toBytesLEC(input, output)

  func toBytesBE*[T: BigUint](input: T, output: var openArray[uint8]): Result[void, BitsUtilsError]  =
    return toBytesBEC(input, output)

  func fromBytesLE*[T: BigUint](input: openArray[uint8], output: var T): Result[void, BitsUtilsError] =
    return fromBytesBEC(input, output)

  func fromBytesBE*[T: BigUint](input: openArray[uint8], output: var T): Result[void, BitsUtilsError] =
    return fromBytesBEC(input, output)

  func `&`*[T: SomeInteger](x: T, y: T): T =
    x and y

  func `|`*[T: SomeInteger](x: T, y: T): T =
    x or y

  func `~`*[T: SomeInteger](x: T): T =
    not x

  func `^`*[T: SomeInteger](x: T, y: T): T =
    x xor y

  func `^=`*[T: SomeInteger](x: var T, y: T): void =
    x = x xor y
    return 

  func `&=`*[T: SomeInteger](x: var T, y: T): void =
    x = x and y
    return 

  func `|=`*[T: SomeInteger](x: var T, y: T): void =
    x = x or y
    return

  func `<<`*[T: SomeInteger](x: T, y: T): T =
    return x shl y

  func `>>`*[T: SomeInteger](x: T, y: T): T =
    return x shr y

  func `<<<`*[T: SomeInteger](x: T, y: T): T =
    return rotateLeftBits(x, y)

  func `>>>`*[T: SomeInteger](x: T, y: T): T =
    return rotateRightBits(x, y)

  func `<<<=`*[T: SomeInteger](x: var T, y: T): void =
    x = rotateLeftBits(x, y)
    return 

  func `>>>=`*[T: SomeInteger](x: var T, y: T): void =
    x = rotateRightBits(x, y)
    return 

  func `shl`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    shlArrayC(x, y)

  func `shr`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    shrArrayC(x, y)

  func `<<`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    shlArrayC(x, y)

  func `>>`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    shrArrayC(x, y)

  func `<<<`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    leftRotateArrayC(x, y)

  func `>>>`*[N: static int](x: array[N, uint8], y: int): array[N, uint8] =
    rightRotateArrayC(x, y)

  func `<<<=`*[N: static int](x: var array[N, uint8], y: int): void =
    x = leftRotateArrayC(x, y)

  func `>>>=`*[N: static int](x: var array[N, uint8], y: int): void =
    x = rightRotateArrayC(x, y)

  func bitref8(n: uint8): uint8 =
    bitref8C(n)

  func bitref16(n: uint16): uint16 =
    bitref16C(n)

  func bitref32(n: uint32): uint32 =
    bitref32C(n)

  func bitref64(n: uint64): uint64 =
    bitref64C(n)

  func bitref*[T: Uint](n: T): T =
    when sizeof(T) == 1:
      bitref8C(n)
    elif sizeof(T) == 2:
      bitref16C(n)
    elif sizeof(T) == 4:
      bitref32C(n)
    elif sizeof(T) == 8:
      bitref64C(n)

  func extend*[T: SomeUnsignedInt](b: uint8): T =
    extendC(b)

  func swap[T](input: T): T =
    swapC(input)

  func swap[N: static int, T](input: array[N, T], output: var array[N, T]): void =
    swapC(input, output)

  func swap[T](input: openArray[T], output: var openArray[T], length: static int): void =
    swapC(input, output, length)

  func decodeLE*[N1: static[int], N2: static[int], T: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T]): void =
    decodeLEC(input, output)

  func encodeLE*[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
    encodeLEC(input, output)

  func decodeBE*[N1: static[int], N2: static[int], T2: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T2]): void =
    decodeBEC(input, output)

  func encodeBE*[N1: static[int], T1: BigUint, N2: static[int]](input: ptr array[N1, T1], output: ptr array[N2, uint8]): void =
    encodeBEC(input, output)

  func decodeLE*[T](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
    decodeLEC(input, output, length)

  func encodeLE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
    encodeLEC(input, output, length)

  func decodeBE*[T](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], length: static int): void =
    decodeBEC(input, output, length)

  func encodeBE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], length: static int): void =
    encodeBEC(input, output, length)

  func fromBytesBE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
    fromBytesBEC(input, output, inputLen)

  func fromBytesLE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T, inputLen: static int): void =
    fromBytesLEC(input, output, inputLen)

  func toBytesBE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
    toBytesBEC(input, output, outputLen)

  func toBytesLE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8], outputLen: static int): void =
    toBytesLEC(input, output, outputLen)

  func fromBytesBE*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
    fromBytesBEC(input, output)

  func fromBytesLE*[T: BigUint, N: static[int]](input: ptr array[N, uint8], output: ptr T): void =
    fromBytesLEC(input, output)

  func toBytesBE*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
    toBytesBEC(input, output)

  func toBytesLE*[T: BigUint, N: static[int]](input: ptr T, output: ptr array[N, uint8]): void =
    toBytesLEC(input, output)
