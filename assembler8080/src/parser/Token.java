package parser;

public class Token {
	public final int token;
	public final String sequence;

	public Token(int token, String sequence) {
		super();
		this.token = token;
		this.sequence = sequence;
	}// Constructor - Token(token, sequence)
	public static final int EPSILON = 0;
	public static final int FUNCTION = 1;
	public static final int OPEN_BRACKET = 2;
	public static final int CLOSE_BRACKET = 3;
	public static final int PLUS_MINUS = 4;
	public static final int MULT_DIV = 5;
	public static final int RAISED = 6;
	public static final int HEX = 7;
	public static final int OCTAL = 8;
	public static final int BINARY = 9;
	public static final int DECIMAL = 10;
	public static final int STRING = 11;
	public static final int LOGIC = 12;
	public static final int VARIABLE = 13;
}// class Token

