package parser;

public interface ExpressionNodeVisitor {
	public void visit(VariableExpressionNode node);

	public void visit(ConstantExpressionNode node);

	public void visit(AdditionExpressionNode node);

	public void visit(MultiplicationExpressionNode node);

	public void visit(ExponentiationExpressionNode node);

	public void visit(FunctionExpressionNode node);

	public void visit(LogicExpressionNode node);

	public void accept(ExpressionNodeVisitor visitor);

}// interface ExpressionNodeVisitor