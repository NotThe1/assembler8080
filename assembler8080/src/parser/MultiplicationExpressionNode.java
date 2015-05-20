package parser;

//import MyParser.SequenceExpressionNode.Term;


public class MultiplicationExpressionNode extends SequenceExpressionNode {

	public MultiplicationExpressionNode() {
		// TODO Auto-generated constructor stub
	}//Constructor - MultiplicationExpressionNode() 

	public MultiplicationExpressionNode(ExpressionNode a, boolean positive) {
		super(a, positive);
		// TODO Auto-generated constructor stub
	}//Constructor -MultiplicationExpressionNode(ExpressionNode a, boolean positive) 

	@Override
	public int getType() {
		return ExpressionNode.MULTIPLICATION_NODE;
	}//getType

	@Override
	public Integer getValue() {
		Integer product = 1;
		for (Term t: terms){
			if (t.positive){
				product *= t.expression.getValue();
			}else{
				product /= t.expression.getValue();
			}//if
		}//for
		return product;
	}//getValue
	
	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
		for (Term t: terms){
			t.expression.accept(visitor);
		}//for
	}//accept



}//class MultiplicationExpressionNod
