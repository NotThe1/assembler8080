package assembler;

public class PassOne {
	private Integer lineNumber; // Source file line number
	private boolean isEmptyLine; // true if Source file line is empty
	private Integer location; // Memory location
	private String symbol; // Label or Name
//	private boolean isInstruction; // true if instruction,false if directive
	private Instruction instruction; // Instruction
	private Directive directive;	//  Directive
	private String arguments; // whole argument field
	private String comment; // Comments if any

	public PassOne() {
		// TODO Auto-generated constructor stub
	}// Constructor - PassOne();
	public PassOne(Integer lineNumber) {		//add an empty line
		this.setLineNumber(lineNumber);
		this.setEmptyLine(true);
	}// Constructor - PassOne(Integer lineNumber)
	public PassOne(Integer lineNumber, Integer location,String symbol,Instruction instruction,
			String arguments,String comment) {	//add line with Instruction
		this.setLineNumber(lineNumber);
		this.setEmptyLine(false);
		this.setLocation(location);
		this.setSymbol(symbol);
//		this.setInstruction(true);
		this.setInstruction(instruction);
		this.setArguments(arguments);
		this.setComment(comment);
	}// Constructor - PassOne(Integer lineNumber, Integer location,String symbol,Instruction instruction,
	//							String arguments,String comment)
	public PassOne(Integer lineNumber, Integer location,String symbol,Directive directive,
			String arguments,String comment) {	//add line with Directiver
		this.setLineNumber(lineNumber);
		this.setEmptyLine(false);
		this.setLocation(location);
		this.setSymbol(symbol);
//		this.setInstruction(true);
		this.setDirective(directive);
		this.setArguments(arguments);
		this.setComment(comment);
	}// Constructor - PassOne(Integer lineNumber, Integer location,String symbol,Instruction instruction,
	//							String arguments,String comment)
	public PassOne(Integer lineNumber, Integer location,String symbol,String comment) {	//label abd (comment)
		this.setLineNumber(lineNumber);
		this.setEmptyLine(false);
		this.setLocation(location);
		this.setSymbol(symbol);
		this.setArguments(arguments);
		this.setComment(comment);
	}// Constructor - PassOne(Integer lineNumber, Integer location,String symbol,Instruction instruction,
	//							String arguments,String comment)
	public Integer getLineNumber() {
		return lineNumber;
	}//getLineNumber
	private void setLineNumber(Integer lineNumber) {
		this.lineNumber = lineNumber;
	}//setLineNumber
	public boolean isEmptyLine() {
		return isEmptyLine;
	}//isEmptyLine
	private void setEmptyLine(boolean isEmptyLine) {
		this.isEmptyLine = isEmptyLine;
	}//setEmptyLine
	public Integer getLocation() {
		return location;
	}//getLocation
	public void setLocation(Integer location) {
		this.location = location;
	}//setLocation
	public String getSymbol() {
		return symbol;
	}//getSymbol
	private void setSymbol(String symbol) {
		this.symbol = symbol;
	}//setSymbol
//	public boolean isInstruction() {
//		return isInstruction;
//	}//isInstruction
//	private void setInstruction(boolean isInstruction) {
//		this.isInstruction = isInstruction;
//	}//setInstruction
	public Instruction getInstruction() {
		return instruction;
	}//getInstruction
	private void setInstruction(Instruction instruction) {
		this.instruction = instruction;
	}//setInstruction
	public Directive getDirective() {
		return directive;
	}//getDirective
	private void setDirective(Directive directive) {
		this.directive = directive;
	}//setDirective
	public String getArguments() {
		return arguments;
	}//getArguments
	private void setArguments(String arguments) {
		this.arguments = arguments;
	}//setArguments
	public String getComment() {
		return comment;
	}//getComment
	public void setComment(String comment) {
		this.comment = comment;
	}//setComment

}// class PassOne