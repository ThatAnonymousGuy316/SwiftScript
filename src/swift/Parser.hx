package swift;

import swift.Ast;
import swift.Lexer;

class Parser {
	var tokens:Array<Token>;
	var pos:Int = 0;

	public function new(tokens:Array<Token>) {
		this.tokens = tokens;
	}

	public function parse():Array<Stmt> {
		var stmts:Array<Stmt> = [];
		while (!isAtEnd()) {
			stmts.push(declaration());
		}
		return stmts;
	}

	function declaration():Stmt {
		if (check(Let)) return varDecl(true);
		if (check(Var)) return varDecl(false);
		if (check(Func)) return funcDecl();
		return statement();
	}

	function varDecl(isConst:Bool):Stmt {
		advance();
		var name = consume(Identifier, "Expected variable name").lexeme;
		var initializer:Null<Expr> = null;
		if (match(Equals)) {
			initializer = expression();
		}
		return VarDecl(name, isConst, initializer);
	}

	function funcDecl():Stmt {
		advance();
		var name = consume(Identifier, "Expected function name").lexeme;
		consume(LParen, "Expected '(' after function name");
		var params = paramList();
		consume(RParen, "Expected ')' after parameters");
		if (match(Arrow)) {
			consume(Identifier, "Expected return type after '->'");
		}
		consume(LBrace, "Expected '{' before function body");
		var body = block();
		return FuncDecl(name, params, body);
	}

	function paramList():Array<String> {
		var params:Array<String> = [];
		if (!check(RParen)) {
			do {
				var pname = consume(Identifier, "Expected parameter name").lexeme;
				if (match(Colon)) {
					consume(Identifier, "Expected type after ':'");
				}
				params.push(pname);
			} while (match(Comma));
		}
		return params;
	}

	function statement():Stmt {
		if (check(If)) return ifStmt();
		if (check(While)) return whileStmt();
		if (check(For)) return forStmt();
		if (check(Return)) return returnStmt();
		if (check(LBrace)) {
			advance();
			return ExprStmt(Literal(null));
		}
		return exprStmt();
	}

	function ifStmt():Stmt {
		advance();
		var cond = expression();
		consume(LBrace, "Expected '{' after if condition");
		var thenBranch = block();
		var elseBranch:Null<Array<Stmt>> = null;
		if (match(Else)) {
			consume(LBrace, "Expected '{' after else");
			elseBranch = block();
		}
		return If(cond, thenBranch, elseBranch);
	}

	function whileStmt():Stmt {
		advance();
		var cond = expression();
		consume(LBrace, "Expected '{' after while condition");
		var body = block();
		return While(cond, body);
	}

	function forStmt():Stmt {
		advance();
		var varName = consume(Identifier, "Expected loop variable name").lexeme;
		consume(In, "Expected 'in' after loop variable");
		var iterable = expression();
		consume(LBrace, "Expected '{' after for-in iterable");
		var body = block();
		return ForIn(varName, iterable, body);
	}

	function returnStmt():Stmt {
		advance();
		var value:Null<Expr> = null;
		if (!check(RBrace) && !isAtEnd()) {
			value = expression();
		}
		return Return(value);
	}

	function exprStmt():Stmt {
		var expr = expression();
		return ExprStmt(expr);
	}

	function block():Array<Stmt> {
		var stmts:Array<Stmt> = [];
		while (!check(RBrace) && !isAtEnd()) {
			stmts.push(declaration());
		}
		consume(RBrace, "Expected '}' after block");
		return stmts;
	}

	function expression():Expr return assignment();

	function assignment():Expr {
		var expr = equality();
		if (match(Equals)) {
			var value = assignment();
			switch (expr) {
				case Variable(name): return Assign(name, value);
				default: trace("Invalid assignment target");
			}
		}
		return expr;
	}

	function equality():Expr {
		var expr = comparison();
		while (check(EqEq) || check(NotEq)) {
			var op = advance().type;
			var right = comparison();
			expr = Binary(expr, op, right);
		}
		return expr;
	}

	function comparison():Expr {
		var expr = term();
		while (check(Lt) || check(Gt) || check(LtEq) || check(GtEq)) {
			var op = advance().type;
			var right = term();
			expr = Binary(expr, op, right);
		}
		return expr;
	}

	function term():Expr {
		var expr = factor();
		while (check(Plus) || check(Minus)) {
			var op = advance().type;
			var right = factor();
			expr = Binary(expr, op, right);
		}
		return expr;
	}

	function factor():Expr {
		var expr = unary();
		while (check(Star) || check(Slash)) {
			var op = advance().type;
			var right = unary();
			expr = Binary(expr, op, right);
		}
		return expr;
	}

	function unary():Expr {
		if (check(Minus)) {
			var op = advance().type;
			var right = unary();
			return Unary(op, right);
		}
		return callExpr();
	}

	function callExpr():Expr {
		var expr = primary();
		while (true) {
			if (check(LParen)) {
				advance();
				var args = argList();
				consume(RParen, "Expected ')' after arguments");
				var trailing:Null<Expr> = null;
				if (check(LBrace)) {
					trailing = closure();
				}
				expr = Call(expr, args, trailing);
			} else if (check(LBrace) && isCallable(expr)) {
				var trailing = closure();
				expr = Call(expr, [], trailing);
			} else {
				break;
			}
		}
		return expr;
	}

	function isCallable(e:Expr):Bool {
		return switch (e) {
			case Variable(_): true;
			default: false;
		}
	}

	function argList():Array<Expr> {
		var args:Array<Expr> = [];
		if (!check(RParen)) {
			do {
				args.push(expression());
			} while (match(Comma));
		}
		return args;
	}
	function closure():Expr {
		consume(LBrace, "Expected '{' to start closure");
		var params = tryParseClosureParams();
		var body = block();
		return Closure(params, body);
	}

	function tryParseClosureParams():Array<String> {
		var start = pos;
		var hasParens = check(LParen);
		if (hasParens) advance();

		var names:Array<String> = [];
		var ok = check(Identifier);
		if (ok) {
			while (check(Identifier)) {
				names.push(peek().lexeme);
				advance();
				if (check(Colon)) {
					advance();
					if (check(Identifier)) advance();
				}
				if (check(Comma)) {
					advance();
				} else {
					break;
				}
			}
		}
		if (hasParens) {
			if (check(RParen)) advance(); else ok = false;
		}
		if (ok && check(In)) {
			advance();
			return names;
		}
		pos = start;
		return [];
	}

	function primary():Expr {
		if (check(True)) { advance(); return Literal(true); }
		if (check(False)) { advance(); return Literal(false); }
		if (check(Nil)) { advance(); return NilLiteral; }
		if (check(IntLiteral)) { var t = advance(); return Literal(Std.parseInt(t.lexeme)); }
		if (check(FloatLiteral)) { var t = advance(); return Literal(Std.parseFloat(t.lexeme)); }
		if (check(StringLiteral)) { var t = advance(); return Literal(t.lexeme); }
		if (check(Identifier)) { var t = advance(); return Variable(t.lexeme); }
		if (check(LParen)) {
			advance();
			var expr = expression();
			consume(RParen, "Expected ')' after expression");
			return expr;
		}
		if (check(LBrace)) {
			return closure();
		}
		trace('Unexpected token: ${peek().type} at line ${peek().line}');
		advance();
		return NilLiteral;
	}

	function match(type:TokenType):Bool {
		if (!check(type)) return false;
		advance();
		return true;
	}

	function check(type:TokenType):Bool {
		if (isAtEnd()) return false;
		return peek().type == type;
	}

	function consume(type:TokenType, message:String):Token {
		if (check(type)) return advance();
		trace('Parse error: $message (got ${peek().type} at line ${peek().line})');
		return peek();
	}

	function advance():Token {
		if (!isAtEnd()) pos++;
		return previous();
	}

	function peek():Token return tokens[pos];
	function previous():Token return tokens[pos - 1];
	function isAtEnd():Bool return peek().type == EOF;
}
