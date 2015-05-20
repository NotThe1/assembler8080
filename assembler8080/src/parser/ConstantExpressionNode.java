package parser;

public class ConstantExpressionNode implements ExpressionNode {
	private Integer value;

	public ConstantExpressionNode(Integer value) {
		this.value = value;
	}// Constructor - ConstantExpressionNode(double value)

	public ConstantExpressionNode(String value) {
		this.value = Integer.valueOf(value);
	}// Constructor - ConstantExpressionNode(String value)

	public ConstantExpressionNode(int base, String rawValue) {
	
		rawValue = rawValue.substring(0,rawValue.length()-1);
		switch (base) {
		case Token.DECIMAL:
			value = Integer.valueOf(rawValue);
			break;
		case Token.HEX:
			value = Integer.valueOf(rawValue,16);
			break;
		case Token.OCTAL:
			value = Integer.valueOf(rawValue,8);
			break;
		case Token.BINARY:
			value = Integer.valueOf(rawValue,2);
			break;
		case Token.STRING:
//			value = Integer.valueOf(rawValue,2);
			value = 0;
			break;
		default:
			String errMessage = String.format("Unknown Constant expression found: %s - Type :%d%n", rawValue, base);
			throw new ParserException(errMessage);
		}// switch
		//this.value = value;
	}// Constructor - ConstantExpressionNode(String value)

	@Override
	public int getType() {
		return ExpressionNode.CONSTANT_NODE;
	}// getType

	@Override
	public Integer getValue() {
		return value;
	}// getValue
	
	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
	}//accept

}// class ConstantExpressionNode
