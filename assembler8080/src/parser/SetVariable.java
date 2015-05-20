package parser;

public class SetVariable implements ExpressionNodeVisitor {
	
	private String name;
	private Integer value;

	public SetVariable(String name,Integer value) {
		super();
		this.name = name;
		this.value= value;
	}//Constructor - SetVariable()
	
	
	@Override
	public void visit(VariableExpressionNode node) {
		if (node.getName().equals(name)){
			node.setValue(value);
		}//if
	}//visit

	@Override
	public void visit(ConstantExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void visit(AdditionExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void visit(MultiplicationExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void visit(ExponentiationExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void visit(FunctionExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void visit(LogicExpressionNode node) {
		// TODO Auto-generated method stub
	}
	@Override
	public void accept(ExpressionNodeVisitor visitor) {
		// TODO Auto-generated method stub
	}
	
	

}
