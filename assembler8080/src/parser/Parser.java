package parser;

import java.util.LinkedList;

public class Parser {
	LinkedList<Token> tokens;
	Token lookahead;

	public Parser() {
	}// Constructor - Parser

	public ExpressionNode parse(LinkedList<Token> tokens) {
		this.tokens = (LinkedList<Token>) tokens.clone();
		lookahead = this.tokens.getFirst();

		ExpressionNode expr = expression();

		if (lookahead.token != Token.EPSILON) {
			throw new ParserException(String.format("Unexpected symbol %s found)", lookahead));
		}// if

		return expr;
	}// parse

	private void nextToken() {
		tokens.pop();

		if (tokens.isEmpty()) { // at the end we return an epsilon token
			lookahead = new Token(Token.EPSILON, ""); // -1 ??
		} else {
			lookahead = tokens.getFirst();
		}// if - empty
	}// nextToken

	private ExpressionNode expression() {
		// expression -> signed_term_sum_op
		ExpressionNode expr = signedTerm();
		return sumOp(expr);
	}// expression

	private ExpressionNode sumOp(ExpressionNode expr) {
		if (lookahead.token == Token.PLUS_MINUS) {// sum_op -> PLUSMINUS
													// term_sum_op
			AdditionExpressionNode sum;
			if (expr.getType() == ExpressionNode.ADDITION_NODE) {
				sum = (AdditionExpressionNode) expr;
			} else {
				sum = new AdditionExpressionNode(expr, true);
			}// if

			boolean positive = lookahead.sequence.equals("+");
			nextToken();
			ExpressionNode t = term();
			sum.add(t, positive);
			return sumOp(sum);
		} else { // sumOp -> EPLSILON
			return expr;
		}// if
	}// sumOp

	private ExpressionNode signedTerm() {
		if (lookahead.token == Token.PLUS_MINUS) { // signedTerm -> PLUSMINUS
													// term
			boolean positive = lookahead.sequence.equals("+");
			nextToken();
			ExpressionNode t = term();
			return (positive) ? t : new AdditionExpressionNode(t, false);
		} else { // signedTerm -> term
			return term();
		}// if
	}// signedterm

	private ExpressionNode term() {
		// term -> factor term_op
		ExpressionNode f = factor();
		return termOp(f);
	}// term

	private ExpressionNode termOp(ExpressionNode expression) {
		if (lookahead.token == Token.MULT_DIV) { // term_op -> MULT_DIV factor
													// term_op
			MultiplicationExpressionNode prod;
			if (expression.getType() == ExpressionNode.MULTIPLICATION_NODE) {
				prod = (MultiplicationExpressionNode) expression;
			} else {
				prod = new MultiplicationExpressionNode(expression, true);
			}// inner if - type

			boolean positive = lookahead.sequence.equals("*");
			nextToken();
			ExpressionNode f = signedFactor();
			prod.add(f, positive);
			return termOp(prod);
		}// if
			// term_op -> EPLSILON
		return expression;
	}// termOp()

	private ExpressionNode signedFactor() {
		if (lookahead.token == Token.PLUS_MINUS) { // signed_Factor -> PLUSMINUS
													// factor
			boolean positive = lookahead.sequence.equals("+");
			nextToken();
			ExpressionNode t = factor();
			return (positive) ? t : new AdditionExpressionNode(t, false);
		} else {
			// signed_Factor -> factor
			return factor();
		}// if
	}// signedFactor

	public ExpressionNode factor() {
		// factor -> argument - factor_op
		ExpressionNode a = argument();
		return factorOp(a);
	}// factor

	public ExpressionNode factorOp(ExpressionNode expression) {
		if (lookahead.token == Token.RAISED) { // factor_op -> RAISED expression
			nextToken();
			ExpressionNode exponent = signedFactor();
			return new ExponentiationExpressionNode(expression, exponent);
		} else { // factor_op ->EPLSILON
			return expression;
		}// if
	}// factorOp

	public ExpressionNode argument() {
		if (lookahead.token == Token.FUNCTION) { // argument -> FUNCTION
													// argument
			int function = FunctionExpressionNode.stringToFunction(lookahead.sequence);
			nextToken();
			ExpressionNode expr = argument();
			return new FunctionExpressionNode(function, expr);
		} else if (lookahead.token == Token.OPEN_BRACKET) { // argument ->
															// OPEN_BRACKET sum
															// CLOSE_BRACKET
			nextToken();
			ExpressionNode expr = expression();
			if (lookahead.token != Token.CLOSE_BRACKET) {
				String errMessage = String.format("Closing brackets expected and %s found instead", lookahead.sequence);
				throw new ParserException(errMessage);
			}// if - not closing bracket
			nextToken();
			return expr;
		} else { // argument -> value
			return value();
		}// if
	}// argument

	private ExpressionNode value() {
		// handle number conversion if needed
		ExpressionNode expr = null;
		int tokenType = lookahead.token;
		switch (tokenType) {
		case Token.DECIMAL:
			if (lookahead.sequence.endsWith("D")) { // xxxxD
				expr = new ConstantExpressionNode(Token.DECIMAL, lookahead.sequence);
			} else { // xxxx no "D"
				expr = new ConstantExpressionNode(lookahead.sequence);
			}//
			break;
		case Token.HEX:
			expr = new ConstantExpressionNode(Token.HEX, lookahead.sequence);
			break;
		case Token.OCTAL:
			expr = new ConstantExpressionNode(Token.OCTAL, lookahead.sequence);
			break;
		case Token.BINARY:
			expr = new ConstantExpressionNode(Token.BINARY, lookahead.sequence);
			break;
		case Token.STRING:
			expr = new ConstantExpressionNode(Token.STRING, lookahead.sequence);
			break;

		case Token.VARIABLE:
			expr = new VariableExpressionNode(lookahead.sequence);
			break;
		default:
			String errMessage = String.format("Unexpected Symbol %s found", lookahead.sequence);
			throw new ParserException(errMessage);
		}// switch
		nextToken();
		return expr;


	}// value

}// class Parser
