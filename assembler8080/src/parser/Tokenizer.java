package parser;

import java.util.LinkedList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Tokenizer {
	private LinkedList<TokenInfo> tokenInfos;
	private LinkedList<Token> tokens;

	public Tokenizer() {
		tokenInfos = new LinkedList<TokenInfo>();
		tokens = new LinkedList<Token>();
		
		this.add("sin|cos|exp|ln|sqrt",Token.FUNCTION);
		this.add("\\(", Token.OPEN_BRACKET);
		this.add("\\)",Token.CLOSE_BRACKET);
		this.add("[\\+|-]", Token.PLUS_MINUS);
		this.add("[\\*|/]", Token.MULT_DIV);
		this.add("[\\^]", Token.RAISED);
		this.add("[0-9][0-9a-fA-F]{0,4}H", Token.HEX);
		this.add("[0-7]+[Q|O]",Token.OCTAL);
		this.add("[0-1]+B", Token.BINARY);
		this.add("[0-9]{1,4}D?+", Token.DECIMAL);
		this.add("'.*'", Token.STRING);
		this.add("\\bAND\\b|\\bOR\\b", Token.LOGIC);
		this.add("^[\\?\\@\\w\\$][\\w\\$]{0,24}", Token.VARIABLE);
		//	"^[\\?\\@\\w][\\w]{0,7}"
		//  "^[\\?\\@\\w][\\w]{0,19}"
		this.add("\\s\\$\\s", Token.VARIABLE);		//"\\$"
				
	}// Constructor - Tokenizer()

//	public static void main(String[] args) {
//		Tokenizer tokenizer = new Tokenizer();
//	}// main
	public void tokenize(String str){
		String s = new String(str).trim();
		tokens.clear();
		
		while(!s.equals("")){
			boolean match = false;
			for(TokenInfo info : tokenInfos){
				Matcher m = info.regex.matcher(s);
				if (m.find()){
					match = true;
					
					String tok = m.group().trim();
					tokens.add(new Token(info.token,tok));
					
					s = m.replaceFirst("").trim();
					break;
				}//if -find
			}// for-each info
			if(!match){
				throw new ParserException("Unexpected character in input: " + s);	
			}//if
		}//while
	}//tokenize
	
	public LinkedList<Token> getTokens(){
		return tokens;
	}//getTokens

	public void add(String regex, int token) {
		tokenInfos.add(new TokenInfo(Pattern.compile("^(" + regex + ")"), token));
	}// add

	// inner classes
	private class TokenInfo {
		public final Pattern regex;
		public final int token;

		public TokenInfo(Pattern regex, int token) {
			super();
			this.regex = regex;
			this.token = token;
		}// Constructor - TokenInfo(regex , token)
	}// class TokenInfo


	
//EQUATES
//	private  String[] regexes = {"sin|cos|exp|ln|sqrt",	//REGEX_FUNCTION
//		"\\(",		//REGEX_OPEN_BRACKET 
//		"\\)",		//REGEX_CLOSE_BRACKET
//		"[\\+|-]",		//REGEX_PLUS_MINUS
//		"[\\*|/]",		//REGEX_MULT_DIV
//		"[\\^]",	//REGEX_RAISED
//		"[0-9][0-9a-fA-F]{1,4}H",	//REGEX_HEX
//		"[0-7]*[Q|O]",		//REGEX_OCTAL
//		"[0-1]+B",			//REGEX_BINARY
//		"[0-9]{1,4}D?+",	//REGEX_DECIMAL
//		"'.*'",				//REGEX_STRING
//		"^[\\?\\@\\w][\\w]{0,7}"	//REGEX_VARIABLE 
//		
//	};
//	
	

}// class Tokenizer