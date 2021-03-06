package assembler;

import java.awt.Color;
import java.awt.Component;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.AdjustmentEvent;
import java.awt.event.AdjustmentListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Scanner;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTextArea;
import javax.swing.SwingConstants;
import javax.swing.filechooser.FileNameExtensionFilter;

import parser.EvaluationException;
import parser.ExpressionNode;
import parser.Parser;
import parser.ParserException;
import parser.SetVariable;
import parser.Token;
import parser.Tokenizer;

public class ASM_1_0 implements ActionListener, AdjustmentListener {

	private JFrame frame;
	private File asmSourceFile = null;
	private JButton btnStart;
	private Scanner scanner;
	private Scanner scannerComma;
	private Pattern patternForLabel;
	private Pattern patternForName;
	private Pattern patternForComments;
	private Pattern patternForInclude;
	private Pattern patternForLineNumber;
	private String r8r8Pattern;
	private String r16dPattern;
	private String r8Pattern;
	private Matcher matcher;
	private JCheckBox cbSaveToFile;
	private String defaultDirectory;

	private LinkedList<PassOne> passOneList;
	private SymbolTable symbolTable;
	private InstructionCounter instructionCounter;
	private HashMap<Integer, Byte> memoryImage; /* allows for non contiguous memory utilization */
												
	private Tokenizer tokenizer;
	
	private Parser parser;
	private int lineNumber;
	private boolean isEmptyLine;
	private int currentPC;
	private String symbol;
	private Instruction instruction;
	private Directive directive;
	private String arguments;
	private String comment;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					ASM_1_0 window = new ASM_1_0();
					window.frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}// try
			}// run
		});
	}// main

	/*
	 * starting point for the Assembler
	 */

	public void passTwo(File sourceFile) {
		Matcher matcher;
		// String line= null;
		String rawLine = null;
		String sourceLine = null;

		try {
			if (memoryImage != null) {
				memoryImage = null;
			}// new memory Image
			memoryImage = new HashMap<Integer, Byte>();
			String ap = sourceFile.getAbsolutePath();
			String baseFileName = ap.substring(0, ap.length() - 4);
			String listFilePath = baseFileName + ".list";
			File listFile = new File(listFilePath);
			FileWriter fw = new FileWriter(listFile);
			PrintWriter pw = new PrintWriter(fw);

			// FileReader source = new FileReader(sourceFile);
			// BufferedReader reader = new BufferedReader(source);

			currentPC = instructionCounter.getCurrentLocation();

			Scanner scannerPassTwo = new Scanner(txtSource.getText());
			while (scannerPassTwo.hasNextLine()) {
				String memImage = "";
				sourceLine = scannerPassTwo.nextLine();
				matcher = patternForLineNumber.matcher(sourceLine);
				if (!matcher.lookingAt()) {
					continue;
				}// no line number
				int lineNumber = Integer.valueOf(matcher.group().trim(), 10);
				rawLine = sourceLine.substring(matcher.end(), sourceLine.length());
				parseLine(lineNumber, rawLine);
				// line = rawLine.toUpperCase();
				// parseLine(lineNumber, line);
				//

				if (isEmptyLine) {
					passOneList.add(new PassOne(lineNumber)); // empty line
				} else if (instruction != null) {
					passOneList.add(new PassOne(lineNumber, currentPC, symbol, instruction, arguments, comment));// Instruction
					memImage = setMemoryBytes(lineNumber, instruction, arguments);
				} else if (directive != null) {
					if (directive.doPassTwo()) {
						memImage = setMemoryBytesForDirectives(lineNumber, directive, arguments);
					}// if pass2
					passOneList.add(new PassOne(lineNumber, currentPC, symbol, directive, arguments, comment));// Directive
				} else {
					passOneList.add(new PassOne(lineNumber, currentPC, symbol, comment));
				}//
				saveMemoryImage(currentPC, memImage);
				String logMessage = String.format("%04d: %04X  %-10s %-20s%n", lineNumber, currentPC, memImage,
						rawLine);
				txtListing.append(logMessage);
				if (cbSaveToFile.isSelected()) {
					pw.print(logMessage);
				}// if - do we send to file?

			}// while
			scannerPassTwo.close();

			doList(pw);
			if (cbSaveToFile.isSelected()) {
				try {
					String memoryFilePath = baseFileName + ".mem";
					File memoryFile = new File(memoryFilePath);
					FileWriter mfw = new FileWriter(memoryFile);
					mfw.write(doMemoryFile());
					mfw.close();
				} catch (Exception e) {
					// TODO: handle exception
				}// inner try
			}// if

			txtSource.setCaretPosition(0);
			txtListing.setCaretPosition(0);
			// reader.close();
			pw.close();
			fw.close();
		} catch (IOException e) {
			e.printStackTrace();
		}// outter TRY
	}// performPassTwo

	private String doMemoryFile() {// FileWriter fw
		Set<Integer> locations = memoryImage.keySet();
		List<Integer> locationsOrdered = asSortedList(locations);

		// int sourceLocation;
		int lastLocation = -1;
		int currentLocation = -1;
		int currentLineStart = -1;
		byte zero = 0;
		StringBuilder sb = new StringBuilder();
		StringBuilder thisLine = new StringBuilder();
		Byte value;
		// Scanner sc = new Scanner(txtValues.getText());
		for (Integer sourceLocation : locationsOrdered) {
			lastLocation = currentLocation;
			value = memoryImage.get(sourceLocation);
			if ((sourceLocation & 0XFFF0) == currentLineStart) {// on the same line
				if (currentLocation < sourceLocation) {// need some padding
					while (currentLocation < sourceLocation) {
						sb.append(getThisValue(currentLocation, zero));
						thisLine.append(getThisChar(currentLocation, zero));
						currentLocation++;
					}// while - pad in middle
				}// if - need to catch up to source location
				sb.append(getThisValue(currentLocation, value));
				thisLine.append(getThisChar(currentLocation, value));
				currentLocation++;
				// ------------------
			} else { // start a new line
				if ((lastLocation % 16 != 0) && (sb.length() != 0)) {
					// do pad on initial pass or if not needed
					int leftPadCount = lastLocation % 16;
					for (int i = leftPadCount; i < 16; i++) {
						sb.append(getThisValue(i, zero));
						thisLine.append(getThisChar(i, zero));
					}// pad right
				}// if - initial pass
				sb.append(thisLine.toString());

				currentLineStart = sourceLocation & 0XFFF0;
				currentLocation = currentLineStart + 1;
				thisLine.setLength(0);
				thisLine.append(" ");

				if (currentLineStart == sourceLocation) {// use actual value
					sb.append(String.format("%n%04X:", currentLineStart));
					sb.append(getThisValue(currentLineStart, value));
					thisLine.append(getThisChar(currentLineStart, value));
				} else {
					sb.append(String.format("%n%04X:", currentLineStart));
					sb.append(getThisValue(currentLineStart, zero));
					thisLine.append(getThisChar(currentLineStart, zero));
					while (currentLocation < sourceLocation) {
						sb.append(getThisValue(currentLocation, zero));
						thisLine.append(getThisChar(currentLocation, zero));
						currentLocation++;
					}// while - pad in middle
					sb.append(getThisValue(currentLocation, value));
					thisLine.append(getThisChar(currentLocation, value));
					currentLocation++;
				}// if/else
			}// new line and left adding
		}// while - processing each location/value
			// -----done processing actual values--------
		// -------------- need to finish output------------------
		if (currentLocation % 16 != 0) {// clean up
			int leftPadCount = currentLocation % 16;
			for (int i = leftPadCount; i < 16; i++) {
				sb.append(getThisValue(i, zero));
				thisLine.append(getThisChar(i, zero));
			}// pad right
		}// if - intial pass
		sb.append(thisLine.toString());
		// -----done with cleanup------
		return sb.toString();
		// process to end of line
	}// doMemoryFile

	private String getThisValue(int location, byte value) {
		final String stdFormat = " %02X";
		final String xtraSpaceFormat = " %02X ";
		String thisFormat = (((location % 16) == 7)) ? xtraSpaceFormat : stdFormat;
		return String.format(thisFormat, value);
	}

	private String getThisChar(int location, byte value) {
		String c = (((value >= 0X20) && (value <= 0X7F)) ? new String(new byte[] { value }) : ".");
		if ((location % 16) == 7) {
			return c + " ";
		} else {
			return c;
		}//
	}// getThischar

	private void doList(PrintWriter pw) {
		if (cbSaveToFile.isSelected()) {
			pw.printf("%n%n%n%n%40s%n%n", "Xref");
		}// if - file?

		txtListing.append(String.format("%n%n%n%n%40s%n%n", "Xref"));

		HashMap<String, SymbolTableEntry> symbols = symbolTable.getTableEntries();
		Set<String> keys = symbols.keySet();
		List<String> list = asSortedList(keys); // *******************************
												// see below
		ArrayList<Integer> refLines;
		StringBuilder sb;
		char fistLetter = 00;
		for (String key : list) {
			SymbolTableEntry entry = symbols.get((String) key);
			String name = entry.getName();
			int value = entry.getValue();
			int lineNumber = entry.getDefinedLineNumber();
			refLines = entry.getReferencedLineNumbers();
			sb = new StringBuilder();
			for (int refLine : refLines) {
				sb.append(String.format("  %04d,", refLine));
			}// for - reference line numbers

			if (fistLetter != name.charAt(0)) {
				txtListing.append("\n");
				if (cbSaveToFile.isSelected()) {
					pw.printf("%n");
				}// if - file?
			}// if skip a line?
			fistLetter = name.charAt(0);
			if (cbSaveToFile.isSelected()) {
				pw.printf("%04d\t%04X\t%-30s\t\t%s%n", lineNumber, value, name, sb.toString());
			}// if - file?
			String logEntry = String.format("%04d\t%04X\t%-30s\t\t%s%n", lineNumber, value, name, sb.toString());
			txtListing.append(logEntry);
			sb = null;
		}// for
	}// doList
		// *******************used above

	public static <T extends Comparable<? super T>> List<T> asSortedList(Collection<T> c) {
		List<T> list = new ArrayList<T>(c);
		Collections.sort(list);
		return list;
	}// sort for key list

	private void saveMemoryImage(int pc, String memImage) {
		int numOfChars = memImage.length() / 2;
		if (numOfChars < 1) {
			return;
		}// if - nothing here
		String strValue;
		int intValue;
		for (int i = 0; i < numOfChars; i++) {
			strValue = memImage.substring(i * 2, (i + 1) * 2);
			intValue = Integer.valueOf(strValue, 16);
			memoryImage.put((Integer) pc + i, (byte) intValue);
		}
	}// saveMemoryImage

	public void passOne() {
		Matcher matcher;
		String line;

		Scanner scannerPassOne = new Scanner(txtSource.getText());
		while (scannerPassOne.hasNextLine()) {
			line = scannerPassOne.nextLine();
			matcher = patternForLineNumber.matcher(line);
			if (!matcher.lookingAt()) {
				continue;
			}// no line number
			int lineNumber = Integer.valueOf(matcher.group().trim(), 10);
			parseLine(lineNumber, line.substring(matcher.end(), line.length()));
		}// while

		// symbolTable.passOneDone();
		SymbolTable.passOneDone();
		instructionCounter.reset();
		scannerPassOne.close();
	}// buildTheSymbolTable

	public void passZero(File sourceFile) {
		try {
			FileReader source = new FileReader(sourceFile);
			BufferedReader reader = new BufferedReader(source);
			String line = null;
			String rawLine = null;
			String outputLine;
			Matcher matcher1;
			while ((rawLine = reader.readLine()) != null) {
				// line = rawLine.toUpperCase();
				line = rawLine;
				lineNumber++;
				outputLine = String.format("%04d  %s%n", lineNumber, line);
				txtSource.append(outputLine);
				matcher1 = patternForInclude.matcher(line);

				if (matcher1.find()) {
					String fileReference = line.substring(matcher1.end(), line.length());
					doInclude(fileReference, sourceFile.getParentFile().getAbsolutePath());
				}// if
			}// while
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}// TRY
	}// passZero

	public void doInclude(String fileReference, String parentDirectory) {

		if (!fileReference.contains("\\")) {
			fileReference = parentDirectory + System.getProperty("file.separator") + fileReference;
		}//

		if (!(fileReference.toUpperCase().endsWith(ASSEMBLER_SUFFIX.toUpperCase()))) {
			fileReference += "." + ASSEMBLER_SUFFIX;
		}//

		String includeMarker = ";<<<<<<<<<<<<<<<<<<<<<<<   Include  >>>>>>>>>>>>>>>>";
		txtSource.append(String.format("%04d  %s%n", lineNumber++, includeMarker));

		File includedFile = new File(fileReference);
		passZero(includedFile);

		txtSource.append(String.format("%04d  %s%n", lineNumber++, includeMarker));

	}// doInclude

	// private void displaySymbolTable() {
	// HashMap<String, SymbolTableEntry> symbols = symbolTable.getTableEntries();
	// Set<String> keys = symbols.keySet();
	//
	// for (Object key : keys) {
	// SymbolTableEntry entry = symbols.get((String) key);
	// String name = entry.getName();
	// int value = entry.getValue();
	// int lineNumber = entry.getDefinedLineNumber();
	// String references = "";
	// if (entry.getReferencedLineNumbers() != null) {
	// for (int i : entry.getReferencedLineNumbers()) {
	// references += String.format(",%04d", i);
	// }// for
	// }// if
	// String logEntry = String.format("%04d  %04X  %s\t%s%n", lineNumber, value, name, references);
	// txtListing.append(logEntry);
	// }// for
	// }// displaySymbolTable

	private String setMemoryBytesForDirectives(Integer lineNumber, Directive directive, String arguments) {
		String ans = "";
		int ansInt = 00;
		String directiveName = directive.getName();
		switch (directiveName) {
		case "DB":
			if (arguments == null) {
				throw new AssemblerException("DB on line: " + lineNumber + " needs an argument");
			} else {
				String arg;

				scannerComma = new Scanner(arguments);
				scannerComma.useDelimiter(",");
				while (scannerComma.hasNext()) {
					arg = scannerComma.next();
					if (arg.matches(stringValuePattern)) {// Literal
						arg = arg.replace("'", "");
						char[] allLetters = arg.toCharArray();
						byte b;
						for (char eachLetter : allLetters) {
							b = (byte) eachLetter;
							ans += String.format("%02X", b);
						}// for
					} else { // expression
						ansInt = resolveSimpleArgument(arg, lineNumber) & 0XFF;
						ans += String.format("%02X", ansInt);
					}//
				}// while
			}// if - arguments null

			break;
		case "DW":
			if (arguments == null) {
				throw new AssemblerException("DW on line: " + lineNumber + " needs an argument");
			} else {
				String arg;
				scannerComma = new Scanner(arguments);
				scannerComma.useDelimiter(",");
				while (scannerComma.hasNext()) {
					arg = scannerComma.next();
					ansInt = resolveSimpleArgument(arg, lineNumber) & 0XFFFF;
					byte hiByte = (byte) (ansInt >> 8);
					byte loByte = (byte) (ansInt & 0x00FF);
					ans += String.format("%02X%02X", loByte, hiByte);
				}// while
			}// if - arguments null

			break;
		default:
			String msg = String.format("Bad Directive - %s -  on source line:%04d", directiveName, lineNumber);
			throw new AssemblerException(msg);
		}// switch

		return ans;
	}// setMemoryBytesForDirectives

	private String setMemoryBytes(Integer lineNumber, Instruction instruction, String arguments) {
		String ans = null;
		Integer argumentType = instruction.getOperandType();
		Byte baseCode = instruction.getBaseCode();
		byte registerValue;
		int shiftValue;
		int arg;
		String argStr;
		byte opC;
		switch (argumentType) {
		case Instruction.ARGUMENT_NONE:
			ans = String.format("%02X", baseCode); // Only one value
			break;
		case Instruction.ARGUMENT_R8:
			registerValue = Instruction.getR8Value(arguments);
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);
			ans = String.format("%02X", opC);
			break;
		case Instruction.ARGUMENT_R8_R8:
			String args = arguments.replace(" ", "");
			if (!args.matches(r8r8Pattern)) {
				String msg = String.format("Bad argument - %s -  on source line:%04d", arguments, lineNumber);
				throw new AssemblerException(msg);
			} else {
				byte register1Value = Instruction.getR8Value(args.substring(0, 1));
				byte register2Value = Instruction.getR8Value(args.substring(2));
				int shiftValue1 = instruction.getOperand1Shift();
				int shiftValue2 = instruction.getOperand2Shift();
				register1Value = (byte) (register1Value << shiftValue1);
				register2Value = (byte) (register2Value << shiftValue2);

				opC = (byte) (baseCode | register1Value | register2Value);
				ans = String.format("%02X", opC);
			}// if
			break;
		case Instruction.ARGUMENT_R16D:
			registerValue = Instruction.getR16DValue(arguments);
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);
			ans = String.format("%02X", opC);
			break;
		case Instruction.ARGUMENT_R16Q:
			registerValue = Instruction.getR16QValue(arguments);
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);
			ans = String.format("%02X", opC);
			break;
		case Instruction.ARGUMENT_D8:
			opC = baseCode;
			if (arguments.matches(stringValuePattern)) {// Literal
				arg = Integer.valueOf(arguments.replace("'", ""), 16) & 0XFF;
			} else {
				arg = resolveSimpleArgument(arguments, lineNumber);
			}//
			ans = String.format("%02X%02x", opC, arg).toUpperCase();
			break;
		case Instruction.ARGUMENT_D16:
			opC = baseCode;
			if (arguments.matches(stringValuePattern)) {// Literal
				arg = Integer.valueOf(arguments.replace("'", ""), 16) & 0XFF;
				;
			} else {
				arg = resolveSimpleArgument(arguments, lineNumber);
			}//
			arg = arg & 0XFFFF; // mod 64K
			argStr = String.format("%04X", arg).toUpperCase();
			ans = String.format("%02X%s%s", opC, argStr.substring(2), argStr.substring(0, 2));
			break;
		case Instruction.ARGUMENT_R16D_D16:
			scannerComma = new Scanner(arguments);
			scannerComma.useDelimiter(",");
			String R16D;
			String D16;
			try {
				R16D = scannerComma.next().trim();
				D16 = scannerComma.next().trim();
			} catch (NoSuchElementException nse) {
				throw new AssemblerException("Bad argument - " + arguments + " - on line: " + lineNumber);
			}//
			if (!R16D.matches(r16dPattern)) {
				throw new AssemblerException("Bad argument - " + arguments + " - on line: " + lineNumber);
			}//
			opC = baseCode;
			registerValue = Instruction.getR16DValue(R16D);
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);

			if (D16.matches(stringValuePattern)) {// Literal
				arg = Integer.valueOf(D16.replace("'", ""), 16) & 0XFF;
				;
			} else {
				arg = resolveSimpleArgument(D16, lineNumber);
			}//
			arg = arg & 0XFFFF; // mod 64K
			argStr = String.format("%04X", arg).toUpperCase();
			ans = String.format("%02X%s%s", opC, argStr.substring(2), argStr.substring(0, 2));
			break;
		case Instruction.ARGUMENT_R8_D8:
			Scanner sc2 = new Scanner(arguments);
			sc2.useDelimiter(",");
			String R8;
			String D8;
			try {
				R8 = sc2.next().trim();
				D8 = sc2.next().trim();
			} catch (NoSuchElementException nse) {
				throw new AssemblerException("Bad argument - " + arguments + " - on line: " + lineNumber);
			}//
			if (!R8.matches(r8Pattern)) {
				throw new AssemblerException("Bad argument - " + arguments + " - on line: " + lineNumber);
			}//

			opC = baseCode;
			registerValue = Instruction.getR8Value(R8);
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);

			if (D8.matches(stringValuePattern)) {// Literal
				arg = Integer.valueOf(D8.replace("'", ""), 16) & 0XFF;
				arg = resolveSimpleArgument(D8, lineNumber);
				;
			} else {
				arg = resolveSimpleArgument(D8, lineNumber);
			}//
			ans = String.format("%02X%02x", opC, arg).toUpperCase();
			break;
		case Instruction.ARGUMENT_P8: // RST instructions
			int rv = Integer.valueOf(arguments, 16);
			registerValue = (byte) rv;
			shiftValue = instruction.getOperand1Shift();
			registerValue = (byte) (registerValue << shiftValue);
			opC = (byte) (baseCode | registerValue);
			ans = String.format("%02X", opC);
			break;
		default:

		}// switch'
		return ans;
	}

	private boolean isInstruction(String token) {
		return (instructions.containsKey(token));
	}// isInstruction

	private boolean isDirective(String token) {
		return (directives.containsKey(token));
	}// isDirective

	// private boolean isComment(String token) {
	// return token.startsWith(";");
	// }

	private void parseLine(int lineNumber, String sourceLine) {
		String workingLine = sourceLine.replaceAll("\t", " ");
		currentPC = instructionCounter.getCurrentLocation();
		clearElements();
		if (workingLine.length() == 0) {// do nothing on an empty line
			isEmptyLine = true;
			return;
		}// if - empty source line

		workingLine = checkForComment(workingLine); // check for Comment

		// comments have been removed from the working line

		if (workingLine.length() == 0) {
			return; // all done! the whole line was a comment
		}// if

		workingLine = checkForInstruction(workingLine);
		if (instruction == null) {
			workingLine = checkForDirective(workingLine, lineNumber);
		}//

		if (workingLine.length() == 0) {
			return; // all done!
		}// if

		// must be a label/name at begging of line
		workingLine = checkForSymbol(workingLine, lineNumber);

		if (workingLine.length() == 0) {
			return; // all done!
		}// if

		workingLine = checkForDirective(workingLine, lineNumber);
		if (directive == null) {
			workingLine = checkForInstruction(workingLine);
		}// if

	}// parseLine

	private String checkForComment(String lineToCheck) {
		matcher = patternForComments.matcher(lineToCheck);
		if (matcher.find()) {// looks like a comment
			comment = matcher.group();
			if (comment.contains("'")) {// is there a single quote here?
				if (lineToCheck.substring(0, matcher.start()).contains("'")) {
					comment = null;
				}// its all inside a string
			}// if single quote fund
			lineToCheck = lineToCheck.substring(0, matcher.start()).trim();
		}// if comments found
		return lineToCheck.trim();
	}// checkForComment

	private String checkForSymbol(String lineToCheck, Integer lineNumber) {
		String originalLine = lineToCheck;
		matcher = patternForLabel.matcher(lineToCheck);

		// check for labels & names
		if (matcher.lookingAt()) { // found a label
			symbol = matcher.group().replace(":", "");

			symbolTable.defineSymbol(symbol, currentPC, lineNumber, SymbolTable.LABEL);
			lineToCheck = lineToCheck.substring(matcher.end()).trim();
		} else {
			matcher = patternForName.matcher(lineToCheck);
			if (matcher.lookingAt()) {// found a name
				symbol = matcher.group().trim();
				lineToCheck = lineToCheck.substring(matcher.end()).trim();
				if (lineToCheck.startsWith("EQU")) { // equate
					lineToCheck = lineToCheck.substring(3).trim();
					arguments = lineToCheck;
					int value = resolveSimpleArgument(arguments, lineNumber);
					symbolTable.defineSymbol(symbol, value, lineNumber, SymbolTable.NAME);
					directive = directives.get("EQU");
					lineToCheck = ""; // done with this line
				} else if (lineToCheck.startsWith("SET")) { // SET
					directive = directives.get("SET");
					lineToCheck = lineToCheck.substring(3);
				} else if (lineToCheck.startsWith("MACRO")) { // Macro
					directive = directives.get("MACRO");
					lineToCheck = lineToCheck.substring(4);
				} else {
					if (!originalLine.toUpperCase().startsWith("$INCLUDE")) {
						System.out.printf("** Check line number %d text = %s%n", lineNumber, originalLine);
					}
				}// if the directive

			} else {
				// label = "     Not a Label/Name";
			}
		}// outer if
		return lineToCheck.trim();
	}// checkForSymbol

	private String checkForInstruction(String lineToCheck) {
		scanner = new Scanner(lineToCheck);
		String token = scanner.next();
		if (isInstruction(token)) { // have an instruction
			instruction = instructions.get(token);
			instructionCounter.incrementCurrentLocation(instruction.getOpCodeSize());
			arguments = (scanner.hasNext()) ? scanner.nextLine().trim() : null;
			lineToCheck = "";
		}//
		return lineToCheck;
	}// checkForInstructions

	/*
	 * EQU,SET and MACRO are handled in the checkForSymbol.
	 */
	private String checkForDirective(String lineToCheck, int lineNumber) {
		scanner = new Scanner(lineToCheck);
		String token = scanner.next();
		String errorMsg = String.format("Directive %s on line: %04d not yet implemented", token, lineNumber);
		// if (isDirective(token)) { // have a directive
		if (isDirective(token)) {
			directive = directives.get(token);
			arguments = (scanner.hasNext()) ? scanner.nextLine().trim() : null;
			switch (token) {
			case "DB":
				if (arguments == null) {
					throw new AssemblerException("DB on line: " + lineNumber + " needs an argument");
				} else {
					String arg;
					scannerComma = new Scanner(arguments);
					scannerComma.useDelimiter(",");
					while (scannerComma.hasNext()) {
						arg = scannerComma.next();
						if (arg.matches(stringValuePattern)) {// Literal
							arg = arg.replace("'", "");
							instructionCounter.incrementCurrentLocation(arg.length());
						} else { // expression
							instructionCounter.incrementCurrentLocation();
						}//
					}// while
				}// if - arguments null
				lineToCheck = "";
				break;
			case "DW":
				if (arguments == null) {
					throw new AssemblerException("DW on line: " + lineNumber + " needs an argument");
				} else {
					String arg;
					scannerComma = new Scanner(arguments);
					scannerComma.useDelimiter(",");
					while (scannerComma.hasNext()) {
						arg = scannerComma.next();
						instructionCounter.incrementCurrentLocation(2);
					}// while
				}// if - arguments null
				lineToCheck = "";
				break;
			case "DS":
				int storage = resolveSimpleArgument(arguments, lineNumber);
				instructionCounter.incrementCurrentLocation(storage);
				break;
			case "ORG":
				Integer loc = resolveSimpleArgument(arguments, lineNumber);
				if (loc != null) {
					instructionCounter.setCurrentLocation(loc);
					instructionCounter.setPriorLocation();
				}// set if valid else leave alone
				lineToCheck = ""; // done with this line
				break;
			case "ASEG":
				if (arguments == null) {
					instructionCounter.makeCurrent(InstructionCounter.ASEG);
				} else {
					instructionCounter.makeCurrent(InstructionCounter.ASEG, arguments);
				}// if
				break;
			case "DSEG":
				if (arguments == null) {
					instructionCounter.makeCurrent(InstructionCounter.DSEG);
				} else {
					instructionCounter.makeCurrent(InstructionCounter.DSEG, arguments);
				}// if
				break;
			case "CSEG":
				if (arguments == null) {
					instructionCounter.makeCurrent(InstructionCounter.CSEG);
				} else {
					instructionCounter.makeCurrent(InstructionCounter.CSEG, arguments);
				}// if
				break;
			case "IF":
				throw new AssemblerException(errorMsg);
				// break;
			case "ELSE":
				throw new AssemblerException(errorMsg);
				// break;
			case "ENDIF":
				throw new AssemblerException(errorMsg);
				// break;
			case "END":
				// Ignore
				// System.err.println(errorMsg);
				break;
			case "PUBLIC":
				throw new AssemblerException(errorMsg);
				// break;
			case "EXTRN":
				throw new AssemblerException(errorMsg);
				// break;
			case "NAME":
				throw new AssemblerException(errorMsg);
				// break;
			case "STKLN":
				throw new AssemblerException(errorMsg);
				// break;
			case "TITLE":
				// ignore
				comment = lineToCheck;
				lineToCheck = "";
				break;
			default:
				// Ignore
			}// switch for directives

		}
		return lineToCheck.trim();
	}// checkForDirective

	private Integer resolveSimpleArgument(String argument, Integer lineNumber) {
		// Integer ans = null;
		Integer ans = 0;
		if (argument.equals("$")) {
			ans = currentPC;
		} else if (symbolTable.contains(argument)) {
			ans = symbolTable.getValue(argument);
			symbolTable.referenceSymbol(argument, lineNumber);
		} else if (argument.matches(stringValuePattern)) {
			// ans = 0;
			String s = argument.replace("'", ""); // remove the 's
			byte[] ba = s.getBytes();
			for (byte b : ba) {
				ans = (ans << 8) + (b & 0XFF);
			}//

		} else if (argument.matches(hexValuePattern)) {
			ans = Integer.valueOf(argument.replace("H", ""), 16);
		} else if (argument.matches(octalValuePattern)) {
			ans = Integer.valueOf(argument.substring(0, argument.length() - 1), 8);
		} else if (argument.matches(decimalValuePattern)) {
			ans = Integer.valueOf(argument.replace("D", ""), 10);
		} else if (argument.matches(binaryValuePattern)) {
			ans = Integer.valueOf(argument.replace("D", ""), 2);

		} else {// send to expression resolver
			ans = resolveExpression(argument, lineNumber);
		}
		if (ans == null) {
			System.out.printf("Null ans from argument: %s%n", argument);
		}

		return (ans != null) ? ans & 0XFFFF : 0; // max value is 64K
	}// resolveSimpleArgument

	private Integer resolveExpression(String arguments, Integer lineNumber) {
		Integer answer = null;
		try {
			tokenizer.tokenize(arguments);
			ExpressionNode expression = parser.parse(tokenizer.getTokens());
			LinkedList<Token> tokens = tokenizer.getTokens();

			for (Token t : tokens) {
				if (t.token == Token.VARIABLE) {
					int value = symbolTable.getValue(t.sequence);
					symbolTable.referenceSymbol(t.sequence, lineNumber);

					expression.accept(new SetVariable(t.sequence, value));
				}// if - its a variable
			}
			answer = expression.getValue();
		} catch (ParserException pe) {
			System.err.println(pe.getMessage());
			throw new AssemblerException("bad Expression: " + arguments);
		} catch (EvaluationException ee) {
			System.err.println(ee.getMessage());
			throw new AssemblerException("bad Expression: " + arguments);
		}// try
		return answer;
	}// resolveExpression

	private void clearElements() {
		isEmptyLine = false; // ?
		symbol = null;
		// isInstruction = false; // ?
		directive = null;
		instruction = null;
		arguments = null;
		comment = null;
	}// clearElements

	private String replaceWithListingFileName(String fileName) {
		String[] fileNameParts;
		String suffix;
		fileNameParts = fileName.split("\\.");
		switch (fileNameParts[1]) {
		case "asm":
			suffix = ".list";
			break;
		case "ASM":
			suffix = ".LIST";
			break;
		case "Asm":
			suffix = ".List";
			break;
		default:
			suffix = ".list";
		}// switch

		return fileNameParts[0] + suffix;

	}// replaceFileType

	@Override
	public void adjustmentValueChanged(AdjustmentEvent ae) {
		if (((Component) ae.getSource()).getName() == "verticalScrollBar") {
			scrollListing.getVerticalScrollBar().setValue(scrollSource.getVerticalScrollBar().getValue());
		}// if - the left scroll pane
	}// adjustmentValueChanged

	private JFileChooser getFileChooser(String directory, String filterDescription, String filterExtensions) {
		JFileChooser chooser = new JFileChooser(directory);
		chooser.setMultiSelectionEnabled(false);
		chooser.addChoosableFileFilter(new FileNameExtensionFilter(filterDescription, filterExtensions));
		chooser.setAcceptAllFileFilterUsed(false);
		return chooser;
	}// getFileChooser

	@Override
	public void actionPerformed(ActionEvent ae) {
		String action = ae.getActionCommand();
		switch (action) {
		case "mnuFileOpen":
			JFileChooser chooserOpen = getFileChooser(defaultDirectory, "Assembler Source Code", ASSEMBLER_SUFFIX);
			if (chooserOpen.showOpenDialog(frame) != JFileChooser.APPROVE_OPTION) {
				System.out.println("You cancelled the file open%n");
			} else {
				txtSource.setText("");
				txtListing.setText("");
				asmSourceFile = chooserOpen.getSelectedFile();
				String sourceFileName = asmSourceFile.getName();
				defaultDirectory = asmSourceFile.getParent();
				frame.setTitle(defaultDirectory);
				lblSource.setText(sourceFileName);
				lblListing.setText(replaceWithListingFileName(sourceFileName));
				btnStart.setEnabled(true);
			}//
			break;
		case "btnStart":
			instructionCounter.reset();
			symbolTable.reset();
			if (asmSourceFile != null) {
				txtSource.setText("");
				txtListing.setText("");
				lineNumber = 0;

				passZero(asmSourceFile);
				passOne();
				passTwo(asmSourceFile);
				// passOne(asmSourceFile);
				// passTwo(asmSourceFile);
			}// if
			break;
		case "btnTest":
			HashMap<String, SymbolTableEntry> symbols = symbolTable.getTableEntries();
			Set<String> keys = symbols.keySet();
			List<String> list = asSortedList(keys); // *******************************
													// see below
			ArrayList<Integer> refLines;
			StringBuilder sb;
			char fistLetter = 00;
			for (String key : list) {
				SymbolTableEntry entry = symbols.get((String) key);
				String name = entry.getName();
				if (fistLetter != name.charAt(0)) {
				}
				fistLetter = name.charAt(0);
				int value = entry.getValue();
				int lineNumber = entry.getDefinedLineNumber();
				refLines = entry.getReferencedLineNumbers();
				sb = new StringBuilder();
				for (int refLine : refLines) {
					sb.append(String.format(" %04d", refLine));
				}// for - reference line numbers
				String logEntry = String.format("%04d\t%04X\t%-30s\t\t%s%n", lineNumber, value, name, sb.toString());
				sb = null;
			}// for
			break;
		default:
		}// switch
	}// actionPerformed

	public void appInit() {
		passOneList = new LinkedList<PassOne>();
		instructionCounter = new InstructionCounter();
		instruction = new Instruction();
		symbolTable = new SymbolTable(instructionCounter);
		memoryImage = new HashMap<Integer, Byte>();
		tokenizer = new Tokenizer();
		parser = new Parser();
		String labelPattern = "^[$\\?\\@\\w][\\w$]{1,25}:"; // "^[$\\?\\@\\w][\\w$]{1,8}:"
		patternForLabel = Pattern.compile(labelPattern);
		String namePattern = "^[$\\?\\@\\w][\\w$]{1,25}\\s|[$\\?\\@\\w][\\w$]{1,25}$"; // "^[$\\?\\@\\w][\\w$]{1,8}\\s|[$\\?\\@\\w][\\w$]{1,8}$"
		patternForName = Pattern.compile(namePattern);
		String commentsPattern = ";.*";
		patternForComments = Pattern.compile(commentsPattern);
		r8r8Pattern = "[ABCDEHLM],[ABCDEHLM]";
		r16dPattern = "B|BC|D|DE|H|HL|SP";
		r8Pattern = "A|B|C|D|E|H|L|M";
		patternForInclude = Pattern.compile("\\$INCLUDE ", Pattern.CASE_INSENSITIVE);
		patternForLineNumber = Pattern.compile("^\\d{4}\\s");

		Path sourcePath = Paths.get(FILE_LOCATION, "Code");
		defaultDirectory = sourcePath.resolve(FILE_LOCATION).toString();
		frame.setTitle(defaultDirectory);

		lblSource = new JLabel("No File");
		lblSource.setHorizontalAlignment(SwingConstants.CENTER);
		lblSource.setFont(new Font("Courier New", Font.BOLD, 16));
		lblSource.setForeground(Color.BLUE);
		scrollSource.setColumnHeaderView(lblSource);

		lblListing = new JLabel("No File");
		lblListing.setHorizontalAlignment(SwingConstants.CENTER);
		lblListing.setFont(new Font("Courier New", Font.BOLD, 16));
		lblListing.setForeground(Color.BLUE);
		scrollListing.setColumnHeaderView(lblListing);
		txtSource.setTabSize(4);
		txtListing.setTabSize(4);

	}// appInit
		// --------------------------------------------------------------------------------//

	/**
	 * Create the application.
	 */
	public ASM_1_0() {
		initialize();

		appInit();
	}// Constructor - ASM1()

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frame = new JFrame();
		frame.setBounds(100, 100, 1291, 715);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		GridBagLayout gridBagLayout = new GridBagLayout();
		gridBagLayout.columnWidths = new int[] { 108, 600, 0, 0 };
		gridBagLayout.rowHeights = new int[] { 32, 612, 0 };
		gridBagLayout.columnWeights = new double[] { 0.0, 1.0, 0.0, Double.MIN_VALUE };
		gridBagLayout.rowWeights = new double[] { 0.0, 1.0, Double.MIN_VALUE };
		frame.getContentPane().setLayout(gridBagLayout);

		JPanel panel1 = new JPanel();
		GridBagConstraints gbc_panel1 = new GridBagConstraints();
		gbc_panel1.fill = GridBagConstraints.BOTH;
		gbc_panel1.insets = new Insets(0, 0, 0, 5);
		gbc_panel1.gridx = 0;
		gbc_panel1.gridy = 1;
		frame.getContentPane().add(panel1, gbc_panel1);
		panel1.setLayout(null);

		btnStart = new JButton("Start");
		btnStart.setEnabled(false);
		btnStart.setActionCommand("btnStart");
		btnStart.addActionListener(this);
		btnStart.setBounds(10, 25, 89, 23);
		panel1.add(btnStart);

		JButton btnTest = new JButton("Xref");
		btnTest.setVisible(false);
		btnTest.setEnabled(false);
		btnTest.setActionCommand("btnTest");
		btnTest.addActionListener(this);
		btnTest.setBounds(10, 568, 89, 33);
		panel1.add(btnTest);

		cbSaveToFile = new JCheckBox("Save To File");
		cbSaveToFile.setSelected(true);
		cbSaveToFile.setBounds(10, 77, 97, 23);
		panel1.add(cbSaveToFile);

		JSplitPane splitPane = new JSplitPane();
		splitPane.setDividerSize(10);
		splitPane.setOneTouchExpandable(true);
		GridBagConstraints gbc_splitPane = new GridBagConstraints();
		gbc_splitPane.insets = new Insets(0, 0, 0, 5);
		gbc_splitPane.fill = GridBagConstraints.BOTH;
		gbc_splitPane.gridx = 1;
		gbc_splitPane.gridy = 1;
		frame.getContentPane().add(splitPane, gbc_splitPane);

		scrollSource = new JScrollPane();
		scrollSource.getVerticalScrollBar().addAdjustmentListener(this);
		splitPane.setLeftComponent(scrollSource);

		txtSource = new JTextArea();

		scrollSource.setViewportView(txtSource);

		scrollListing = new JScrollPane();
		scrollListing.getVerticalScrollBar().addAdjustmentListener(this);
		splitPane.setRightComponent(scrollListing);

		txtListing = new JTextArea();
		scrollListing.setViewportView(txtListing);
		splitPane.setDividerLocation(500);

		JMenuBar menuBar = new JMenuBar();
		frame.setJMenuBar(menuBar);

		JMenu mnuFile = new JMenu("File");
		menuBar.add(mnuFile);

		JMenuItem mnuFileOpen = new JMenuItem("Open...");
		mnuFileOpen.setActionCommand("mnuFileOpen");
		mnuFileOpen.addActionListener(this);
		mnuFile.add(mnuFileOpen);

		// initApplication();
	}// initialize

	// TODO reserved word END

	// TODO reserved words STACK and MEMORY pg 4-19 assembler MAY_81 pdf
	private static HashMap<String, Directive> directives;
	static {
		directives = new HashMap<String, Directive>();
		directives.put("EQU", new Directive("EQU", true, 1, false));
		directives.put("SET", new Directive("SET", true, 1, false));
		directives.put("DB", new Directive("DB", false, 8, true));
		directives.put("DW", new Directive("DW", false, 8, true));
		directives.put("DS", new Directive("DS", false, 1, false));

		directives.put("IF", new Directive("IF", false, 1, false));
		directives.put("ELSE", new Directive("ELSE", false, 0, false));
		directives.put("ENDIF", new Directive("ENDIF", false, 0, false));

		directives.put("END", new Directive("END", false, 1, false));
		directives.put("EOT", new Directive("EOT", false, 0, false)); // obsolete

		directives.put("ORG", new Directive("ORG", false, 1, false));
		directives.put("ASEG", new Directive("ASEG", false, 0, false));
		directives.put("CSEG", new Directive("CSEG", false, 1, false)); // blank,PAGE,INPAGE
		directives.put("DSEG", new Directive("DSEG", false, 1, false)); // blank,PAGE,INPAGE

		directives.put("PUBLIC", new Directive("PUBLIC", false, 1, false)); // name-List
		directives.put("EXTRN", new Directive("EXTRN", false, 1, false)); // name-List
		directives.put("NAME", new Directive("NAME", false, 1, false)); // Name for the module

		directives.put("STKLN", new Directive("STKLN", false, 1, false)); // name-List

		directives.put("MACRO", new Directive("MACRO", true, 8, false));
		directives.put("ENDM", new Directive("ENDM", true, 0, false));
		directives.put("LOCAL", new Directive("LOCAL", true, 8, false)); // label-names
		directives.put("REPT", new Directive("REPT", true, 1, false));
		directives.put("IRP", new Directive("IRP", true, 1, false)); // list
		// of
		// dummy
		// parameters
		directives.put("IRPC", new Directive("IRPC", true, 1, false)); // list
		directives.put("EXITM", new Directive("EXITM", true, 0, false));
	}// static
	private static HashMap<String, Instruction> instructions;
	static {
		instructions = new HashMap<String, Instruction>();

		instructions.put("CMC", new Instruction("CMC", 1, (byte) 0X3F, Instruction.ARGUMENT_NONE));
		instructions.put("STC", new Instruction("STC", 1, (byte) 0X37, Instruction.ARGUMENT_NONE));
		instructions.put("INR", new Instruction("INR", 1, (byte) 0X04, Instruction.ARGUMENT_R8, 3)); // INC
		instructions.put("DCR", new Instruction("DCR", 1, (byte) 0X05, Instruction.ARGUMENT_R8, 3));
		instructions.put("CMA", new Instruction("CMA", 1, (byte) 0X2F, Instruction.ARGUMENT_NONE));
		instructions.put("DAA", new Instruction("DAA", 1, (byte) 0X27, Instruction.ARGUMENT_NONE));
		instructions.put("NOP", new Instruction("NOP", 1, (byte) 0X00, Instruction.ARGUMENT_NONE));
		instructions.put("HLT", new Instruction("HLT", 1, (byte) 0X76, Instruction.ARGUMENT_NONE));

		instructions.put("MOV", new Instruction("MOV", 1, (byte) 0X40, Instruction.ARGUMENT_R8_R8, 3, 0));
		instructions.put("STAX", new Instruction("STAX", 1, (byte) 0X02, Instruction.ARGUMENT_R16D, 4)); // TODO
		instructions.put("LDAX", new Instruction("LDAX", 1, (byte) 0X0A, Instruction.ARGUMENT_R16D, 4)); // TODO

		instructions.put("ADD", new Instruction("ADD", 1, (byte) 0X80, Instruction.ARGUMENT_R8, 0));
		instructions.put("ADC", new Instruction("ADC", 1, (byte) 0X88, Instruction.ARGUMENT_R8, 0));
		instructions.put("SUB", new Instruction("SUB", 1, (byte) 0X90, Instruction.ARGUMENT_R8, 0));
		instructions.put("SBB", new Instruction("SBB", 1, (byte) 0X98, Instruction.ARGUMENT_R8, 0));
		instructions.put("ANA", new Instruction("ANA", 1, (byte) 0XA0, Instruction.ARGUMENT_R8, 0));
		instructions.put("XRA", new Instruction("XRA", 1, (byte) 0XA8, Instruction.ARGUMENT_R8, 0));
		instructions.put("ORA", new Instruction("ORA", 1, (byte) 0XB0, Instruction.ARGUMENT_R8, 0));
		instructions.put("CMP", new Instruction("CMP", 1, (byte) 0XB8, Instruction.ARGUMENT_R8, 0));

		instructions.put("RRC", new Instruction("RRC", 1, (byte) 0X0F, Instruction.ARGUMENT_NONE));
		instructions.put("RLC", new Instruction("RLC", 1, (byte) 0X07, Instruction.ARGUMENT_NONE));
		instructions.put("RAL", new Instruction("RAL", 1, (byte) 0X17, Instruction.ARGUMENT_NONE));
		instructions.put("RAR", new Instruction("RAR", 1, (byte) 0X1F, Instruction.ARGUMENT_NONE));

		instructions.put("PUSH", new Instruction("PUSH", 1, (byte) 0XC5, Instruction.ARGUMENT_R16Q, 4));
		instructions.put("POP", new Instruction("POP", 1, (byte) 0XC1, Instruction.ARGUMENT_R16Q, 4));
		instructions.put("DAD", new Instruction("DAD", 1, (byte) 0X09, Instruction.ARGUMENT_R16D, 4));
		instructions.put("INX", new Instruction("INX", 1, (byte) 0X03, Instruction.ARGUMENT_R16D, 4));
		instructions.put("DCX", new Instruction("DCX", 1, (byte) 0X0B, Instruction.ARGUMENT_R16D, 4));

		instructions.put("XCHG", new Instruction("XCHG", 1, (byte) 0XEB, Instruction.ARGUMENT_NONE));
		instructions.put("XTHL", new Instruction("XTHL", 1, (byte) 0XE3, Instruction.ARGUMENT_NONE));
		instructions.put("SPHL", new Instruction("SPHL", 1, (byte) 0XF9, Instruction.ARGUMENT_NONE));
		instructions.put("PCHL", new Instruction("PCHL", 1, (byte) 0XE9, Instruction.ARGUMENT_NONE));

		instructions.put("LXI", new Instruction("LXI", 3, (byte) 0X01, Instruction.ARGUMENT_R16D_D16, 4));
		instructions.put("MVI", new Instruction("MVI", 2, (byte) 0X06, Instruction.ARGUMENT_R8_D8, 3));
		instructions.put("ADI", new Instruction("ADI", 2, (byte) 0XC6, Instruction.ARGUMENT_D8));
		instructions.put("ACI", new Instruction("ACI", 2, (byte) 0XCE, Instruction.ARGUMENT_D8));
		instructions.put("SUI", new Instruction("SUI", 2, (byte) 0XD6, Instruction.ARGUMENT_D8));
		instructions.put("SBI", new Instruction("SBI", 2, (byte) 0XDE, Instruction.ARGUMENT_D8));
		instructions.put("ANI", new Instruction("ANI", 2, (byte) 0XE6, Instruction.ARGUMENT_D8));
		instructions.put("XRI", new Instruction("XRI", 2, (byte) 0XEE, Instruction.ARGUMENT_D8));
		instructions.put("ORI", new Instruction("ORI", 2, (byte) 0XF6, Instruction.ARGUMENT_D8));
		instructions.put("CPI", new Instruction("CPI", 2, (byte) 0XFE, Instruction.ARGUMENT_D8));

		instructions.put("STA", new Instruction("STA", 3, (byte) 0X32, Instruction.ARGUMENT_D16));
		instructions.put("LDA", new Instruction("LDA", 3, (byte) 0X3A, Instruction.ARGUMENT_D16));
		instructions.put("SHLD", new Instruction("SHLD", 3, (byte) 0X22, Instruction.ARGUMENT_D16));
		instructions.put("LHLD", new Instruction("LHLD", 3, (byte) 0X2A, Instruction.ARGUMENT_D16));

		instructions.put("JMP", new Instruction("JMP", 3, (byte) 0XC3, Instruction.ARGUMENT_D16));
		instructions.put("JNZ", new Instruction("JNZ", 3, (byte) 0XC2, Instruction.ARGUMENT_D16));
		instructions.put("JZ", new Instruction("JZ", 3, (byte) 0XCA, Instruction.ARGUMENT_D16));
		instructions.put("JNC", new Instruction("JNC", 3, (byte) 0XD2, Instruction.ARGUMENT_D16));
		instructions.put("JC", new Instruction("JC", 3, (byte) 0XDA, Instruction.ARGUMENT_D16));
		instructions.put("JPO", new Instruction("JPO", 3, (byte) 0XE2, Instruction.ARGUMENT_D16));
		instructions.put("JPE", new Instruction("JPE", 3, (byte) 0XEA, Instruction.ARGUMENT_D16));
		instructions.put("JP", new Instruction("JP", 3, (byte) 0XF2, Instruction.ARGUMENT_D16));
		instructions.put("JM", new Instruction("JM", 3, (byte) 0XFA, Instruction.ARGUMENT_D16));

		instructions.put("CALL", new Instruction("CALL", 3, (byte) 0XCD, Instruction.ARGUMENT_D16));
		instructions.put("CNZ", new Instruction("CNZ", 3, (byte) 0XC4, Instruction.ARGUMENT_D16));
		instructions.put("CZ", new Instruction("CZ", 3, (byte) 0XCC, Instruction.ARGUMENT_D16));
		instructions.put("CNC", new Instruction("CNC", 3, (byte) 0XD4, Instruction.ARGUMENT_D16));
		instructions.put("CC", new Instruction("CC", 3, (byte) 0XDC, Instruction.ARGUMENT_D16));
		instructions.put("CPO", new Instruction("CPO", 3, (byte) 0XE4, Instruction.ARGUMENT_D16));
		instructions.put("CPE", new Instruction("CPE", 3, (byte) 0XEC, Instruction.ARGUMENT_D16));
		instructions.put("CP", new Instruction("CP", 3, (byte) 0XF4, Instruction.ARGUMENT_D16));
		instructions.put("CM", new Instruction("CM", 3, (byte) 0XFC, Instruction.ARGUMENT_D16));

		instructions.put("RET", new Instruction("RET", 1, (byte) 0XC9, Instruction.ARGUMENT_NONE));
		instructions.put("RNZ", new Instruction("RNZ", 1, (byte) 0XC0, Instruction.ARGUMENT_NONE));
		instructions.put("RZ", new Instruction("RZ", 1, (byte) 0XC8, Instruction.ARGUMENT_NONE));
		instructions.put("RNC", new Instruction("RNC", 1, (byte) 0XD0, Instruction.ARGUMENT_NONE));
		instructions.put("RC", new Instruction("RC", 1, (byte) 0XD8, Instruction.ARGUMENT_NONE));
		instructions.put("RPO", new Instruction("RPO", 1, (byte) 0XE0, Instruction.ARGUMENT_NONE));
		instructions.put("RPE", new Instruction("RPE", 1, (byte) 0XE8, Instruction.ARGUMENT_NONE));
		instructions.put("RP", new Instruction("RP", 1, (byte) 0XF0, Instruction.ARGUMENT_NONE));
		instructions.put("RM", new Instruction("RM", 1, (byte) 0XF8, Instruction.ARGUMENT_NONE));

		instructions.put("RST", new Instruction("RST", 1, (byte) 0XC7, Instruction.ARGUMENT_P8, 3));

		instructions.put("EI", new Instruction("EI", 1, (byte) 0XFB, Instruction.ARGUMENT_NONE));
		instructions.put("DI", new Instruction("DI", 1, (byte) 0XF3, Instruction.ARGUMENT_NONE));

		instructions.put("IN", new Instruction("IN", 2, (byte) 0XDB, Instruction.ARGUMENT_D8));
		instructions.put("OUT", new Instruction("OUT", 2, (byte) 0XD3, Instruction.ARGUMENT_D8));
	}// static

	private static final String hexValuePattern = "[0-9][0-9A-Fa-f]{0,4}H";
	private static final String octalValuePattern = "[0-7]+[O|Q]";
	private static final String binaryValuePattern = "[01]B";
	private static final String decimalValuePattern = "[0-9]{1,4}D?+";
	private static final String stringValuePattern = "\\A'.*'\\z"; // used for

	public final static String FILE_LOCATION = ".";
	private final static String CODE = "Code";
	public final static String ASSEMBLER_SUFFIX = "asm";
	private JTextArea txtSource;
	private JTextArea txtListing;
	private JScrollPane scrollSource;
	private JScrollPane scrollListing;
	JLabel lblSource;
	JLabel lblListing;
}// class ASM1
