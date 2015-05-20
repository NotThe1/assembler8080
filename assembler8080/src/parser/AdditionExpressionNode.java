package parser;


public class AdditionExpressionNode extends SequenceExpressionNode {

	public AdditionExpressionNode() {
		super();
	}//Constructor - AdditionExpressionNode() 

	public AdditionExpressionNode(ExpressionNode a, boolean positive) {
		super(a, positive);
	}//Constructor - AdditionExpressionNode(ExpressionNode a, boolean positive)

	@Override
	public int getType() {
		return ExpressionNode.ADDITION_NODE;
	}//getType

	@Override
	public Integer getValue() {
		Integer sum = 0;
		for (Term t: terms){
			if (t.positive){
				sum += t.expression.getValue();
			}else{
				sum -= t.expression.getValue();
			}//if
		}//for
		return sum;
	}//getValue
	
	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
		for (Term t: terms){
			t.expression.accept(visitor);
		}//for
	}//accept

}//class AdditionExpressionNode 
