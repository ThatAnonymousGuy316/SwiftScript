package swift;

import swift.Ast;

interface Callable {
	function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic;
}

class NativeFunction implements Callable {
	var fn:Array<Dynamic> -> Dynamic;

	public function new(fn:Array<Dynamic> -> Dynamic) {
		this.fn = fn;
	}

	public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
		return fn(args);
	}
}

class SSFunction implements Callable {
	var params:Array<String>;
	var body:Array<Stmt>;
	var closureEnv:Environment;

	public function new(params:Array<String>, body:Array<Stmt>, closureEnv:Environment) {
		this.params = params;
		this.body = body;
		this.closureEnv = closureEnv;
	}

	public function call(interpreter:Interpreter, args:Array<Dynamic>):Dynamic {
		var callEnv = new Environment(closureEnv);
		for (i in 0...params.length) {
			var arg = i < args.length ? args[i] : null;
			callEnv.define(params[i], arg);
		}
		try {
			interpreter.executeBlock(body, callEnv);
		} catch (r:ReturnSignal) {
			return r.value;
		}
		return null;
	}
}

class ReturnSignal {
	public var value:Dynamic;
	public function new(value:Dynamic) {
		this.value = value;
	}
}
