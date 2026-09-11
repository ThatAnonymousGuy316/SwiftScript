package swift;

enum Expr {
	Literal(value:Dynamic);
	NilLiteral;
	Variable(name:String);
	Assign(name:String, value:Expr);
	Binary(left:Expr, op:TokenType, right:Expr);
	Logical(left:Expr, op:TokenType, right:Expr);
	Unary(op:TokenType, expr:Expr);
	Call(callee:Expr, args:Array<Expr>, trailingClosure:Null<Expr>);
	Closure(params:Array<String>, body:Array<Stmt>);
}

enum Stmt {
	VarDecl(name:String, isConst:Bool, initializer:Null<Expr>);
	FuncDecl(name:String, params:Array<String>, body:Array<Stmt>);
	ExprStmt(expr:Expr);
	If(cond:Expr, thenBranch:Array<Stmt>, elseBranch:Null<Array<Stmt>>);
	While(cond:Expr, body:Array<Stmt>);
	ForIn(varName:String, iterable:Expr, body:Array<Stmt>);
	Return(value:Null<Expr>);
}
