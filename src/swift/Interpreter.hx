package swift;

import swift.Ast;

class Interpreter {
	public var globals:Environment = new Environment();
	var environment:Environment;

	public function new() {
		environment = globals;
		registerBuiltins();
	}

	function registerBuiltins() {
		globals.define("print", new NativeFunction(function(args:Array<Dynamic>):Dynamic {
			Sys.println(args.map(Std.string).join(" "));
			return null;
		}));
	}

	public function registerNative(name:String, fn:Array<Dynamic> -> Dynamic) {
		globals.define(name, new NativeFunction(fn));
	}

	public function run(statements:Array<Stmt>) {
		hoistFunctions(statements, globals);
		for (stmt in statements) {
			execute(stmt);
		}
	}

	function hoistFunctions(statements:Array<Stmt>, env:Environment) {
		for (stmt in statements) {
			switch (stmt) {
				case FuncDecl(name, params, body):
					env.define(name, new SSFunction(params, body, env));
				default:
			}
		}
	}

	public function callIfDefined(name:String, args:Array<Dynamic> = null):Dynamic {
		if (!globals.existsInChain(name)) return null;
		var fn = globals.get(name);
		if (Std.isOfType(fn, SSFunction) || Std.isOfType(fn, NativeFunction)) {
			var callable:Callable = cast fn;
			return callable.call(this, args == null ? [] : args);
		}
		return null;
	}

	function execute(stmt:Stmt) {
		switch (stmt) {
			case VarDecl(name, isConst, initializer):
				var value = initializer != null ? evaluate(initializer) : null;
				environment.define(name, value, isConst);

			case FuncDecl(name, params, body):
				var fn = new SSFunction(params, body, environment);
				environment.define(name, fn);

			case ExprStmt(expr):
				evaluate(expr);

			case If(cond, thenBranch, elseBranch):
				if (isTruthy(evaluate(cond))) {
					executeBlock(thenBranch, new Environment(environment));
				} else if (elseBranch != null) {
					executeBlock(elseBranch, new Environment(environment));
				}

			case While(cond, body):
				while (isTruthy(evaluate(cond))) {
					executeBlock(body, new Environment(environment));
				}

			case ForIn(varName, iterableExpr, body):
				var iterable:Dynamic = evaluate(iterableExpr);
				if (Std.isOfType(iterable, Array)) {
					var arr:Array<Dynamic> = cast iterable;
					for (item in arr) {
						var loopEnv = new Environment(environment);
						loopEnv.define(varName, item);
						executeBlock(body, loopEnv);
					}
				} else {
					trace('for-in target is not an array');
				}

			case Return(value):
				var v = value != null ? evaluate(value) : null;
				throw new ReturnSignal(v);
		}
	}

	public function executeBlock(statements:Array<Stmt>, blockEnv:Environment) {
		var previous = environment;
		environment = blockEnv;
		try {
			hoistFunctions(statements, blockEnv);
			for (stmt in statements) execute(stmt);
			environment = previous;
		} catch (e:Dynamic) {
			environment = previous;
			throw e;
		}
	}

	function evaluate(expr:Expr):Dynamic {
		return switch (expr) {
			case Literal(value): value;
			case NilLiteral: null;
			case Variable(name): environment.get(name);

			case Assign(name, valueExpr):
				var value = evaluate(valueExpr);
				environment.assign(name, value);
				value;

			case Binary(left, op, right):
				evalBinary(evaluate(left), op, evaluate(right));

			case Logical(left, op, right):
				var leftVal = evaluate(left);
				switch (op) {
					case PipePipe:
						if (isTruthy(leftVal)) leftVal else evaluate(right);
					case AmpAmp:
						if (!isTruthy(leftVal)) leftVal else evaluate(right);
					default:
						trace('Unsupported logical operator: $op');
						null;
				}

			case Unary(op, exprInner):
				var v = evaluate(exprInner);
				switch (op) {
					case Minus: -(v : Float);
					case Bang: !isTruthy(v);
					default: null;
				}

			case Closure(params, body):
				new SSFunction(params, body, environment);

			case Call(calleeExpr, argExprs, trailingClosure):
				var callee = evaluate(calleeExpr);
				var args = [for (a in argExprs) evaluate(a)];
				if (trailingClosure != null) {
					args.push(evaluate(trailingClosure));
				}
				if (Std.isOfType(callee, SSFunction) || Std.isOfType(callee, NativeFunction)) {
					var callable:Callable = cast callee;
					callable.call(this, args);
				} else {
					trace('Attempted to call a non-function value');
					null;
				}
		}
	}

	function evalBinary(left:Dynamic, op:TokenType, right:Dynamic):Dynamic {
		return switch (op) {
			case Plus:
				if (Std.isOfType(left, String) || Std.isOfType(right, String)) {
					Std.string(left) + Std.string(right);
				} else {
					(left : Float) + (right : Float);
				}
			case Minus: (left : Float) - (right : Float);
			case Star: (left : Float) * (right : Float);
			case Slash: (left : Float) / (right : Float);
			case EqEq: left == right;
			case NotEq: left != right;
			case Lt: (left : Float) < (right : Float);
			case Gt: (left : Float) > (right : Float);
			case LtEq: (left : Float) <= (right : Float);
			case GtEq: (left : Float) >= (right : Float);
			default:
				trace('Unsupported binary operator: $op');
				null;
		}
	}

	function isTruthy(value:Dynamic):Bool {
		if (value == null) return false;
		if (Std.isOfType(value, Bool)) return value;
		return true;
	}
}
