import std/bitops
import std/endians
import envconst
import arraytype
import autoopt

type
  BigUint = concept u
    u is (uint16|uint32|uint64)

# getBN : get Nth byte of a BigUint
# usage : when you need to get a byte from a BigUint
# not depend on endian order

template getB0*(a: uint16): int = int((a shr 0) and 0xFF'u16)
template getB1*(a: uint16): int = int((a shr 8) and 0xFF'u16)

template getB0*(a: uint32): int = int((a shr 0) and 0xFF'u32)
template getB1*(a: uint32): int = int((a shr 8) and 0xFF'u32)
template getB2*(a: uint32): int = int((a shr 16) and 0xFF'u32)
template getB3*(a: uint32): int = int((a shr 24) and 0xFF'u32)

template getB0*(a: uint64): int = int((a shr 0) and 0xFF'u64)
template getB1*(a: uint64): int = int((a shr 8) and 0xFF'u64)
template getB2*(a: uint64): int = int((a shr 16) and 0xFF'u64)
template getB3*(a: uint64): int = int((a shr 24) and 0xFF'u64)
template getB4*(a: uint64): int = int((a shr 32) and 0xFF'u64)
template getB5*(a: uint64): int = int((a shr 40) and 0xFF'u64)
template getB6*(a: uint64): int = int((a shr 48) and 0xFF'u64)
template getB7*(a: uint64): int = int((a shr 56) and 0xFF'u64)

# swapEndian : swap endian
# use Nim's default swapEndian code
template swapEndian*[T: SomeUnsignedInt](input: T, output: var T): void {.autoSizeOpt.} =
  when T is uint64:
    swapEndian64(addr output, addr input)
  elif T is uint32:
    swapEndian32(addr output, addr input)
  elif T is uint16:
    swapEndian16(addr output, addr input)
  else:
    output = input

template swapEndian*[T: SomeUnsignedInt, N: static int](input: array[N, T], output: var array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    swapEndian(input[i], output[i])

template swapEndian*[T: SomeUnsignedInt, N: static int](input, output: slicearray[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    swapEndian(input[i], output[i])

template swapEndian*[T: SomeUnsignedInt, N: static int](input: ptr array[N, T], output: ptr array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    swapEndian(input[i], output[i])


# toLE : to little endian generic function
# use Nim's default littleEndian code 
template toLE*[T: SomeUnsignedInt](input: T, output: var T): void {.autoSizeOpt.} =
  when T is uint64:
    littleEndian64(addr output, addr input)
  elif T is uint32:
    littleEndian32(addr output, addr input)
  elif T is uint16:
    littleEndian16(addr output, addr input)
  else:
    output = input

# toBE : to big endian generic function
# use Nim's default bigEndian code
template toBE*[T: SomeUnsignedInt](input: T, output: var T): void {.autoSizeOpt.} =
  when T is uint64:
    bigEndian64(addr output, addr input)
  elif T is uint32:
    bigEndian32(addr output, addr input)
  elif T is uint16:
    bigEndian16(addr output, addr input)
  else:
    output = input

# beToNative : big endian to native endian
# warning ; input's endian must be big endian
template beToNative*[T: BigUint](input: T, output: var T): void {.autoSizeOpt.} =
  when cpuEndian == littleEndian:
    swapEndian(input, output)
  else:
    output = input

template beToNative*[T: BigUint, N: static int](input: array[N, T], output: var array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint](input: openArray[T], output: var openArray[T]): void {.autoSizeOpt.} =
  for i in 0 ..< input.len:
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint](input: openArray[T], output: var openArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint, N: static int](input, output: slicearray[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint, N: static int](input: ptr array[N, T], output: ptr array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: int): void {.autoSizeOpt.} =
  for i in 0 ..< length:
    beToNative(input[i], output[i]) 

template beToNative*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    beToNative(input[i], output[i]) 

# nativeToBE : native endian to big endian
# warning : input's endian must be native endian
template nativeToBE*[T: BigUint](input: T, output: var T): void {.autoSizeOpt.} =
  when cpuEndian == littleEndian:
    swapEndian(input, output)
  else:
    output = input

template nativeToBE*[T: BigUint, N: static int](input: array[N, T], output: var array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint](input: openArray[T], output: var openArray[T]): void {.autoSizeOpt.} =
  for i in 0 ..< input.len:
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint](input: openArray[T], output: var openArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint, N: static int](input, output: slicearray[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint, N: static int](input: ptr array[N, T], output: ptr array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: int): void {.autoSizeOpt.} =
  for i in 0 ..< length:
    nativeToBE(input[i], output[i])

template nativeToBE*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    nativeToBE(input[i], output[i])

# leToNative : little endian to native endian
# warning : input's endian must be little endian
template leToNative*[T: BigUint](input: T, output: var T): void {.autoSizeOpt.} =
  when cpuEndian == bigEndian:
    swapEndian(input, output)
  else:
    output = input

template leToNative*[T: BigUint, N: static int](input: array[N, T], output: var array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    leToNative(input[i], output[i])

template leToNative*[T: BigUint](input: openArray[T], output: var openArray[T]): void {.autoSizeOpt.} =
  for i in 0 ..< input.len:
    leToNative(input[i], output[i])

template leToNative*[T: BigUint](input: openArray[T], output: var openArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    leToNative(input[i], output[i])

template leToNative*[T: BigUint, N: static int](input, output: slicearray[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    leToNative(input[i], output[i])

template leToNative*[T: BigUint, N: static int](input: ptr array[N, T], output: ptr array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    leToNative(input[i], output[i])

template leToNative*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: int): void {.autoSizeOpt.} =
  for i in 0 ..< length:
    leToNative(input[i], output[i])

template leToNative*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    leToNative(input[i], output[i])

# nativeToLE : native endian to little endian
# warning : input's endian must be native endian
template nativeToLE*[T: BigUint](input: T, output: var T): void {.autoSizeOpt.} =
  when cpuEndian == bigEndian:
    swapEndian(input, output)
  else:
    output = input

template nativeToLE*[T: BigUint, N: static int](input: array[N, T], output: var array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToLE(input[i], output[i])

template nativeToLE*[T: BigUint](input: openArray[T], output: var openArray[T]): void {.autoSizeOpt.} =
  for i in 0 ..< input.len:
    nativeToLE(input[i], output[i])

template nativeToLE*[T: BigUint](input: openArray[T], output: var openArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    nativeToLE(input[i], output[i])
    
template nativeToLE*[T: BigUint, N: static int](input, output: slicearray[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToLE(input[i], output[i])

template nativeToLE*[T: BigUint, N: static int](input: ptr array[N, T], output: ptr array[N, T]): void {.autoSizeOpt.} =
  unroll(i, 0, N - 1):
    nativeToLE(input[i], output[i])

template nativeToLE*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: int): void {.autoSizeOpt.} =
  for i in 0 ..< length:
    nativeToLE(input[i], output[i])

template nativeToLE*[T: BigUint](input: ptr UncheckedArray[T], output: ptr UncheckedArray[T], length: static int): void {.autoSizeOpt.} =
  unroll(i, 0, length - 1):
    nativeToLE(input[i], output[i])

# decodeLE : uint8 array to big uint array by little endian
# array version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[N1, N2: static int, T: BigUint](input: array[N1, uint8], output: var array[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."
 
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output)

# decodeLE : uint8 array to big uint array by little endian
# slicearray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[N1, N2: static int, T: BigUint](input: slicearray[N1, uint8], output: slicearray[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output)


# decodeLE : uint8 array to big uint array by little endian
# openArray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< output.len:
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    let size: int = input.len * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output)

# decodeLE : uint8 array to big uint array by little endian
# openArray and static length version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[T: BigUint](input: openArray[uint8], output: var openArray[T], outputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, outputLen - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    const size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output, outputLen)

# decodeLE : uint8 array to big uint array by little endian
# ptr array version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[N1, N2: static int, T: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output)

# decodeLE : uint8 array to big uint array by little endian
# ptr UncheckedArray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], outputLen: int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)

    for i in 0 ..< outputLen:
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    let size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output, outputLen)

# decodeLE : uint8 array to big uint array by little endian
# ptr UncheckedArray and static length version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeLE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], outputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, outputLen - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl (b * 8))
  else:
    const size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not LE:
      leToNative(output, output, outputLen)

# decodeBE : uint8 array to big uint array by big endian
# array version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[N1, N2: static int, T: BigUint](input: array[N1, uint8], output: var array[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output)

# decodeBE : uint8 array to big uint array by big endian
# slicearray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[N1, N2: static int, T: BigUint](input: slicearray[N1, uint8], output: slicearray[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output)

# decodeBE : uint8 array to big uint array by big endian
# openArray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[T: BigUint](input: openArray[uint8], output: var openArray[T]): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< output.len:
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    let size: int = input.len * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output)

# decodeBE : uint8 array to big uint array by big endian
# openArray and static length version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[T: BigUint](input: openArray[uint8], output: var openArray[T], outputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, outputLen - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    const size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output, outputLen)

# decodeBE : uint8 array to big uint array by big endian
# ptr array version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[N1, N2: static int, T: BigUint](input: ptr array[N1, uint8], output: ptr array[N2, T]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(uint8) * N1 == sizeof(T) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N2 - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    const size: int = N1 * sizeof(uint8)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output)

# decodeBE : uint8 array to big uint array by big endian
# ptr UncheckedArray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], outputLen: int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< outputLen:
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    let size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output, outputLen)

# decodeBE : uint8 array to big uint array by big endian
# ptr UncheckedArray and static length version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64 array
template decodeBE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr UncheckedArray[T], outputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, outputLen - 1):
      output[i] = 0
      unroll(b, 0, step - 1):
        output[i] = output[i] or (input[i * step + b].T shl ((step - 1 - b) * 8))
  else:
    const size: int = outputLen * sizeof(T)
    copyMem(addr output[0], addr input[0], size)
    when not BE:
      beToNative(output, output, outputLen)

# encodeLE : big uint array to uint8 array by little endian
# array version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[N1, N2: static int, T: BigUint](input: array[N1, T], output: var array[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(addr input[0], cast[ptr array[N1, T]](addr output[0]))

# encodeLE : big uint array to uint8 array by little endian
# slicearray version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[N1, N2: static int, T: BigUint](input: slicearray[N1, T], output: slicearray[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(input, output.castTo(T))

# encodeLE : big uint array to uint8 array by little endian
# openArray version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< input.len:
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    let size: int = input.len * sizeof(T)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(cast[ptr UncheckedArray[T]](addr input[0]), cast[ptr UncheckedArray[T]](addr output[0]), input.len)

# encodeLE : big uint array to uint8 array by little endian
# openArray and static length version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[T: BigUint](input: openArray[T], output: var openArray[uint8], inputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, inputLen - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    const size: int = inputLen * sizeof(T)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(cast[ptr UncheckedArray[T]](addr input[0]), cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# encodeLE : big uint array to uint8 array by little endian
# ptr array version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[N1, N2: static int, T](input: ptr array[N1, T], output: ptr array[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(input, cast[ptr array[N1, T]](addr output[0]))

# encodeLE : big uint array to uint8 array by little endian
# ptr UncheckedArray version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], inputLen: int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< inputLen:
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    let size: int = inputLen * sizeof(T)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(input, cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# encodeLE : big uint array to uint8 array by little endian
# ptr UncheckedArray and static length version
# input : cpu native endian uint16/uint32/uint64 array
# output : little endian uint8 array
template encodeLE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], inputLen: static int): void {.autoSizeOpt.} =
  const step: int = sizeof(T)

  when defined(nostd):
    unroll(i, 0, inputLen - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr (b * 8)) and 0xFF)
  else:
    const size: int = inputLen * sizeof(T)
    when LE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToLE(input, cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# encodeBE : big uint array to uint8 array by big endian
# array version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[N1, N2: static int, T: BigUint](input: array[N1, T], output: var array[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(addr input, cast[ptr array[N1, T]](addr output[0]))

# encodeBE : big uint array to uint8 array by big endian
# slicearray version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[N1, N2: static int, T: BigUint](input: slicearray[N1, T], output: slicearray[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."

  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(input, output.castTo(T))

# encodeBE : big uint array to uint8 array by big endian
# openArray version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[T: BigUint](input: openArray[T], output: var openArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< input.len:
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    let size: int = input.len * sizeof(T)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(cast[ptr UncheckedArray[T]](addr input[0]), cast[ptr UncheckedArray[T]](addr output[0]), input.len)

# encodeBE : big uint array to uint8 array by big endian
# openArray and static length version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[T: BigUint](input: openArray[T], output: var openArray[uint8], inputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, inputLen - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    const size: int = inputLen * sizeof(T)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(cast[ptr UncheckedArray[T]](addr input[0]), cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# encodeBE : big uint array to uint8 array by big endian
# ptr array version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[N1, N2: static int, T](input: ptr array[N1, T], output: ptr array[N2, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert sizeof(T) * N1 == sizeof(uint8) * N2, "The total size of input and output must be same."
 
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, N1 - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    const size: int = N2 * sizeof(uint8)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(addr input[0], cast[ptr array[N1, T]](addr output[0]))

# encodeBE : big uint array to uint8 array by big endian
# ptr UncheckedArray version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 array
template encodeBE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], inputLen: int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    for i in 0 ..< inputLen:
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    let size: int = inputLen * sizeof(T)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(input, cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# encodeBE : big uint array to uint8 array by big endian
# ptr UncheckedArray and static length version
# input : cpu native endian uint16/uint32/uint64 array
# output : big endian uint8 arrayimport ../../../../Utility/src/Utility/codeutils/bits
import ../../../../Utility/src/Utility/codeutils/errorutils
import ../../../../Utility/src/Utility/codeutils/arraytype
import ../../../../Utility/src/Utility/dataformat/dataformat
import std/[monotimes, times]
import std/bitops
import std/endians
template encodeBE*[T](input: ptr UncheckedArray[T], output: ptr UncheckedArray[uint8], inputLen: static int): void {.autoSizeOpt.} =
  when defined(nostd):
    const step: int = sizeof(T)
    unroll(i, 0, inputLen - 1):
      unroll(b, 0, step - 1):
        output[i * step + b] = uint8((input[i] shr ((step - b - 1) * 8)) and 0xFF)
  else:
    const size: int = inputLen * sizeof(T)
    when BE:
      copyMem(addr output[0], addr input[0], size)
    else:
      nativeToBE(input, cast[ptr UncheckedArray[T]](addr output[0]), inputLen)

# fromBytesLE : uint8 array to big uint
# array version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesLE*[T: BigUint, N: static int](input: array[N, uint8], output: var T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd): 
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl (b * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not LE:
      leToNative(output, output)

# fromBytesLE : uint8 array to big uint
# slicearray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesLE*[T: BigUint, N: static int](input: slicearray[N, uint8], output: var T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl (b * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not LE:
      leToNative(output, output)

# fromBytesLE : uint8 array to big uint
# openArray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesLE*[T: BigUint](input: openArray[uint8], output: var T): void {.autoSizeOpt.} =
  when defined(nostd):
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl (b * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not LE:
      leToNative(output, output)

# fromBytesLE : uint8 array to big uint
# ptr array version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesLE*[T: BigUint, N: static int](input: ptr array[N, uint8], output: ptr T): void {.autoSizeOpt.} =  
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."
  
  when defined(nostd):
    output[] = 0
    unroll(b, 0, sizeof(T) - 1):
      output[] = output[] or (input[b].T shl (b * 8))
  else:
    const size: int = sizeof(T)
    copyMem(output, input, size)
    when not LE:
      leToNative(output, output)

# fromBytesLE : uint8 array to big uint
# ptr UncheckedArray version
# input : little endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesLE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    output[] = 0
    unroll(b, 0, sizeof(T) - 1):
      output[] = output[] or (input[b].T shl (b * 8))
  else:
    const size: int = sizeof(T)
    copyMem(output, input, size)
    when not LE:
      leToNative(output, output)

# fromBytesBE : uint8 array to big uint by big endian
# array version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesBE*[T: BigUint, N: static int](input: array[N, uint8], output: var T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl ((sizeof(T) - 1 - b) * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not BE:
      beToNative(output, output)

# fromBytesBE : uint8 array to big uint by big endian
# slicearray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesBE*[T: BigUint, N: static int](input: slicearray[N, uint8], output: var T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl ((sizeof(T) - 1 - b) * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not BE:
      beToNative(output, output)

# fromBytesBE : uint8 array to big uint by big endian
# openArray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesBE*[T: BigUint](input: openArray[uint8], output: var T): void {.autoSizeOpt.} =
  when defined(nostd):
    output = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl ((sizeof(T) - 1 - b) * 8))
  else:
    const size: int = sizeof(T)
    copyMem(addr output, addr input[0], size)
    when not BE:
      beToNative(output, output)

# fromBytesBE : uint8 array to big uint by big endian
# ptr array version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesBE*[T: BigUint, N: static int](input: ptr array[N, uint8], output: ptr T): void {.autoSizeOpt.} =  
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."
  
  when defined(nostd):
    output[] = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl ((sizeof(T) - 1 - b) * 8))
  else:
    const size: int = sizeof(T)
    copyMem(output, input, size)
    when not BE:
      beToNative(output, output)

# fromBytesBE : uint8 array to big uint by big endian
# ptr UncheckedArray version
# input : big endian uint8 array
# output : cpu native endian uint16/uint32/uint64
template fromBytesBE*[T: BigUint](input: ptr UncheckedArray[uint8], output: ptr T): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    output[] = 0
    unroll(b, 0, sizeof(T) - 1):
      output = output or (input[b].T shl ((sizeof(T) - 1 - b) * 8))
  else:
    const size: int = sizeof(T)
    copyMem(output, input, size)
    when not BE:
      beToNative(output, output)

# toBytesLE : big uint to uint8 array by little endian
# array version
# input : cpu native endian uint16/uint32/uint64
# output : little endian uint8 array
template toBytesLE*[N: static int, T: BigUint](input: T, output: var array[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr (b * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when LE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr (b * 8)) and 0xFF)

# toBytesLE : big uint to uint8 array by little endian
# slicearray version
# input : cpu native endian uint16/uint32/uint64
# output : little endian uint8 array
template toBytesLE*[N: static int, T: BigUint](input: T, output: slicearray[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr (b * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when LE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr (b * 8)) and 0xFF)

# toBytesLE : big uint to uint8 array by little endian
# openArray version
# input : cpu native endian uint16/uint32/uint64
# output : little endian uint8 array
template toBytesLE*[T: BigUint](input: T, output: openArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr (b * 8)) and 0xFF)
  else:
    when LE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr (b * 8)) and 0xFF)

# toBytesLE : big uint to uint8 array by little endian
# ptr array version
# input : cpu native endian uint16/uint32/uint64
# output : little endian uint8 array
template toBytesLE*[N: static int, T: BigUint](input: ptr T, output: ptr array[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input[] shr (b * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when LE:
      copyMem(output, input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input[] shr (b * 8)) and 0xFF)

# toBytesLE : big uint to uint8 array by little endian
# ptr UncheckedArray version
# input : cpu native endian uint16/uint32/uint64
# output : little endian uint8 array
template toBytesLE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input[] shr (b * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when LE:
      copyMem(output, input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input[] shr (b * 8)) and 0xFF)

# toBytesBE : big uint to uint8 array by big endian
# array version
# input : cpu native endian uint16/uint32/uint64
# output : big endian uint8 array
template toBytesBE*[N: static int, T: BigUint](input: T, output: var array[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when BE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)

# toBytesBE : big uint to uint8 array by big endian
# slicearray version
template toBytesBE*[N: static int, T: BigUint](input: T, output: slicearray[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when BE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)

# toBytesBE : big uint to uint8 array by big endian
# openArray version
template toBytesBE*[T: BigUint](input: T, output: openArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when BE:
      copyMem(addr output[0], addr input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)

# toBytesBE : big uint to uint8 array by big endian
# ptr array version
template toBytesBE*[N: static int, T: BigUint](input: ptr T, output: ptr array[N, uint8]): void {.autoSizeOpt.} =
  static:
    doAssert N == sizeof(T), "The total size of input and output must be same."

  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input[] shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when BE:
      copyMem(output, input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input[] shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)

# toBytesBE : big uint to uint8 array by big endian
# ptr UncheckedArray version
template toBytesBE*[T: BigUint](input: ptr T, output: ptr UncheckedArray[uint8]): void {.autoSizeOpt.} =
  when defined(nostd):
    unroll(b, 0, sizeof(T) - 1):
      output[b] = uint8((input[] shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)
  else:
    const size: int = sizeof(T)
    when BE:
      copyMem(output, input, size)
    else:
      unroll(b, 0, sizeof(T) - 1):
        output[b] = uint8((input[] shr ((sizeof(T) - 1 - b) * 8)) and 0xFF)

# left rotate
template leftRotate*[T: SomeInteger](value: T, shift: T): T {.autoSizeOpt.} =
  when defined(nostd):
    ((value shl shift.int) or (value shr (int(sizeof(T)) * 8) - shift.int))
  else:
    rotateLeftBits(value, shift)

# right rotate
template rightRotate*[T: SomeInteger](value: T, shift: T): T {.autoSizeOpt.} =
  when defined(nostd):
    ((value shr shift.int) or (value shl (int(sizeof(T)) * 8) - shift.int))
  else:
    rotateRightBits(value, shift)

# bit reverse for uint8
template reverseBit8(n: uint8): uint8 {.autoSizeOpt.} =
  var x = n
  x = (x shr 4) or (x shl 4)
  x = ((x shr 2) and 0x33'u8) or ((x shl 2) and 0xCC'u8)
  x = ((x shr 1) and 0x55'u8) or ((x shl 1) and 0xAA'u8)
  x

# bit reverse for uint16
template reverseBit16(n: uint16): uint16 {.autoSizeOpt.} =
  var x = n
  x = (x shr 8) or (x shl 8)
  x = ((x shr 4) and 0x0F0F'u16) or ((x shl 4) and 0xF0F0'u16)
  x = ((x shr 2) and 0x3333'u16) or ((x shl 2) and 0xCCCC'u16)
  x = ((x shr 1) and 0x5555'u16) or ((x shl 1) and 0xAAAA'u16)
  x

# bit reverse for uint32
template reverseBit32(n: uint32): uint32 {.autoSizeOpt.} =
  var x = n
  x = (x shr 16) or (x shl 16)
  x = ((x shr 8) and 0x00FF00FF'u32) or ((x shl 8) and 0xFF00FF00'u32)
  x = ((x shr 4) and 0x0F0F0F0F'u32) or ((x shl 4) and 0xF0F0F0F0'u32)
  x = ((x shr 2) and 0x33333333'u32) or ((x shl 2) and 0xCCCCCCCC'u32)
  x = ((x shr 1) and 0x55555555'u32) or ((x shl 1) and 0xAAAAAAAA'u32)
  x

# bit reverse for uint64
template reverseBit64(n: uint64): uint64 {.autoSizeOpt.} =
  var x = n
  x = (x shr 32) or (x shl 32)
  x = ((x shr 16) and 0x0000FFFF0000FFFF'u64) or ((x shl 16) and 0xFFFF0000FFFF0000'u64)
  x = ((x shr 8) and 0x00FF00FF00FF00FF'u64) or ((x shl 8) and 0xFF00FF00FF00FF00'u64)
  x = ((x shr 4) and 0x0F0F0F0F0F0F0F0F'u64) or ((x shl 4) and 0xF0F0F0F0F0F0F0F0'u64)
  x = ((x shr 2) and 0x3333333333333333'u64) or ((x shl 2) and 0xCCCCCCCCCCCCCCCC'u64)
  x = ((x shr 1) and 0x5555555555555555'u64) or ((x shl 1) and 0xAAAAAAAAAAAAAAA'u64)
  x

# bit reverse for generic
template reverseBit*[T: SomeUnsignedInt](n: T): T {.autoSizeOpt.} = 
  when T is uint64:
    reverseBit64(n)
  elif T is uint32:
    reverseBit32(n)
  elif T is uint16:
    reverseBit16(n)
  elif T is uint8:
    reverseBit8(n)

# nand generic operator
template `nand`*[T: SomeInteger](a, b: T): T =
  not (a and b)

# nor generic operator
template `nor`*[T: SomeInteger](a, b: T): T =
  not (a or b)

# and sign operator
template `&`*[T: SomeInteger](a, b: T): T =
  a and b

# or sign operator
template `|`*[T: SomeInteger](a, b: T): T =
  a or b

# xor sign operator
template `^`*[T: SomeInteger](a, b: T): T =
  a xor b

# not sign operator
template `~`*[T: SomeInteger](a: T): T =
  not a

# and assign sign operator
template `&=`*[T: SomeInteger](a: var T, b: T): void =
  a = a and b

# or assign sign operator
template `|=`*[T: SomeInteger](a: var T, b: T): void =
  a = a or b

# xor assign sign operator
template `^=`*[T: SomeInteger](a: var T, b: T): void =
  a = a xor b

# not assign sign operator
template `~=`*[T: SomeInteger](a: var T): void =
  a = not a
