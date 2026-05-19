
import std/macros

proc replaceNodes(node: NimNode, target: string, replacement: NimNode): NimNode =
  if node.kind == nnkIdent and node.strVal == target:
    return replacement

  result = copyNimNode(node)
  for child in node:
    result.add(replaceNodes(child, target, replacement))

macro unroll*(i: untyped, startExp, stopExp: static int, stepOrBody: untyped, bodyExp: untyped = nil): untyped =
  var step = 1
  var body: NimNode

  if bodyExp == nil:
    body = stepOrBody
  else:
    step = stepOrBody.intVal.int
    body = bodyExp

  result = newStmtList()
  let targetName = i.strVal

  when defined(sizeOpt):
    if startExp <= stopExp:
      let rangeNode = if step == 1: newTree(nnkInfix, ident"..", newLit(startExp), newLit(stopExp))
                      else: newTree(nnkCall, ident"countup", newLit(startExp), newLit(stopExp), newLit(step))
      result.add(newTree(nnkForStmt, i, rangeNode, body))
    else:
      let rangeNode = newTree(nnkCall, ident"countdown", newLit(startExp), newLit(stopExp), newLit(step))
      result.add(newTree(nnkForStmt, i, rangeNode, body))
  else:
    if startExp <= stopExp:
      var val = startExp
      while val <= stopExp:
        result.add(replaceNodes(body, targetName, newLit(val)))
        val += step
    else:
      var val = startExp
      while val >= stopExp:
        result.add(replaceNodes(body, targetName, newLit(val)))
        val -= step

macro autoSizeOpt*(n: untyped): untyped =
  n.expectKind({nnkProcDef, nnkTemplateDef})

  let targetKind = when defined(sizeOpt): nnkProcDef else: nnkTemplateDef

  result = newTree(targetKind)
  for child in n:
    result.add(child)

  if targetKind == nnkProcDef and result[3].kind == nnkEmpty:
    result[3] = newTree(nnkFormalParams, ident"void")

  var pragmas = result[4]
  if pragmas.kind == nnkPragma:
    var newPragmas = newNimNode(nnkPragma)
    for p in pragmas:
      if p.kind == nnkIdent and p.strVal == "autoSizeOpt":
        continue
      newPragmas.add(p)
    result[4] = newPragmas

macro autoTemplateOpt*(n: untyped): untyped =
  n.expectKind({nnkProcDef, nnkTemplateDef})

  let targetKind = when defined(templateOpt): nnkTemplateDef else: nnkProcDef

  result = newTree(targetKind)
  for child in n:
    result.add(child)

  if targetKind == nnkProcDef and result[3].kind == nnkEmpty:
    result[3] = newTree(nnkFormalParams, ident"void")

  var pragmas = result[4]
  if pragmas.kind == nnkPragma:
    var newPragmas = newNimNode(nnkPragma)
    for p in pragmas:
      if p.kind == nnkIdent and p.strVal == "autoTemplateOpt":
        continue
      newPragmas.add(p)
    result[4] = newPragmas

macro optimise*(n: untyped): untyped =
  proc transform(node: NimNode): NimNode =
    if node.kind == nnkForStmt:
      let iter = node[1]
      if (iter.kind == nnkCall) and (iter[0].kind == nnkIdent) and (iter[0].strVal == "static"):
        when defined(sizeOpt):
          var newNode = copyNimNode(node)
          newNode.add(node[0]) 
          newNode.add(iter[1]) 
          newNode.add(transform(node[2])) 
          return newNode
        else:
          return node

    elif node.kind == nnkWhenStmt:
      when defined(sizeOpt):
        result = newTree(nnkIfStmt)
        for child in node:
          var branch = copyNimTree(child)
          if branch.kind in {nnkElifBranch, nnkElse, nnkElifExpr}:
            let lastIdx = branch.len - 1
            branch[lastIdx] = transform(branch[lastIdx])
          result.add(branch)
        return result
      else:
        discard

    result = copyNimNode(node)
    for child in node:
      result.add(transform(child))

  result = transform(n)
