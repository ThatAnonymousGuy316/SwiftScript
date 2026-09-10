package swift;

class Environment {
	var values:Map<String, Dynamic> = new Map();
	var constants:Map<String, Bool> = new Map();
	public var enclosing:Null<Environment>;

	public function new(?enclosing:Environment) {
		this.enclosing = enclosing;
	}

	public function define(name:String, value:Dynamic, isConst:Bool = false) {
		values.set(name, value);
		constants.set(name, isConst);
	}

	public function get(name:String):Dynamic {
		if (values.exists(name)) return values.get(name);
		if (enclosing != null) return enclosing.get(name);
		trace('Undefined variable: $name');
		return null;
	}

	public function existsInChain(name:String):Bool {
		if (values.exists(name)) return true;
		if (enclosing != null) return enclosing.existsInChain(name);
		return false;
	}

	public function assign(name:String, value:Dynamic) {
		if (values.exists(name)) {
			if (constants.get(name) == true) {
				trace('Cannot assign to constant: $name');
				return;
			}
			values.set(name, value);
			return;
		}
		if (enclosing != null) {
			enclosing.assign(name, value);
			return;
		}
		trace('Undefined variable: $name');
	}
}
