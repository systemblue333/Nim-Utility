import std/bitops
import autoopt
import ../dataformat/dataformat
import envconst
import bits
import std/endians
import arraytype

# big uint generic type
type
  BigUint*[size: static int] = array[size div (sizeof(UINT) * 8), UINT]

# big uint types : uint128 ~ uint4096
type
  uint128* = BigUint[128]
  uint256* = BigUint[256]
  uint512* = BigUint[512]
  uint1024* = BigUint[1024]
  uint2048* = BigUint[2048]
  uint4096* = BigUint[4096]

# big uint xor generic operator
proc `xor`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  unroll(i, 0, (B div CPUBits) - 1):
    output[i] = a[i] xor b[i]
  output

# big uint and generic operator
proc `and`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  unroll(i, 0, (B div CPUBits) - 1):
    output[i] = a[i] and b[i]
  output

# big uint or generic operator
proc `or`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  unroll(i, 0, (B div CPUBits) - 1):
    output[i] = a[i] or b[i]
  output

# big uint not generic operator
proc `not`*[B: static int](a: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  unroll(i, 0, (B div CPUBits) - 1):
    output[i] = not a[i]
  output

# big uint shl generic operator
proc `shl`*[B: static int](input: BigUint[B], shift: range[0..B]): BigUint[B] {.autoTemplateOpt.} =
  # declare output
  var output: BigUint[B]

  # declare shift variables and initialise
  var wordShift: int = shift div CPUBits # UINT(word) shift value
  var bitShift: int = shift mod CPUBits # bit shift value
  var complementShift: int = CPUBits - bitShift

  # declare temporal variables and initialise to 0
  var isValid, isNotLast, mask, va, vn: UINT = 0
  
  # traget index loop
  unroll(targetIndex, 0, (B div CPUBits) - 1):
    # source index loop
    unroll(sourceIndex, 0, (B div CPUBits) - 1):
      block:
        # Straight shift: target = source + wordShift
        isValid = UINT(targetIndex == (sourceIndex + wordShift))
        mask = 0.UINT - isValid 
        
        # endian convert and store to output
        leToNative(input[sourceIndex], va)
        vn = va shl bitShift
        nativeToLE(vn, vn)
        output[targetIndex] = output[targetIndex] or (vn and mask)

        # Cross-word shift: target = source + wordShift + 1
        isNotLast = (UINT(sourceIndex < (B div CPUBits) - 1) and UINT(bitShift > 0)).UINT
        isValid = (UINT(targetIndex == (sourceIndex + wordShift + 1)) and isNotLast).UINT
        mask = 0.UINT - isValid
        
        # endian convert and store to output
        leToNative(input[sourceIndex], va)
        vn = va shr (complementShift and (CPUBits - 1))
        nativeToLE(vn, vn)
        output[targetIndex] = output[targetIndex] or (vn and mask)
  
  # return
  output

# big uint shr generic operator
proc `shr`*[B: static int](input: BigUint[B], shift: range[0..B]): BigUint[B] {.autoTemplateOpt.} =
  # declare output
  var output: BigUint[B]

  # declare shift variables and initialise
  var wordShift: int = shift div CPUBits # word shift value
  var bitShift: int = shift mod CPUBits # bit shift value
  var complementShift: int = CPUBits - bitShift

  # declare temporal variables and initialise to 0
  var isValid, isNotFirst, mask, va, vn: UINT = 0
  
  unroll(targetIndex, 0, (B div CPUBits) - 1):
    unroll(sourceIndex, 0, (B div CPUBits) - 1):
      block:
        # Straight shift: target = source - wordShift
        isValid = UINT(targetIndex == (sourceIndex - wordShift))
        mask = 0.UINT - isValid
        
        # endian convert and store to output
        leToNative(input[sourceIndex], va)
        vn = va shr bitShift
        nativeToLE(vn, vn)
        output[targetIndex] = output[targetIndex] or (vn and mask)
        
        # Cross-word shift: target = source - wordShift - 1
        isNotFirst = (UINT(sourceIndex > 0) and UINT(bitShift > 0)).UINT
        isValid = (UINT(targetIndex == (sourceIndex - wordShift - 1)) and isNotFirst).UINT
        mask = 0.UINT - isValid
        
        # endian convert and store to output
        leToNative(input[sourceIndex], va)
        vn = va shl (complementShift and (CPUBits - 1))
        nativeToLE(vn, vn)
        output[targetIndex] = output[targetIndex] or (vn and mask)
  
  # return
  output

# big uint rotateLeftBits generic function
proc rotateLeftBits*[B: static int](a: BigUint[B], shift: range[0..B]): BigUint[B] {.autoTemplateOpt.} =
  var s: int = shift mod B
  (a shl s) or (a shr (B - s))

# big uint rotateRightBits generic function
proc rotateRightBits*[B: static int](a: BigUint[B], shift: range[0..B]): BigUint[B] {.autoTemplateOpt.} =
  var s: int = shift mod B
  (a shr s) or (a shl (B - s))

# big uint add generic operator
proc `+`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  var carry: UINT = 0
  var va, vb, vsum: UINT = 0
  unroll(i, 0, (B div CPUBits) - 1):
    block:
      leToNative(a[i], va)
      leToNative(b[i], vb)
      vsum = va + vb + carry
      carry = (UINT(vsum < va) or (UINT(carry != 0.UINT) and UINT(vsum == va))).UINT
      nativeToLE(vsum, vsum)
      output[i] = vsum
  output

# big uint sub generic operator
proc `-`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  var borrow: UINT = 0
  var va, vb, vdiff: UINT = 0
  unroll(i, 0, (B div CPUBits) - 1):
    block:
      leToNative(a[i], va)
      leToNative(b[i], vb)
      vdiff = va - vb - borrow
      borrow = (UINT(va < vb) or (UINT(borrow != 0.UINT) and UINT(va == vb))).UINT
      nativeToLE(vdiff, vdiff)
      output[i] = vdiff
  output

# big uint mul generic operator
proc `*`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var output: BigUint[B]
  var va, vb, mHi, mLo, oldOut, sum, carry: UINT = 0
  const half = CPUBits div 2
  const mask_half = (1.UINT shl half) - 1.UINT
  var aLow, aHigh, bLow, bHigh, res0, res1, res2, res3, mid, sum1, carry1, carry2: UINT = 0
  const len = B div CPUBits
  
  unroll(i, 0, len - 1):
    block:
      carry = 0
      unroll(j, 0, len - 1):
        block:
          const target_idx = i + j
          
          when target_idx < len:
            leToNative(a[i], va)
            leToNative(b[j], vb)
            
            # Inline mulInternal logic
            aLow = va and mask_half
            aHigh = va shr half
            bLow = vb and mask_half
            bHigh = vb shr half
            res0 = aLow * bLow
            res1 = aLow * bHigh
            res2 = aHigh * bLow
            res3 = aHigh * bHigh
            mid = (res0 shr half) + (res1 and mask_half) + (res2 and mask_half)
            mLo = res0 + (res1 shl half) + (res2 shl half)
            mHi = res3 + (mid shr half) + (res1 shr half) + (res2 shr half)
            
            leToNative(output[target_idx], oldOut)
            
            sum1 = oldOut + mLo
            carry1 = UINT(sum1 < oldOut)
            sum = sum1 + carry
            carry2 = UINT(sum < sum1)
            
            carry = mHi + carry1 + carry2
            
            nativeToLE(sum, sum)
            output[target_idx] = sum
  output

# big uint divmod generic operator
# return value's real type is (BigUint[B], BigUint[B])
template `divmod`*[B: static int](a, b: BigUint[B]): untyped =
  var q: BigUint[B]
  var r: BigUint[B]
  var bit, vr, vb, borrow, isGe, mask, diff, va, vq: UINT = 0
  const len = B div CPUBits
  unroll(i, 0, B - 1):
    block:
      # bit extraction from MSB to LSB
      # bit index j = B - 1 - i
      const j_bit = B - 1 - i
      const wordIdx = j_bit div CPUBits
      const bitIdx = j_bit mod CPUBits
      
      leToNative(a[wordIdx], va)
      bit = (va shr bitIdx) and 1.UINT
      
      r = r shl 1
      leToNative(r[0], vr)
      vr = vr or bit
      nativeToLE(vr, vr)
      r[0] = vr
      
      borrow = 0.UINT
      unroll(j, 0, len - 1):
        block:
          leToNative(r[j], vr)
          leToNative(b[j], vb)
          borrow = (UINT(vr < vb) or (UINT(borrow != 0.UINT) and UINT(vr == vb))).UINT
      
      isGe = 1.UINT - borrow
      mask = 0.UINT - isGe
      
      borrow = 0.UINT
      unroll(j, 0, len - 1):
        block:
          leToNative(r[j], vr)
          leToNative(b[j], vb)
          diff = vr - (vb and mask) - borrow
          borrow = (UINT(vr < (vb and mask)) or (UINT(borrow != 0.UINT) and UINT(vr == (vb and mask)))).UINT
          nativeToLE(diff, diff)
          r[j] = diff
      
      leToNative(q[wordIdx], vq)
      vq = vq or (isGe shl bitIdx)
      nativeToLE(vq, vq)
      q[wordIdx] = vq

  (q, r)

# big uint div generic operator
proc `div`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var (q, r) = divmod(a, b)
  q

# big uint mod generic operator
proc `mod`*[B: static int](a, b: BigUint[B]): BigUint[B] {.autoTemplateOpt.} =
  var (q, r) = divmod(a, b)
  r

# big uint to string generic operator
proc `$`*[B: static int](a: BigUint[B]): string {.autoTemplateOpt.} =
  var output: string = ""
  var va: UINT = 0
  const len = B div CPUBits
  unroll(i, 0, len - 1):
    leToNative(a[len - 1 - i], va)
    output.add($(va))
  output

# toBigUint template 
# type :  array[N, T] -> BigUint[sizeof(T) * N * 8]
# endian : native -> LE
template toBigUint*[N: static int, T: SomeUnsignedInt](input: array[N, T]): untyped =
  var output: BigUint[sizeof(T) * N * 8]
  var pOutput: ptr array[N, T] = cast[ptr array[N, T]](addr output) 
  for i in static(0 ..< N):
    pOutput[i] = input[i]
    toLE(pOutput[i], pOutput[i])
  output

# toBigUint template 
# type :  slicearray[N, T] -> BigUint[sizeof(T) * N * 8]
# endian : native -> LE
template toBigUint*[N: static int, T: SomeUnsignedInt](input: slicearray[N, T]): untyped =
  var output: BigUint[sizeof(T) * N * 8]
  var pOutput: ptr array[N, T] = cast[ptr array[N, T]](addr output)
  for i in static(0 ..< N):
    pOutput[i] = input[i]
    toLE(pOutput[i], pOutput[i])
  output

# toBytes template
# type : BigUInt[B] -> array[B div 8, uint8]
# endian : no converted
template toBytes*[B: static int](a: BigUint[B]): untyped =
  cast[array[B div 8, uint8]](a)
