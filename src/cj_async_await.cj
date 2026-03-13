macro package cj_async_await

import std.ast.*

class MacroException <: Exception {
    public init(message: String) {
        super("macro failed to expand.\n" + message)
    }
}

public macro async(input: Tokens): Tokens {
    let decl = parseDecl(input)
    match (decl) {
        case funcDecl: FuncDecl => return rewriteAsyncFunc(funcDecl)
        case mainDecl: MainDecl => return rewriteAsyncMain(mainDecl)
        case varDecl: VarDecl => return rewriteAsyncLet(varDecl)
        case _ => throw MacroException("@async must be placed on a function, main, or let binding")
    }
}

public macro await(input: Tokens): Tokens {
    let awaitableExpr = expectAwaitableExpr(parseExpr(input))
    return quote(
        $(awaitableExpr).get()
    )
}

private func rewriteAsyncFunc(funcDecl: FuncDecl): Tokens {
    let returnType = explicitReturnType(funcDecl)

    funcDecl.annotations = filteredAnnotations(funcDecl.annotations, "async")

    let spawnExpr = SpawnExpr(quote(
        spawn { =>
            $(funcDecl.block.nodes)
        }
    ))

    funcDecl.declType = parseType(quote(
        Future<$returnType>
    ))
    funcDecl.block.nodes = blockingReturnNodes(spawnExpr)
    return funcDecl.toTokens()
}

private func rewriteAsyncMain(mainDecl: MainDecl): Tokens {
    mainDecl.annotations = filteredAnnotations(mainDecl.annotations, "async")

    let spawnExpr = SpawnExpr(quote(
        spawn { =>
            $(mainDecl.block.nodes)
        }
    ))

    let blockingExpr = parseExpr(quote(
        $(spawnExpr).get()
    ))
    let newBlockNodes = ArrayList<Node>()
    newBlockNodes.add(ReturnExpr(quote(
        return $(blockingExpr)
    )))
    mainDecl.block.nodes = newBlockNodes
    return mainDecl.toTokens()
}

private func rewriteAsyncLet(varDecl: VarDecl): Tokens {
    expectAsyncLet(varDecl)

    let identifier = explicitBindingIdentifier(varDecl)
    let initializer = explicitInitializer(varDecl)
    let valueType = explicitValueType(varDecl)

    return quote(
        let $identifier: Future<$valueType> = $(initializer)
    )
}

private func explicitReturnType(funcDecl: FuncDecl): TypeNode {
    try {
        return funcDecl.declType
    } catch (_: ASTException) {
        throw MacroException("@async functions must declare an explicit return type")
    }
}

private func explicitInitializer(varDecl: VarDecl): Expr {
    try {
        return varDecl.expr
    } catch (_: ASTException) {
        throw MacroException("@async let bindings must have an initializer")
    }
}

private func explicitValueType(varDecl: VarDecl): TypeNode {
    try {
        return varDecl.declType
    } catch (_: ASTException) {
        throw MacroException("@async let bindings must declare an explicit value type")
    }
}

private func expectAsyncLet(varDecl: VarDecl): Unit {
    let varDeclTokens = varDecl.toTokens()
    if (varDeclTokens[0].value != "let") {
        throw MacroException("@async variable bindings only support let in v1")
    }

    try {
        varDecl.identifier
    } catch (_: ASTException) {
        throw MacroException("@async let only supports a single binding name in v1")
    }
}

private func explicitBindingIdentifier(varDecl: VarDecl): Token {
    try {
        return varDecl.identifier
    } catch (_: ASTException) {
        throw MacroException("@async let only supports a single binding name in v1")
    }
}

private func expectAwaitableExpr(expr: Expr): Expr {
    match (expr) {
        case _: CallExpr => return expr
        case _: RefExpr => return expr
        case _: MemberAccess => return expr
        case _: SubscriptExpr => return expr
        case _: SpawnExpr => return expr
        case parenExpr: ParenExpr => return expectAwaitableExpr(parenExpr.parenthesizedExpr)
        case _ => throw MacroException("@await only supports future-producing calls and bindings in v2")
    }
}

private func blockingReturnNodes(spawnExpr: SpawnExpr): ArrayList<Node> {
    let newBlockNodes = ArrayList<Node>()
    newBlockNodes.add(ReturnExpr(quote(
        return $(spawnExpr)
    )))
    return newBlockNodes
}

private func filteredAnnotations(annotations: ArrayList<Annotation>, identifier: String): ArrayList<Annotation> {
    let filtered = ArrayList<Annotation>()
    for (annotation in annotations) {
        if (annotation.identifier.value != identifier) {
            filtered.add(annotation)
        }
    }
    return filtered
}
