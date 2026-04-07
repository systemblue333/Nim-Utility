import std/macros
import security
from std/typetraits import supportsCopyMem


func mapLitsImpl(constructor: NimNode; op: NimNode; nested: bool;
                 filter = nnkLiterals): NimNode =
  if constructor.kind in filter:
    result = newNimNode(nnkCall, lineInfoFrom = constructor)
    result.add op
    result.add constructor
  else:
    result = copyNimNode(constructor)
    for v in constructor:
      if nested or v.kind in filter:
        result.add mapLitsImpl(v, op, nested, filter)
      else:
        result.add v

macro mapLiterals*(constructor, op: untyped;
                   nested = true): untyped =
  ## Applies `op` to each of the **atomic** literals like `3`
  ## or `"abc"` in the specified `constructor` AST. This can
  ## be used to map every array element to some target type:
  runnableExamples:
    let x = mapLiterals([0.1, 1.2, 2.3, 3.4], int)
    doAssert x is array[4, int]
    doAssert x == [int(0.1), int(1.2), int(2.3), int(3.4)]
  ## If `nested` is true (which is the default), the literals are replaced
  ## everywhere in the `constructor` AST, otherwise only the first level
  ## is considered:
  runnableExamples:
    let a = mapLiterals((1.2, (2.3, 3.4), 4.8), int)
    let b = mapLiterals((1.2, (2.3, 3.4), 4.8), int, nested=false)
    assert a == (1, (2, 3), 4)
    assert b == (1, (2.3, 3.4), 4)

    let c = mapLiterals((1, (2, 3), 4, (5, 6)), `$`)
    let d = mapLiterals((1, (2, 3), 4, (5, 6)), `$`, nested=false)
    assert c == ("1", ("2", "3"), "4", ("5", "6"))
    assert d == ("1", (2, 3), "4", (5, 6))
  ## There are no constraints for the `constructor` AST, it
  ## works for nested tuples of arrays of sets etc.
  result = mapLitsImpl(constructor, op, nested.boolVal)

macro evalOnceAs*(expAlias: untyped, exp: untyped,
                  letAssigneable: static[bool]): untyped =
  ## `expAlias`를 호출자 스코프에 주입하여, 매크로 인자의 중복 평가로 인한
  ## 버그를 방지합니다. `SecureSeq`, `SecureString` 등을 다루는 템플릿 내에서
  ## 인자를 안전하게 한 번만 평가할 때 사용됩니다.
  ##
  ## `evalOnceAs(myAlias, myExp)`는 `letAssigneable`이 true일 때
  ## `let myAlias = myExp`처럼 동작하며, false일 때는 인자를 그대로 전달합니다.

  expectKind(expAlias, nnkIdent)
  var val = exp

  result = newStmtList()

  # 인자가 단순 심볼이 아니고 'let' 할당이 가능한 경우,
  # genSym을 통해 임시 변수를 생성하여 값을 단 한 번만 평가합니다.
  if exp.kind != nnkSym and letAssigneable:
    val = genSym(nskLet, "evalOnce")
    result.add(newLetStmt(val, exp))

  # 변환된 값(또는 원본)을 반환하는 내부 템플릿을 생성하여 주입합니다.
  result.add(
    newProc(
      name = genSym(nskTemplate, $expAlias),
      params = [newIdentNode("untyped")], # getType(untyped) 대신 명시적 생성
      body = val,
      procType = nnkTemplateDef
    )
  )


macro mapSecureLiterals*(constructor, op: untyped; nested = true): untyped =
  result = mapLitsImpl(constructor, op, nested.boolVal)

# --- Helper Templates ---

template unCheckedInc(x) =
  {.push overflowChecks: off.}
  inc(x)
  {.pop.}

func addUnique*[T](s: var SecureSeq[T], x: sink T) =
  ## 이미 존재하지 않는 경우에만 x를 s에 추가합니다.
  ## SecureSeq의 내부 요소를 순회하며 == 연산자로 체크합니다.
  for i in 0 ..< s.len:
    if s[i] == x: return

  # SecureSeq에 구현된 add를 호출합니다.
  # (이미 이전에 add를 포팅했다면 해당 로직이 사용됩니다)
  s.add x

func count*[T](s: SecureSeq[T] | SecureString | SecureArray, x: T): int =
  ## 컨테이너 s 내에 x가 나타나는 횟수를 반환합니다.
  result = 0
  for itm in items(s):
    if itm == x:
      unCheckedInc result

func cycle*[T](s: SecureSeq[T] | SecureString | SecureArray, n: Natural): SecureSeq[T] =
  ## s의 아이템들을 n번 반복하여 새로운 SecureSeq를 생성합니다.
  let newLen = n * s.len
  result = newSecureSeq[T](newLen)
  result.length = newLen # 데이터가 채워질 것이므로 길이 설정

  var o = 0
  for x in 0 ..< n:
    for e in s:
      result[o] = e
      unCheckedInc o

proc repeat*[T](x: T, n: Natural): SecureSeq[T] =
  ## 아이템 x를 n번 반복하는 새로운 SecureSeq를 생성합니다.
  result = newSecureSeq[T](n)
  result.length = n
  for i in 0 ..< n:
    result[i] = x

# --- Ported Functions ---

func concat*[T](seqs: varargs[SecureSeq[T]]): SecureSeq[T] =
  var L = 0
  for seqitm in items(seqs): inc(L, len(seqitm))
  result = newSecureSeq[T](L)
  var i = 0
  for s in items(seqs):
    for itm in items(s):
      result[i] = itm
      unCheckedInc(i)

proc deduplicate*[T](s: SecureSeq[T], isSorted: bool = false): SecureSeq[T] =
  result = newSecureSeq[T](0)
  if s.len > 0:
    if isSorted:
      var prev = s[0]
      result.add(prev)
      for i in 1..s.high:
        if s[i] != prev:
          prev = s[i]
          result.add(prev)
    else:
      for itm in items(s):
        # contains operation needed for SecureSeq
        var found = false
        for r in items(result):
          if r == itm:
            found = true
            break
        if not found: result.add(itm)

proc min*[T](x: SecureSeq[T], cmp: proc(a, b: T): int): T {.effectsOf: cmp.} =
  result = x[0]
  for i in 1..high(x):
    if cmp(x[i], result) < 0: result = x[i]

proc max*[T](x: SecureSeq[T], cmp: proc(a, b: T): int): T {.effectsOf: cmp.} =
  result = x[0]
  for i in 1..high(x):
    if cmp(result, x[i]) < 0: result = x[i]

func minIndex*[T](s: SecureSeq[T]): int =
  result = 0
  for i in 1..high(s):
    if s[i] < s[result]: result = i

func minIndex*[T](s: SecureSeq[T], cmp: proc(a, b: T): int): int {.effectsOf: cmp.} =
  result = 0
  for i in 1..high(s):
    if cmp(s[i], s[result]) < 0: result = i

func maxIndex*[T](s: SecureSeq[T]): int =
  result = 0
  for i in 1..high(s):
    if s[i] > s[result]: result = i

func maxIndex*[T](s: SecureSeq[T], cmp: proc(a, b: T): int): int {.effectsOf: cmp.} =
  result = 0
  for i in 1..high(s):
    if cmp(s[result], s[i]) < 0: result = i

func minmax*[T](x: SecureSeq[T]): (T, T) =
  var l = x[0]
  var h = x[0]
  for i in 1..high(x):
    if x[i] < l: l = x[i]
    elif h < x[i]: h = x[i]
  result = (l, h)

func minmax*[T](x: SecureSeq[T], cmp: proc(a, b: T): int): (T, T) {.effectsOf: cmp.} =
  result = (x[0], x[0])
  for i in 1..high(x):
    if cmp(x[i], result[0]) < 0: result[0] = x[i]
    elif cmp(result[1], x[i]) < 0: result[1] = x[i]

template findIt*(s: SecureSeq | SecureString | SecureArray, predicate: untyped): int =
  var
    res = -1
    i = 0
  for it {.inject.} in items(s):
    if predicate:
      res = i
      break
    unCheckedInc(i)
  res

proc zip*[S, T](s1: SecureSeq[S], s2: SecureSeq[T]): SecureSeq[(S, T)] =
  var m = min(s1.len, s2.len)
  result = newSecureSeq[(S, T)](m)
  for i in 0 ..< m:
    result[i] = (s1[i], s2[i])

proc unzip*[S, T](s: SecureSeq[(S, T)]): (SecureSeq[S], SecureSeq[T]) =
  result = (newSecureSeq[S](s.len), newSecureSeq[T](s.len))
  for i in 0..<s.len:
    result[0][i] = s[i][0]
    result[1][i] = s[i][1]
    result[0].length = s.len # Explicitly set length as indexing doesn't inc length
    result[1].length = s.lens

# --- Missing Operators / Needed Overloads ---
# 1. `==` operator for SecureSeq[T]: deduplicate의 non-sorted 로직에서 result.contains(itm)을 대체하기 위해 필요합니다.
# 2. `<` and `>` operators for SecureSeq[T] elements: minIndex, maxIndex 등에서 요소 간 비교를 위해 필요합니다.
# 3. `items` iterator for varargs[SecureSeq[T]]: concat 함수에서 가변 인자를 처리하기 위해 필요합니다.

func distribute*[T](s: SecureSeq[T], num: Positive, spread = true): SecureSeq[SecureSeq[T]] =
  if num < 2:
    result = newSecureSeq[SecureSeq[T]](1)
    result.add(s)
    return

  result = newSecureSeq[SecureSeq[T]](num)
  result.length = num # 할당된 공간만큼 길이 설정

  var
    stride = s.len div num
    first = 0
    last = 0
    extra = s.len mod num

  if extra == 0 or spread == false:
    if extra > 0: unCheckedInc(stride)
    for i in 0 ..< num:
      result[i] = newSecureSeq[T](0)
      for g in first ..< min(s.len, first + stride):
        result[i].add(s[g])
      first += stride
  else:
    for i in 0 ..< num:
      last = first + stride
      if extra > 0:
        extra -= 1
        unCheckedInc(last)
      result[i] = newSecureSeq[T](0)
      for g in first ..< last:
        result[i].add(s[g])
      first = last

proc map*[T, S](s: SecureSeq[T] | SecureArray, op: proc (x: T): S {.closure.}): SecureSeq[S] {.inline, effectsOf: op.} =
  result = newSecureSeq[S](s.len)
  result.length = s.len
  for i in 0 ..< s.len:
    result[i] = op(s[i])

proc apply*[T](s: var (SecureSeq[T] | SecureArray), op: proc (x: var T) {.closure.}) {.inline, effectsOf: op.} =
  for i in 0 ..< s.len: op(s[i])

proc apply*[T](s: var (SecureSeq[T] | SecureArray), op: proc (x: T): T {.closure.}) {.inline, effectsOf: op.} =
  for i in 0 ..< s.len: s[i] = op(s[i])

proc apply*[T](s: SecureSeq[T] | SecureArray, op: proc (x: T) {.closure.}) {.inline, effectsOf: op.} =
  for i in 0 ..< s.len: op(s[i])

iterator filter*[T](s: SecureSeq[T] | SecureArray, pred: proc(x: T): bool {.closure.}): T {.effectsOf: pred.} =
  for i in 0 ..< s.len:
    if pred(s[i]):
      yield s[i]

proc filter*[T](s: SecureSeq[T] | SecureArray, pred: proc(x: T): bool {.closure.}): SecureSeq[T] {.inline, effectsOf: pred.} =
  result = newSecureSeq[T](0)
  for i in 0 ..< s.len:
    if pred(s[i]):
      result.add(s[i])

proc keepIf*[T](s: var SecureSeq[T], pred: proc(x: T): bool {.closure.}) {.inline, effectsOf: pred.} =
  var pos = 0
  for i in 0 ..< len(s):
    if pred(s[i]):
      if pos != i:
        # SecureSeq는 수동 메모리 관리를 하므로 직접 대입 사용
        s[pos] = s[i]
      unCheckedInc(pos)
  # setLen 대신 내부 length 필드 수정
  s.length = pos

func delete*[T](s: var SecureSeq[T]; slice: Slice[int]) =
  if not (slice.a < s.len and slice.a >= 0 and slice.b < s.len):
    # IndexDefect raising logic (as per stdlib)
    raise newException(IndexDefect, "Out of bounds")

  if slice.b >= slice.a:
    var i = slice.a
    var j = slice.b + 1
    var newLen = s.len - j + i
    while i < newLen:
      s[i] = s[j]
      unCheckedInc(i)
      unCheckedInc(j)
    s.length = newLen

func delete*[T](s: var SecureSeq[T]; first, last: Natural) =
  # deprecated logic preserved
  if first > last: return
  if first >= s.len: return

  var i = first
  var j = min(len(s), last + 1)
  var newLen = len(s) - j + i
  while i < newLen:
    s[i] = s[j]
    unCheckedInc(i)
    unCheckedInc(j)
  s.length = newLen

proc filter*(s: SecureString, pred: proc(x: char): bool {.closure.}): SecureString =
  result = newSecureString(0)
  for i in 0 ..< s.len:
    if pred(s[i]):
      result.add(s[i])

# --- Missing Operators / Requirements ---
# 1. `IndexDefect`: 에러 처리를 위해 std/assertions 혹은 system의 IndexDefect가 필요합니다.
# 2. `SecureSeq` 내의 `length` 필드 접근: `keepIf`와 `delete`에서 직접 수정을 위해 필드가 exported(*) 되어 있어야 합니다.
# 3. `SecureArray`에 대한 `var` 파라미터: SecureArray는 고정 크기이므로 `delete`나 `keepIf`는 적

# --- Ported Functions & Templates ---

proc insert*[T](dest: var SecureSeq[T], src: SecureSeq[T] | openArray[T], pos = 0) =
  ## src의 아이템들을 dest의 pos 위치에 삽입합니다.
  var j = len(dest) - 1
  var i = j + len(src)
  if i == j: return

  # SecureSeq의 용량이 부족할 경우를 대비해 처리
  let totalNeeded = i + 1
  if totalNeeded > dest.capacity:
    # 내부적으로 용량을 늘리는 로직 (secureResize 활용 혹은 직접 구현)
    # 여기서는 기존에 정의된 add의 로직을 참고하여 확장되었다고 가정합니다.
    dest.secureResize(totalNeeded)

  dest.length = totalNeeded

  # pos 이후의 아이템들을 뒤로 밀기
  while j >= pos:
    dest[i] = dest[j]
    dec(i)
    dec(j)

  # src의 아이템들을 pos 위치에 삽입
  unCheckedInc(j)
  for item in src:
    dest[j] = item
    unCheckedInc(j)

template filterIt*(s: SecureSeq | SecureString | SecureArray, pred: untyped): untyped =
  ## predicate를 만족하는 항목들로 구성된 새로운 SecureSeq를 반환합니다.
  # 타입 추론을 위해 s[0] 사용
  var res = newSecureSeq[typeof(s[0])](0)
  for it {.inject.} in items(s):
    if pred: res.add(it)
  res

template keepItIf*(varSeq: var SecureSeq, pred: untyped) =
  ## predicate를 만족하는 항목만 남깁니다.
  var pos = 0
  for i in 0 ..< len(varSeq):
    let it {.inject.} = varSeq[i]
    if pred:
      if pos != i:
        varSeq[pos] = varSeq[i]
      unCheckedInc(pos)
  varSeq.length = pos

template countIt*(s: SecureSeq | SecureString | SecureArray, pred: untyped): int =
  ## predicate를 만족하는 항목의 개수를 반환합니다.
  var res = 0
  for it {.inject.} in s:
    if pred: res += 1
  res

proc all*[T](s: SecureSeq[T] | SecureArray, pred: proc(x: T): bool {.closure.}): bool {.effectsOf: pred.} =
  ## 모든 항목이 predicate를 만족하는지 확인합니다.
  for i in items(s):
    if not pred(i):
      return false
  true

template allIt*(s: SecureSeq | SecureString | SecureArray, pred: untyped): bool =
  ## 모든 항목이 predicate를 만족하는지 확인합니다 (it 변수 사용).
  var res = true
  for it {.inject.} in items(s):
    if not pred:
      res = false
      break
  res

proc any*[T](s: SecureSeq[T] | SecureArray, pred: proc(x: T): bool {.closure.}): bool {.effectsOf: pred.} =
  ## 최소 하나 이상의 항목이 predicate를 만족하는지 확인합니다.
  for i in items(s):
    if pred(i):
      return true
  false

template anyIt*(s: SecureSeq | SecureString | SecureArray, pred: untyped): bool =
  ## 최소 하나 이상의 항목이 predicate를 만족하는지 확인합니다 (it 변수 사용).
  findIt(s, pred) != -1

# --- SecureString Specialized Templates ---

template filterIt*(s: SecureString, pred: untyped): SecureString =
  ## SecureString 전용 filterIt (결과값이 SecureString)
  var res = newSecureString(0)
  for it {.inject.} in items(s):
    if pred: res.add(it)
  res

# --- Missing Operators / Requirements ---
# 1. `secureResize`: insert 함수에서 용량이 부족할 때 메모리를 재할당하고 기존 데이터를 안전하게 옮기는 로직이 필요합니다.
# 2. `typeof(s[0])`: template 내에서 요소의 타입을 추출하기 위해 사용됩니다.
# 3. `findIt`: anyIt 템플릿은 앞서 구현된 findIt 템플릿에 의존합니다.

# --- Helper for Secure Types ---

template toSecureSeq1(s: not iterator): untyped =
  type OutType = typeof(items(s))
  when compiles(s.len):
    block:
      evalOnceAs(s2, s, compiles((let _ = s)))
      var i = 0
      var result = newSecureSeq[OutType](s2.len)
      result.length = s2.len # 할당량만큼 길이 설정
      for it in s2:
        result[i] = it
        i += 1
      result
  else:
    var result = newSecureSeq[OutType](0)
    for it in s:
      result.add(it)
    result

template toSecureSeq2(iter: iterator): untyped =
  evalOnceAs(iter2, iter(), false)
  when compiles(iter2.len):
    var i = 0
    var result = newSecureSeq[typeof(iter2)](iter2.len)
    result.length = iter2.len
    for x in iter2:
      result[i] = x
      unCheckedInc i
    result
  else:
    type OutType = typeof(iter2())
    var result = newSecureSeq[OutType](0)
    when compiles(iter2()):
      evalOnceAs(iter4, iter, false)
      let iter3 = iter4()
      for x in iter3():
        result.add(x)
    else:
      for x in iter2():
        result.add(x)
    result

template toSecureSeq*(iter: untyped): untyped =
  ## 모든 iterable을 SecureSeq로 변환합니다.
  when compiles(toSecureSeq1(iter)):
    toSecureSeq1(iter)
  elif compiles(toSecureSeq2(iter)):
    toSecureSeq2(iter)
  else:
    when compiles(iter.len):
      block:
        evalOnceAs(iter2, iter, true)
        var result = newSecureSeq[typeof(iter)](iter2.len)
        result.length = iter2.len
        var i = 0
        for x in iter2:
          result[i] = x
          unCheckedInc i
        result
    else:
      var result = newSecureSeq[typeof(iter)](0)
      for x in iter:
        result.add(x)
      result

# --- Fold Operations ---

template foldl*(sequence: SecureSeq | SecureString | SecureArray, operation: untyped): untyped =
  let s = sequence
  assert s.len > 0, "Can't fold empty sequences"
  var result: typeof(s[0])
  result = s[0]
  for i in 1..<s.len:
    let
      a {.inject.} = result
      b {.inject.} = s[i]
    result = operation
  result

template foldl*(sequence: SecureSeq | SecureString | SecureArray, operation, first): untyped =
  var result: typeof(first) = first
  for x in items(sequence):
    let
      a {.inject.} = result
      b {.inject.} = x
    result = operation
  result

template foldr*(sequence: SecureSeq | SecureString | SecureArray, operation: untyped): untyped =
  let s = sequence
  let n = s.len
  assert n > 0, "Can't fold empty sequences"
  var result = s[n - 1]
  for i in countdown(n - 2, 0):
    let
      a {.inject.} = s[i]
      b {.inject.} = result
    result = operation
  result

# --- Map & Apply It ---

template mapIt*(s: SecureSeq | SecureString | SecureArray, op: untyped): untyped =
  type OutType = typeof((
    block:
      var it{.inject.}: typeof(items(s));
      op))

  when OutType is not (proc):
    when compiles(s.len):
      block:
        evalOnceAs(s2, s, compiles((let _ = s)))
        var i = 0
        var result = newSecureSeq[OutType](s2.len)
        result.length = s2.len
        for it {.inject.} in s2:
          result[i] = op
          i += 1
        result
    else:
      var result = newSecureSeq[OutType](0)
      for it {.inject.} in items(s):
        result.add(op)
      result
  else:
    # fallback to map proc (Secure version)
    type InType = typeof(items(s))
    let f = proc (x: InType): OutType =
              let it {.inject.} = x
              op
    map(s, f)

template applyIt*(varSeq: var (SecureSeq | SecureArray), op: untyped) =
  for i in low(varSeq) .. high(varSeq):
    let it {.inject.} = varSeq[i]
    varSeq[i] = op

template newSecureSeqWith*(len: int, init: untyped): untyped =
  ## 초기화 식을 사용하여 새로운 SecureSeq를 생성합니다.
  type T = typeof(init)
  let newLen = len
  var result = newSecureSeq[T](newLen)
  result.length = newLen
  for i in 0 ..< newLen:
    result[i] = init
  result

# --- Literal Mapping (Macro) ---
# 이 매크로는 AST를 조작하므로 타입 시스템과 독립적으로 작동하지만,
# 최종 결과가 Secure타입으로 생성되도록 보장합니다.


# --- Missing Operators / Requirements ---
# 1. `newSecureSeq`: 위 템플릿들은 SecureSeq 생성을 위해 `newSecureSeq[T](size)`가 필요합니다.
# 2. `SecureSeq`의 `length` 필드: 템플릿 내부에서 `result.length`를 직접 수정하므로 접근 가능해야 합니다.
# 3. `evalOnceAs`: 제시해주신 원본 코드에 포함된 `evalOnceAs` 매크로가 스코프 내에 있어야 합니다.
