package parser;

//import MyParser.SequenceExpressionNode.Term;

public class LogicExpressionNode extends SequenceExpressionNode {

	public LogicExpressionNode() {
		super();
	}//Constructor - LogicExpressionNode()

	public LogicExpressionNode(ExpressionNode a, boolean positive) {
		super(a, positive);
		// TODO Auto-generated constructor stub
	}//Constructor -  LogicExpressionNode(ExpressionNode a, boolean positive)

	@Override
	public int getType() {
		return ExpressionNode.LOGIC_NODE;
	}//getType

	@Override
	public Integer getValue() {
		Integer result = 0;
		for (Term t: terms){
			if (t.positive){
				result += t.expression.getValue();
			}else{
				result -= t.expression.getValue();
			}//if
		}//for
		return result;
	}//getValue

	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
		for (Term t: terms){
			t.expression.accept(visitor);
		}//for
	}//accept

}
