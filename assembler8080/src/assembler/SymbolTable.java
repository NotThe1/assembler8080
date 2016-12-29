package assembler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

public class SymbolTable {
	private HashMap<String, SymbolTableEntry> symbols;
	// private ArrayList<SymbolTableEntry> symbols;
	private SymbolTableEntry entry;
	private static boolean pass1 = true; // used to control two pass assembler
	private  InstructionCounter instructionCounter;

	public SymbolTable() {
		symbols = new HashMap<String, SymbolTableEntry>();
		symbols.put("$", new SymbolTableEntry("$", 0, 0, SymbolTable.ASSEMBLER));
		// pass1 = true;
	}// SymbolTable

	public SymbolTable(InstructionCounter ic) {
		symbols = new HashMap<String, SymbolTableEntry>();
		this.instructionCounter = ic;
		// pass1 = true;
	}// SymbolTable
	
	public void reset(){
		symbols.clear();
		symbols.put("$", new SymbolTableEntry("$", 0, 0, SymbolTable.ASSEMBLER));
	}//reset

	public static void passOneDone() {
		pass1 = false;
	}

	public void defineSymbol(String name, int value, int lineNumber, int symbolType) {
		if (symbols.containsKey(name)) {
			// TODO - account for SET
			if (!pass1) {
				return;
			}//
			String message = String.format("Duplicate definition of %s at line # %04d%n", name, lineNumber);
			System.err.println(message);

		} else { // new symbol
			symbols.put(name, new SymbolTableEntry(name, value, lineNumber, symbolType));
		}// if
	}// defineSymbol

	public void referenceSymbol(String name, int lineNumber, int symbolType) {
		if (symbols.containsKey(name)) {
			entry = symbols.get(name);
			entry.addReferenceLineNumber(lineNumber);
			symbols.put(name, entry);
		} else {
			symbols.put(name, new SymbolTableEntry(name, lineNumber, symbolType));
		}// if
	}// referenceSymbol

	public void referenceSymbol(String name, int lineNumber) {
		if (symbols.containsKey(name)) {
			entry = symbols.get(name);
			entry.addReferenceLineNumber(lineNumber);
			symbols.put(name, entry);
		} else {
			throw new AssemblerException("Attempting to reference an undefined symbol: " + name + " on line: "
					+ lineNumber);
		}// if
	}// referenceSymbol

	public HashMap<String, SymbolTableEntry> getTableEntries() {
		return symbols;
	}// getTableEntries
	
	public List<String> getAllSymbols(){
		Set<String> allSymbols = symbols.keySet();
		List<String> symbolList = asSortedList(allSymbols);
		return symbolList;
		
	}//getAllSymbols
	public static
	<T extends Comparable<? super T>> List<T> asSortedList(Collection c){
		List<T> list = new ArrayList<T>(c);
		Collections.sort(list);
		return list;
	}//asSortedList
	
	
	public SymbolTableEntry getEntry(String symbol){
		return symbols.get(symbol);
	}//getEntry

	public boolean contains(String name) {
		return symbols.containsKey(name);
	}// contains

	public Integer getValue(String name) {
		if (name.equals("$")) {
			return instructionCounter.getPriorLocation();
		} else {
			try {
				return symbols.get(name).getValue();
			} catch (NullPointerException npe) {
				System.err.printf("Bad symbol: %s%n", name);
				return 0;
			}// try
		}//if

	}// getValue
		// ----------------------------------------------------------------------

	public final static int LABEL = 0;
	public final static int NAME = 1;
	public final static int ASSEMBLER = 2;

	public final static int LOCAL = 3;
	public final static int GLOBAL = 4;

}// class SymbolTable

