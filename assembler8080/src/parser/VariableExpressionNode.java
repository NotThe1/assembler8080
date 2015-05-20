package parser;

public class VariableExpressionNode implements ExpressionNode {
	private String name;
	private Integer value;
	private boolean valueSet;

	public VariableExpressionNode(String name) {
		this.name = name;
		valueSet = false;
	}//VariableExpressionNode

	@Override
	public int getType() {
		return ExpressionNode.VARIABLE_NODE;
	}//getType
	
	public void setValue(Integer value){
		this.value = value;
		valueSet = true;
	}//setValue

	@Override
	public Integer getValue() {
		if(valueSet){
			return value;
		}else{
			throw new EvaluationException("Variable '" + name +"' was not initialized.");
		}//if
	}//getValue
	
	public String getName(){
		return name;
	}//getname
	
	public void accept(ExpressionNodeVisitor visitor){
		visitor.visit(this);
	}//accept

}//class VariableExpressionNode
