package assembler;

public class Directive {
	private String name;
	private boolean nameRequired;
	private int maxNumberOfArguments;
	private boolean passTwo;
//	private int counterAdvance; //how many

	public Directive(String name,boolean nameRequired,int maxNumberOfArguments,boolean passTwo) {
		this.name = name;
		this.nameRequired = nameRequired;
		this.maxNumberOfArguments = maxNumberOfArguments;
		this.passTwo = passTwo;
	}//Constructor - Directive(nameRequired, maxNumberOfArguments, dataType)

	 boolean isNameRequired() {
		return nameRequired;
	}

//	 void setNameRequired(boolean nameRequired) {
//		this.nameRequired = nameRequired;
//	}

	int getMaxNumberOfArguments() {
		return maxNumberOfArguments;
	}

//	void setMaxNumberOfArguments(int maxNumberOfArguments) {
//		this.maxNumberOfArguments = maxNumberOfArguments;
//	}

	boolean doPassTwo() {
		return passTwo;
	}

//	void setDataType(DataType dataType) {
//		this.dataType = dataType;
//	}
	
	public String getName() {
		return name;
	}

//	public void setnName(String name) {
//		this.name = name;
//	}


}//class Directive
