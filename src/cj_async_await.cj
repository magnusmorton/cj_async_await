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
        case _ => throw MacroException("@async must be placed on a function")
    }
}

public macro await(input: Tokens): Tokens {
    let callExpr = expectCallExpr(parseExpr(input))
    return quote(
        $(callExpr).get()
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

private func explicitReturnType(funcDecl: FuncDecl): TypeNode {
    try {
        return funcDecl.declType
    } catch (_: ASTException) {
        throw MacroException("@async functions must declare an explicit return type")
    }
}

private func expectCallExpr(expr: Expr): CallExpr {
    match (expr as CallExpr) {
        case Some(callExpr) => callExpr
        case None => throw MacroException("@await only supports function calls in v1")
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
