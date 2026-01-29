{.experimental: "strictNotNil".}

type
  BitsUtilsError* = enum
    TooBigN = 0
    NotSameSize = 1
  BigUint = concept u
    u is (uint16|uint32|uint64)
  Uint = concept u
    u is (uint8|uint16|uint32|uint64)

template decodeLEC[N1: static[int], N2: static[int], T2: BigUint](input: lent array[N1, uint8], output: var array[N2, T2]): void =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  const step: int = sizeof(T2)

  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl (b * 8))

    output[i] = value

template encodeLEC[N1: static[int], T1: BigUint, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  const step: int = sizeof(T1)

  for i in static(0 ..< N1):
    let value: T1 = input[i]
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

template decodeBEC[N1: static[int], N2: static[int], T2: BigUint](input: lent array[N1, uint8], output: var array[N2, T2]): void =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T2) * N2, "The total size of input and output must be same"

  const step: int = sizeof(T2)

  for i in static(0 ..< N2):
    var value: T2 = 0
    let startIndex: int = i * step

    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T2 shl ((sizeof(T2) - 1 - b) * 8))

    output[i] = value

template encodeBEC[N1: static[int], T1: BigUint, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
  static:
    doAssert sizeof(T1) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same"

  const step: int = sizeof(T1)

  for i in static(0 ..< N1):
    let value: T1 = input[i]
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

template decodeLEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T]): void =
  if input.len * sizeof(uint8) != output.len * sizeof(T):
    raise newException(IndexError, "output and input's total size must be same.")

  const step: int = sizeof(T)

  for i in 0 ..< output.len:
    var value: T = 0
    let startIndex: int = i * step

    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T shl (b * 8))

    output[i] = value

template encodeLEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8]): void =
  if input.len * sizeof(T) != output.len * sizeof(uint8):
    raise newException(IndexError, "outpu and input's total size must be same.")

  const step: int = sizeof(T)

  for i in 0 ..< input.len:
    let value: T = input[i]
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr (b * 8)) and 0xFF)

template decodeBEC[T: BigUint](input: lent openArray[uint8], output: var openArray[T]): void =
  if input.len * sizeof(uint8) != output.len * sizeof(T):
    raise newException(IndexError, "output and input's total size must be same.")

  const step: int = sizeof(T)

  for i in 0 ..< output.len:
    var value: T = 0
    let startIndex: int = i * step

    for b in static(0 ..< step):
      value = value or (input[startIndex + b].T shl ((step - 1 - b) * 8))

    output[i] = value

template encodeBEC[T: BigUint](input: lent openArray[T], output: var openArray[uint8]): void =
  if input.len * sizeof(T) != output.len * sizeof(uint8):
    raise newException(IndexError, "outpu and input's total size must be same.")

  const step: int = sizeof(T)

  for i in 0 ..< input.len:
    let value: T = input[i]
    for b in static(0 ..< step):
      output[i * step + b] = uint8((value shr ((step - 1 - b) * 8)) and 0xFF)

template leftRotateC[T: SomeInteger](value: lent T, shift: lent T): T =
  let bitCount: T = sizeof(T) * 8
  let realShift = shift mod bitCount
    
  ((value shl realShift) or (value shr (T(sizeof(T) * 8) - realShift)))

template rightRotateC[T: SomeInteger](value: lent T, shift: lent T): T =
  let bitCount: T = sizeof(T) * 8
  let realShift = shift mod bitCount
    
  ((value shr realShift) or (value shl (T(sizeof(T) * 8) - realShift)))

# Little Endian Encode
template toBytesLEC*[T: BigUint, N: static[int]](x: lent T, result: var array[N, uint8]): void =
  static: doAssert N == sizeof(x)
  for i in static(0 ..< N):
    result[i] = uint8((x shr (i * 8)) and 0xFF)

# Big Endian Encode
template toBytesBEC*[T: BigUint, N: static[int]](x: lent T, result: var array[N, uint8]): void =
  static: doAssert N == sizeof(x)
  for i in static(0 ..< N):
    result[i] = uint8((x shr ((N - 1 - i) * 8)) and 0xFF)

# Little Endian Decode
template fromBytesLEC*[T: BigUint, N: static[int]](src: lent array[N, uint8], ret: var T): void =
  static: doAssert N == sizeof(ret)
  ret = 0
  for i in static(0 ..< N):
    ret = ret or (T(src[i]) shl (i * 8))

# Big Endian Decode
template fromBytesBEC*[T: BigUint, N: static[int]](src: lent array[N, uint8], ret: var T): void =
  static: doAssert N == sizeof(ret)
  ret = 0
  for i in static(0 ..< N):
    ret = ret or (T(src[i]) shl ((N - 1 - i) * 8))

# Little Endian Encode
template toBytesLEC*[T: BigUint](x: lent T, ret: var openArray[uint8]): void =
  if sizeof(T) != ret.len * sizeof(uint8):
    raise newException(IndexError, "T and ret's total size must be same.")
  for i in 0 ..< ret.len:
    ret[i] = uint8((x shr (i * 8)) and 0xFF)

# Big Endian Encode
template toBytesBEC*[T: BigUint](x: lent T, ret: var openArray[uint8]): void =
  if sizeof(T) != ret.len * sizeof(uint8):
    raise newException(IndexError, "T and ret's total size must be same.")
  for i in 0 ..< ret.len:
    ret[i] = uint8((x shr ((ret.len - 1 - i) * 8)) and 0xFF)

# Little Endian Decode
template fromBytesLEC*[T: BigUint](src: lent openArray[uint8], ret: var T): void =
  if sizeof(T) != src.len * sizeof(uint8):
    raise newException(IndexError, "T and ret's total size must be same.")
  ret = 0
  for i in static(0 ..< sizeof(ret)):
    ret = ret or (T(src[i]) shl (i * 8))

# Big Endian Decode
template fromBytesBEC*[T: BigUint](src: lent openArray[uint8], ret: var T): void =
  if sizeof(T) != src.len * sizeof(uint8):
    raise newException(IndexError, "T and ret's total size must be same.")
  ret = 0
  for i in static(0 ..< sizeof(ret)):
    ret = ret or (T(src[i]) shl ((sizeof(ret) - 1 - i) * 8))

template bitref8C(n: lent uint8): uint8 =
  var x = n
  x = (x shr 4) or (x shl 4)
  x = ((x shr 2) and 0x33'u8) or ((x shl 2) and 0xCC'u8)
  x = ((x shr 1) and 0x55'u8) or ((x shl 1) and 0xAA'u8)
  x

template bitref16C(n: lent uint16): uint16 =
  var x = n
  x = (x shr 8) or (x shl 8)
  x = ((x shr 4) and 0x0F0F'u16) or ((x shl 4) and 0xF0F0'u16)
  x = ((x shr 2) and 0x3333'u16) or ((x shl 2) and 0xCCCC'u16)
  x = ((x shr 1) and 0x5555'u16) or ((x shl 1) and 0xAAAA'u16)
  x

template bitref32C(n: lent uint32): uint32 =
  var x = n
  x = (x shr 16) or (x shl 16)
  x = ((x shr 8) and 0x00FF00FF'u32) or ((x shl 8) and 0xFF00FF00'u32)
  x = ((x shr 4) and 0x0F0F0F0F'u32) or ((x shl 4) and 0xF0F0F0F0'u32)
  x = ((x shr 2) and 0x33333333'u32) or ((x shl 2) and 0xCCCCCCCC'u32)
  x = ((x shr 1) and 0x55555555'u32) or ((x shl 1) and 0xAAAAAAAA'u32)
  x

template bitref64C(n: lent uint64): uint64 =
  var x = n
  x = (x shr 32) or (x shl 32)
  x = ((x shr 16) and 0x0000FFFF0000FFFF'u64) or ((x shl 16) and 0xFFFF0000FFFF0000'u64)
  x = ((x shr 8) and 0x00FF00FF00FF00FF'u64) or ((x shl 8) and 0xFF00FF00FF00FF00'u64)
  x = ((x shr 4) and 0x0F0F0F0F0F0F0F0F'u64) or ((x shl 4) and 0xF0F0F0F0F0F0F0F0'u64)
  x = ((x shr 2) and 0x3333333333333333'u64) or ((x shl 2) and 0xCCCCCCCCCCCCCCCC'u64)
  x = ((x shr 1) and 0x5555555555555555'u64) or ((x shl 1) and 0xAAAAAAAAAAAAAAA'u64)
  x

# export wrapper
when defined(templateOpt):
  template decodeLE*[N1: static[int], N2: static[int], T](input: lent array[N1, uint8], output: var array[N2, T]): void =
    decodeLEC(input, output)

  template encodeLE*[N1: static[int], T1, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
    encodeLEC(input, output)

  template decodeBE*[N1: static[int], N2: static[int], T2](input: lent array[N1, uint8], output: var array[N2, T2]): void =
    decodeBEC(input, output)

  template encodeBE*[N1: static[int], T1, N2: static[int]](input: lent array[N1, T1], output: var array[N2, uint8]): void =
    encodeBEC(input, output)

  template decodeLE*[T](input: lent openArray[uint8], output: var openArray[T]): void =
    decodeLEC(input, output)

  template encodeLE*[T](input: lent openArray[T], output: var openArray[uint8]): void =
    encodeLEC(input, output)

  template decodeBE*[T](input: lent openArray[uint8], output: var openArray[T]): void =
    decodeBEC(input, output)

  template encodeBE*[T](input: lent openArray[T], output: var openArray[uint8]): void =
    encodeBEC(input, output)

  template leftRotate*[T: SomeInteger](x: lent T, n: lent T): T =
    var result: T = leftRotateC(x, n)
    result

  template rightRotate*[T: SomeInteger](x: lent T, n: lent T): T =
    var result: T = rightRotateC(x, n)
    result

  template toBytesLE*[T: SomeInteger, N: static[int]](input: lent T, output: var array[N, uint8]): void =
    toBytesLEC(input, output)
    
  template toBytesBE*[T: SomeInteger, N: static[int]](input: lent T, output: var array[N, uint8]): void =
    toBytesBEC(input, output)

  template fromBytesLE*[T: SomeInteger, N: static[int]](input: lent array[N, uint8], output: var T): void =
    fromBytesLEC(input, output)

  template fromBytesBE*[T: SomeINteger, N: static[int]](input: lent array[N, uint8], output: var T): void =
    fromBytesBEC(input, output)

  template toBytesLE*[T: BigUint](x: lent T, ret: var openArray[uint8]): void =
    toBytesLEC(x, ret)

  template toBytesBE*[T: BigUint](x: lent T, ret: var openArray[uint8]): void  =
    toBytesBEC(x, ret)

  template fromBytesLE*[T: BigUint](src: lent openArray[uint8], ret: var T): void  =
    fromBytesBEC(src, ret)

  template fromBytesBE*[T: BigUint](src: lent openArray[uint8], ret: var T): void  =
    fromBytesBEC(src, ret)

  template `^=`*[T: SomeInteger](x: var T, y: T): void =
    x = x xor y

  template `&=`*[T: SomeInteger](x: var T, y: T): void =
    x = x and y

  template `|=`*[T: SomeInteger](x: var T, y: T): void =
    x = x or y

  template `<<`*[T: SomeInteger](x: T, y: T): T =
    x shl y

  template `>>`*[T: SomeInteger](x: T, y: T): T =
    x shr y

  template `<<<`*[T: SomeInteger](x: T, y: T): T =
    leftRotateC(x, y)

  template `>>>`*[T: SomeInteger](x: T, y: T): T =
    rightRotateC(x, y)

  template `<<<=`*[T: SomeInteger](x: var T, y: T): void =
    x = leftRotateTemplate(x, y)

  template `>>>=`*[T: SomeInteger](x: var T, y: T): void =
    x = rightRotateTemplate(x, y)

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

else:
  func decodeLE*[N1: static[int], N2: static[int], T: BigUint](input: array[N1, uint8], output: var array[N2, T]): void =
    decodeLEC(input, output)

  func encodeLE*[N1: static[int], T1: BigUint, N2: static[int]](input: array[N1, T1], output: var array[N2, uint8]): void =
    encodeLEC(input, output)

  func decodeBE*[N1: static[int], N2: static[int], T2: BigUint](input: array[N1, uint8], output: var array[N2, T2]): void =
    decodeBEC(input, output)

  func encodeBE*[N1: static[int], T1: BigUint, N2: static[int]](input: array[N1, T1], output: var array[N2, uint8]): void =
    encodeBEC(input, output)

  func decodeLE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): void =
    decodeLEC(input, output)

  func encodeLE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): void =
    encodeLEC(input, output)

  func decodeBE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): void =
    decodeBEC(input, output)

  func encodeBE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): void =
    encodeBEC(input, output)

  func leftRotate*[T: SomeInteger](x: T, n: T): T =
    result = leftRotateC(x, n)
    return result

  func rightRotate*[T: SomeInteger](x: T, n: T): T =
    result = rightRotateC(x, n)
    return result

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

  func toBytesLE*[T: BigUint](x: T, ret: var openArray[uint8]): void =
    toBytesLEC(x, ret)

  func toBytesBE*[T: BigUint](x: T, ret: var openArray[uint8]): void  =
    toBytesBEC(x, ret)

  func fromBytesLE*[T: BigUint](src: openArray[uint8], ret: var T): void  =
    fromBytesBEC(src, ret)

  func fromBytesBE*[T: BigUint](src: openArray[uint8], ret: var T): void  =
    fromBytesBEC(src, ret)

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
    x shl y
    return 

  func `>>`*[T: SomeInteger](x: T, y: T): T =
    x shr y
    return 

  func `<<<`*[T: SomeInteger](x: T, y: T): T =
    leftRotateC(x, y)
    return 

  func `>>>`*[T: SomeInteger](x: T, y: T): T =
    rightRotateC(x, y)
    return 

  func `<<<=`*[T: SomeInteger](x: var T, y: T): void =
    x = leftRotateC(x, y)
    return 

  func `>>>=`*[T: SomeInteger](x: var T, y: T): void =
    x = rightRotateC(x, y)
    return 

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
