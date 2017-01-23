package assembler;

import java.util.ArrayList;
import java.util.Collections;

public class SymbolTableEntry {
	private String name;
	private int value;
	private int symbolType;
	private int symbolScope;
//	private boolean absolute;
	private Integer definedLineNumber;
	private ArrayList<Integer> referencedLineNumbers;
	

	public SymbolTableEntry() {
		// TODO Auto-generated constructor stub
	}//Constructor - SymbolTable
	
	public SymbolTableEntry(String name,int value,int definedLineNumber,int symbolType){
		this.name = name;
		this.value = value;
		this.symbolType=symbolType;
		this.definedLineNumber= definedLineNumber;
		this.referencedLineNumbers = new ArrayList<Integer>();
		
	}//Constructor - SymbolTable - used when defining a new symbol   **SET
	
	public SymbolTableEntry(String name,int referencedLineNumber,int symbolType){
		this.name = name;
		if(this.referencedLineNumbers == null){
			this.referencedLineNumbers = new ArrayList<Integer>();
		}
		this.referencedLineNumbers.add(referencedLineNumber);
		
	}//Constructor - SymbolTable - used when referencing a new symbol

	String getName() {
		return name;
	}//getName
	void setName(String name) {
		this.name = name;
	}//setName

	int getValue() {
		return value;
	}//getValue
	void setValue(int value) {
		this.value = value;
	}//setValue

	int getSymbolType() {
		return symbolType;
	}//getSymbolType
	void setSymbolType(int symbolType) {
		this.symbolType = symbolType;
	}//setSymbolType

	int getSymbolScope() {
		return symbolScope;
	}//getSymbolScope
	void setSymbolScope(int symbolScope) {
		this.symbolScope = symbolScope;
	}//setSymbolScope

	Integer getDefinedLineNumber() {
		return definedLineNumber;
	}//getDefinedLineNumber
	void setDefinedLineNumber(Integer definedLineNumber) {
		this.definedLineNumber = definedLineNumber;
	}//setDefinedLineNumber

	ArrayList<Integer> getReferencedLineNumbers() {
		ArrayList<Integer> lineNumbers = (ArrayList<Integer>) this.referencedLineNumbers.clone();
		Collections.sort(lineNumbers);
		return lineNumbers;
	}//getReferencedLineNumbers
	
	Integer getReferencedLineNumberSize(){
		return referencedLineNumbers.size();
	}//getReferencedLineNumberSize
	
	void addReferenceLineNumber(int lineNumber){
		if(!referencedLineNumbers.contains(lineNumber)){
			referencedLineNumbers.add(lineNumber);
		}//do not want duplicate references
	}//addReferenceLineNumber

}//class SymbolTable