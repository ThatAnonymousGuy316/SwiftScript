package swift;

class Main {
	static function main() {
		var path = Sys.args()[0];
		if (path == null) {
			trace("Usage: <run> <path-to-script.swift>");
			return;
		}

		var script = Script.fromFile(path);

		script.run();
		script.call("onCreate");
	}
}
