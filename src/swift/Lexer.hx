package swift;

enum TokenType {
	// Literals
	Identifier;
	IntLiteral;
	FloatLiteral;
	StringLiteral;
	True;
	False;
	Nil;

	// Keywords
	Let;
	Var;
	Func;
	If;
	Else;
	For;
	While;
	In;
	Return;

	// Symbols
	LParen;    // (
	RParen;    // )
	LBrace;    // {
	RBrace;    // }
	Comma;     // ,
	Colon;     // :
	Arrow;     // ->
	Equals;    // =
	Plus; Minus; Star; Slash;
	PlusEq; MinusEq;
	EqEq; NotEq;
	Lt; Gt; LtEq; GtEq;

	Newline;
	EOF;
}

typedef Token = {
	type: TokenType,
	lexeme: String,
	line: Int,
}

class Lexer {
	static var keywords:Map<String, TokenType> = [
		"let" => Let,
		"var" => Var,
		"func" => Func,
		"if" => If,
		"else" => Else,
		"for" => For,
		"while" => While,
		"in" => In,
		"return" => Return,
		"true" => True,
		"false" => False,
		"nil" => Nil,
	];

	var source:String;
	var pos:Int = 0;
	var line:Int = 1;
	var tokens:Array<Token> = [];

	public function new(source:String) {
		this.source = source;
	}

	public function scanTokens():Array<Token> {
		while (!isAtEnd()) {
			scanToken();
		}
		tokens.push({type: EOF, lexeme: "", line: line});
		return tokens;
	}

	function scanToken() {
		var c = advance();

		switch (c) {
			case ' ' | '\t' | '\r':
			case '\n':
				line++;
			case '(': add(LParen, c);
			case ')': add(RParen, c);
			case '{': add(LBrace, c);
			case '}': add(RBrace, c);
			case ',': add(Comma, c);
			case ':': add(Colon, c);
			case '+':
				if (match('=')) add(PlusEq, "+=") else add(Plus, c);
			case '-':
				if (match('>')) add(Arrow, "->")
				else if (match('=')) add(MinusEq, "-=")
				else add(Minus, c);
			case '*': add(Star, c);
			case '/':
				if (match('/')) {
					while (peek() != '\n' && !isAtEnd()) advance();
				} else {
					add(Slash, c);
				}
			case '=':
				if (match('=')) add(EqEq, "==") else add(Equals, c);
			case '!':
				if (match('=')) add(NotEq, "!=");
			case '<':
				if (match('=')) add(LtEq, "<=") else add(Lt, c);
			case '>':
				if (match('=')) add(GtEq, ">=") else add(Gt, c);
			case '"':
				scanString();
			default:
				if (isDigit(c)) {
					scanNumber();
				} else if (isAlpha(c)) {
					scanIdentifier();
				} else {
					trace('Unexpected character "$c" at line $line');
				}
		}
	}

	function scanString() {
		var start = pos;
		while (peek() != '"' && !isAtEnd()) {
			if (peek() == '\n') line++;
			advance();
		}
		if (isAtEnd()) {
			trace('Unterminated string at line $line');
			return;
		}
		var value = source.substring(start, pos);
		advance();
		tokens.push({type: StringLiteral, lexeme: value, line: line});
	}

	function scanNumber() {
		var start = pos - 1;
		var isFloat = false;
		while (isDigit(peek())) advance();
		if (peek() == '.' && isDigit(peekNext())) {
			isFloat = true;
			advance();
			while (isDigit(peek())) advance();
		}
		var value = source.substring(start, pos);
		tokens.push({type: isFloat ? FloatLiteral : IntLiteral, lexeme: value, line: line});
	}

	function scanIdentifier() {
		var start = pos - 1;
		while (isAlphaNumeric(peek())) advance();
		var text = source.substring(start, pos);
		var type = keywords.exists(text) ? keywords.get(text) : Identifier;
		tokens.push({type: type, lexeme: text, line: line});
	}

	function add(type:TokenType, lexeme:String) {
		tokens.push({type: type, lexeme: lexeme, line: line});
	}

	function advance():String {
		var c = source.charAt(pos);
		pos++;
		return c;
	}

	function match(expected:String):Bool {
		if (isAtEnd() || source.charAt(pos) != expected) return false;
		pos++;
		return true;
	}

	function peek():String {
		if (isAtEnd()) return "\\0";
		return source.charAt(pos);
	}

	function peekNext():String {
		if (pos + 1 >= source.length) return "\\0";
		return source.charAt(pos + 1);
	}

	function isAtEnd():Bool return pos >= source.length;
	function isDigit(c:String):Bool return c >= "0" && c <= "9";
	function isAlpha(c:String):Bool return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_";
	function isAlphaNumeric(c:String):Bool return isAlpha(c) || isDigit(c);
}
