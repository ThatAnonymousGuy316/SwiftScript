package swift;

class ScriptLoader {
	#if sys
	public static function fromFile(path:String):String {
		if (!sys.FileSystem.exists(path)) {
			trace('Script file not found: $path');
			return "";
		}
		return sys.io.File.getContent(path);
	}
	#end
	
	public static function fromAssets(path:String):String {
		return openfl.utils.Assets.getText(path);
	}
}
