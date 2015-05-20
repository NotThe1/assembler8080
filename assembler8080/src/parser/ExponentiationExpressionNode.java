package parser;


public class ExponentiationExpressionNode implements ExpressionNode {
	private ExpressionNode base;
	private ExpressionNode exponent;

	public ExponentiationExpressionNode(ExpressionNode base,ExpressionNode exponent) {
		this.base = base;
		this.exponent = exponent;
	}//Constructor - ExponentiationExpressionNode(ExpressionNode base,ExpressionNode exponent) 

	@Override
	public int getType() {
		return ExpressionNode.EXPONENTIATION_NODE;
	}//getType

	@Override
	public Integer getValue() {
		return (int) Math.pow(base.getValue(), exponent.getValue());
	}//getValue
	
	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
		base.accept(visitor);
		exponent.accept(visitor);
	}//accept


}//class ExponentiationExpressionNode
