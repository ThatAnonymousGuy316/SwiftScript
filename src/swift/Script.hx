package swift;

import swift.Ast;

class Script {
	public var interpreter:Interpreter;
	var statements:Array<Stmt>;
	var hasRun:Bool = false;
	
	public static function fromFile(path:String):Script {
		return new Script(ScriptLoader.fromFile(path));
	}

	public static function fromAssets(path:String):Script {
		return new Script(ScriptLoader.fromAssets(path));
	}

	public static function fromSource(source:String):Script {
		return new Script(source);
	}

	function new(source:String) {
		interpreter = new Interpreter();
		if (source == "") {
			trace('Script source is empty - nothing to parse');
			statements = [];
			return;
		}
		var tokens = new Lexer(source).scanTokens();
		statements = new Parser(tokens).parse();
	}

	public function set(name:String, value:Dynamic):Void {
		interpreter.globals.define(name, value);
	}

	public function setFunction(name:String, fn:Array<Dynamic> -> Dynamic):Void {
		interpreter.registerNative(name, fn);
	}

	public function get(name:String):Dynamic {
		return interpreter.globals.get(name);
	}

	public function run():Void {
		if (hasRun) return;
		hasRun = true;
		interpreter.run(statements);
	}

	public function call(name:String, ?args:Array<Dynamic>):Dynamic {
		if (!hasRun) run();
		return interpreter.callIfDefined(name, args);
	}
}
