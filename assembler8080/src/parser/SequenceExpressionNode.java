package parser;

import java.util.LinkedList;

public abstract class SequenceExpressionNode implements ExpressionNode {
	protected LinkedList<Term> terms;

	public SequenceExpressionNode() {
		this.terms = new LinkedList<Term>();
	}//Constructor - SequenceExpressionNode
	
	public SequenceExpressionNode(ExpressionNode a, boolean positive) {
		this.terms = new LinkedList<Term>();
		this.terms.add(new Term(positive,a));
	}//Constructor - SequenceExpressionNode
	
	public void add(ExpressionNode a, boolean positive){
		this.terms.add(new Term(positive, a));
	}//add
	
//inner class
	public class Term{
		public boolean positive;
		public ExpressionNode expression;
		
		public Term(boolean positive, ExpressionNode expression){
			super();
			this.positive= positive;
			this.expression= expression;
		}//Constructor - Term(boolean positive, ExpressionNode expression)
		
	}//class Term

}//class SequenceExpressionNode
