---
title: CodeQL
author: ch3n9w
date: 2024-12-06T09:03:06+08:00
cagetories: 
  - 安全研究
draft: true
---

# CodeQL CTF

## Go and don't return

### 3.2

```
import go

class AuthTestConfig extends DataFlow::Configuration {

  AuthTestConfig() { this = "auth-test-config" }

  override predicate isSource(DataFlow::Node source) {
    source = any(DataFlow::CallNode cn |
      cn.getTarget().hasQualifiedName("github.com/minio/minio/cmd", "isReqAuthenticated") or
      cn.getTarget().hasQualifiedName("github.com/github/codeql-ctf-go-return", "errorSource")
    ).getResult()
  }

  override predicate isSink(DataFlow::Node sink) {
    sink = any(DataFlow::EqualityTestNode n).getAnOperand()
  }

}

EqualityTestExpr getAnAuthCheck() {
  // 如果存在comparison的运算单元是污点源, 那么将comparison作为expression返回
  exists(AuthTestConfig config, DataFlow::Node sink, DataFlow::EqualityTestNode comparison |
    config.hasFlow(_, sink) and comparison.getAnOperand() = sink |
    result = comparison.asExpr()
  )
}

ReturnStmt getAReturnStatementInBlock(BlockStmt b) {
  result = b.getAChild*()
}

predicate mustReachReturnInBlock(ControlFlow::Node node, BlockStmt b) {
  node.(IR::ReturnInstruction).getReturnStmt() = getAReturnStatementInBlock(b) or
  forex(ControlFlow::Node succ | succ = node.getASuccessor() | mustReachReturnInBlock(succ, b))
}

from IfStmt i, ControlFlow::ConditionGuardNode ifSucc
where
i.getCond() = getAnAuthCheck() and
i.getCond().(EqualityTestExpr).getAnOperand().(Ident).getName() = "ErrNone" and
ifSucc.ensures(DataFlow::exprNode(i.getCond()), true) and
not mustReachReturnInBlock(ifSucc, i.getThen())
select i
```

---

当变量调用谓词(predicate)的时候, 如果存在结果, 那么这种调用是一个表达式, 否则就是一个公式. 返回结果的谓词可以在经过逻辑判断后返回多个结果, 例如

```
string getANeighbor(string country) {
  country = "France" and result = "Belgium"
  or
  country = "France" and result = "Germany"
  or
  country = "Germany" and result = "Austria"
  or
  country = "Germany" and result = "Belgium"
}
```

对于上述predicate, 如果`country`为"Germany", 那么返回值为Austria和Belgium, 这点和平时用的编程语言区别挺大的.

同样的, `b.getAChild()`是一个带结果的谓词调用, 会返回多个子节点.

接下来是代表闭包传递的`*`和`+`, 这两个都有迭代的功能, 例如`ReturnStmt getAChild*()` 等价于

```
ReturnStmt getOneChild() {
  result = this
  or
  result = this.getAChild().getOneChild()
}
```

而`ReturnStmt getAChild+()` 等价于

```
ReturnStmt getOneChild() {
  result = this.getAChild()
  or
  result = this.getAChild().getOneChild()
}
```

也就是说`*`相比较`+`还包含了自身.

那么`getAReturnStatementInBlock`的结果就是当前节点加上当前节点经过递归后的所有子节点. 

那么子节点的集合要怎么和`node.(IR::ReturnInstruction).getReturnStmt()`进行比较? 根据[文档](https://codeql.github.com/docs/ql-language-reference/formulas/#equality-1)中所描述的:

> For expressions A and B, the formula A = B holds if there is a pair of values—one from A and one from B—that are the same. In other words, A and B have at least one value in common. For example, [1 .. 2] = [2 .. 5] holds, since both expressions have the value 2.

那么就不难理解了, 只要`node.(IR::ReturnInstruction).getReturnStmt()`的值和其中一个相同, `mustReachReturnInBlock`就会成立, 不然就进入`forex`部分.

`forex`的用法, 根据[文档](https://codeql.github.com/docs/ql-language-reference/formulas/#forex), 可以看作是`forall` 和 `exists` 的结合. 三者的定义如下

```
forall(<variable declarations> | <formula 1> | <formula 2>)
exists(<variable declarations> | <formula>)
forex(<variable declarations> | <formula 1> | <formula 2>) 等价于 forall(<vars> | <formula 1> | <formula 2>) and exists(<vars> | <formula 1> | <formula 2>)
```

- `forall`: 当每一个让formula1 成立的变量在formula2成立的时候, 公式成立
- `exists`: 当存在一个变量使得formula成立, 公式成立
- `forex`: 和`forall`类似, 但是排除了`不存在满足formula1的变量的情况`, 因为这种情况下`formula2`会无条件成立.

那么代码中`forex`的意思就是: **对于node的successor, 要求successor存在, 并且每一个successor满足mustReachReturnInBlock, 也就是说每一个successor都存在ReturnStmt**

---


在查阅文档的时候可以注意类的`supertypes`都有哪些, 包括`Direct supertypes` 和 `Indirect supertypes`. 所谓`Indirect supertypes`就是指, `supertype`在经历了多次继承之后才能变成该类, 而`direct supertypes` 是直接继承的. 这些`supertypes`都可以通过类型转换变成这个类.

statement没有返回值, 而expression是有返回值的.

值得注意的是`getAnAuthCheck`中的`exists`是没有返回部分的, 其定义为

```
exists(<variable declarations> | <formula 1> | <formula 2> |...| <formula n>)
```

等价于

```
exists(<variable declarations> | <formula 1> and <formula 2> and...and <formula n>)
```

如果至少存在一组variables使得全部formula都满足, 那么公式成立.

而题解中的这种写法, 相当于等前面所有的formula都满足的时候, 临时变量result会被赋值 `comparison.asExpr()` , 而result又是 `getAnAuthCheck` 的返回值, 因此就变成: 返回一组满足运算单元是污点源的 `EqualityTestExpr`.

