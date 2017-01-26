package assembler;

import java.awt.Point;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LineParser {
	String arguments;
	String comment;
	String directive;
	String instruction;
	String label;
	String lineNumberStr;
	String name;
	int operandType;
	int operand1Shift;
	int operand2Shift;
	byte baseCode;
	int opCodeSize;

	boolean activeLine;
	boolean onlyComment;

	public LineParser() {

	}// Constructor

	public boolean isActiveLine() {
		return this.activeLine;
	}// isActiveLine

	public boolean hasArgument() {
		return this.arguments != null;
	}// hasArgument

	public String getArgument() {
		return hasArgument() ? this.arguments : EMPTY_STRING;
	}// getArgument

	public boolean isOnlyComment() {
		return this.onlyComment;
	}// isOnlyComment

	public boolean hasComment() {
		return this.comment != null;
	}// hasComment

	public String getComment() {
		return hasComment() ? this.comment : EMPTY_STRING;
	}// getComment

	public boolean hasDirective() {
		return this.directive != null;
	}// hasDirective

	public String getDirective() {
		return hasDirective() ? this.directive : EMPTY_STRING;
	}// getDirective

	public boolean hasInstruction() {
		return this.instruction != null;
	}// hasInstruction

	public String getInstruction() {
		return hasInstruction() ? this.instruction : EMPTY_STRING;
	}// getInstruction

	public boolean hasLabel() {
		return this.label != null;
	}// hasLabel

	public String getLabel() {
		return hasLabel() ? this.label : EMPTY_STRING;
	}// getLabel

	public boolean hasLineNumber() {
		return this.lineNumberStr != null;
	}// hasLineNumber

	public String getLineNumberStr() {
		return hasLineNumber() ? this.lineNumberStr : EMPTY_STRING;
	}// getLineNumberStr

	public int getLineNumber() {
		int ln = hasLineNumber() ? Integer.valueOf(this.lineNumberStr, 10) : -1;
		return ln;
	}// getLineNumberInt

	public boolean hasName() {
		return this.name != null;
	}// hasName

	public String getName() {
		return hasName() ? this.name : EMPTY_STRING;
	}// getName

	public int getOpCodeSize() {
		return this.opCodeSize;
	}// getOpCodeSize

	public int getOperandType() {
		return this.operandType;
	}// getOperandType

	public int getOperand1Shift() {
		return this.operand1Shift;
	}// getOperand1Shift

	public int getOperand2Shift() {
		return this.operand2Shift;
	}// getOperand2Shift

	public byte getBaseCode() {
		return this.baseCode;
	}// getBaseCode

	private void resetAtttributes() {
		this.arguments = null;
		this.comment = null;
		this.directive = null;
		this.label = null;
		this.lineNumberStr = null;
		this.instruction = null;
		this.name = null;

		this.opCodeSize = 0;
		this.operandType = Instruction.ARGUMENT_NONE;
		this.operand1Shift = 0;
		this.operand2Shift = 0;
		this.baseCode = (byte) 0X00;

		this.activeLine = false;
		this.onlyComment = false;
	}// clear

	/**
	 * parses the source line and identifies the its components
	 * 
	 * @param sourceLine
	 * @return
	 */

	public boolean parse(String sourceLine) {
		String workingLine = new String(sourceLine);

		// String workingLine = sourceLine.replaceAll("\t", SPACE);
		resetAtttributes();
		if (workingLine.trim().length() == 0) {
			activeLine = false;
			return activeLine;
		} // if
		activeLine = true;

		workingLine = findLineNumber(workingLine);
		if (workingLine.length() == 0)
			return this.activeLine;
		/* no line Number */
		workingLine = findComment(workingLine);
		/* no comment, line number */
		workingLine = findLabel(workingLine);
		if (workingLine.length() == 0)
			return this.activeLine;
		/* no label,comment,line number */
		workingLine = findInstruction(workingLine);
		if (workingLine.length() == 0)
			return this.activeLine;

		/* no instruction ( its args), labels.comments,line numbers */
		/* only a directive line {Name} Directive {Arguments} */

		workingLine = findDirective(workingLine);

		if (workingLine.length() == 0)
			return this.activeLine;
		System.err.printf("Ins: %6s, Dir: %6s, workingLine: %s%n", instruction, directive, workingLine);
		return this.activeLine;
	}// parse



	private String findDirective(String workingLine) {
		String netLine = new String(workingLine).trim();
		this.directive = null;
		String compoundRegex = "('[^']*')|(" + DirectiveSet.getRegex() + ")";

		Pattern patternForDirectives = Pattern.compile(compoundRegex);
		Matcher matcherForDirective = patternForDirectives.matcher(netLine);

		if (matcherForDirective.find()) {
			if ((matcherForDirective.group(1) == null) && (matcherForDirective.group(2) != null)) {
				this.directive = matcherForDirective.group();
				this.arguments = (matcherForDirective.end() < netLine.length())
						? netLine.substring(matcherForDirective.end(), netLine.length()).trim() : null;

				String possibleName = netLine.substring(0, matcherForDirective.start());
				Pattern patternForName = Pattern.compile("[\\@\\?A-Za-z]{1}\\w{1,25}\\s");
				Matcher matcherForName = patternForName.matcher(possibleName);
				this.name = matcherForName.find() ? matcherForName.group().trim() : null;
				netLine = EMPTY_STRING;
			}
		} // outer if
		return netLine;
	}// findDirective


	private String findInstruction(String workingLine) {
		String netLine = new String(workingLine).trim();
		this.instruction = null;
		this.opCodeSize = 0;
		// this.arguments = null;
		this.operandType = Instruction.ARGUMENT_NONE;
		this.operand1Shift = 0;
		this.operand2Shift = 0;
		this.baseCode = (byte) 0X00;
		String compoundRegex = "('[^']*')|(" + InstructionSet.getRegex() + ")";
		Pattern patternForInstructions = Pattern.compile(compoundRegex);
		Matcher matcherForInstruction = patternForInstructions.matcher(netLine);

		if (matcherForInstruction.find()) {
			if ((matcherForInstruction.group(1) == null) && (matcherForInstruction.group(2) != null)) {
				this.instruction = matcherForInstruction.group().toUpperCase();
				// this.arguments = (matcher.end() < netLine.length())
				// ? netLine.substring(matcher.end(), netLine.length() - matcher.end()) : null;
				this.arguments = (matcherForInstruction.end() < netLine.length())
						? netLine.substring(matcherForInstruction.end(), netLine.length()).trim() : null;
				this.opCodeSize = InstructionSet.getOpCodeSize(this.instruction);
				this.operandType = InstructionSet.getOperandType(this.instruction);
				this.operand1Shift = InstructionSet.getOperand1Shift(this.instruction);
				this.operand2Shift = InstructionSet.getOperand2Shift(this.instruction);
				this.baseCode = InstructionSet.getBaseCode(this.instruction);
				netLine = EMPTY_STRING;
			} // inner if - it is an instruction
		} // outer if instruction found
		return netLine;

	}// findInstruction

	private String findSymbol(String workingLine) {
		String netLine = new String(workingLine).trim();
		this.label = null;
		this.name = null;
		Pattern patternForLabel = Pattern.compile("^[$\\?\\@\\w][\\w$]{1,25}:");
		matcher = patternForLabel.matcher(netLine);
		Pattern patternForName = Pattern.compile("^[$\\?\\@\\w][\\w$]{1,25}\\s|[$\\?\\@\\w][\\w$]{1,25}\b");

		Matcher matcherName = patternForName.matcher(netLine);
		if (matcher.lookingAt()) {
			label = matcher.group().trim();
			label = label.replaceAll(":", EMPTY_STRING);
			netLine = matcher.replaceFirst(EMPTY_STRING);
		} else if (matcherName.lookingAt()) {
			name = matcherName.group().trim();
			netLine = matcherName.replaceFirst(EMPTY_STRING);
		} // if Label or Name
		return netLine.trim();
	}// findLabel

	private String findComment1(String workingLine) {
		this.comment = null;
		String netLine = new String(workingLine);
		if (!netLine.contains(";")) {
			return netLine; /* no comments */
		} // if

		Pattern patternForComment = Pattern.compile("('[^']*')|(;)");
		Matcher matcherForComment = patternForComment.matcher(netLine);
		int startFindLoc = 0;
		while (!matcherForComment.hitEnd()) {
			if (matcherForComment.find(startFindLoc)) {
				if ((matcherForComment.group(1) == null) && (matcherForComment.group(2) != null)) {
					comment = netLine.substring(matcherForComment.end(2) - 1);
					netLine = netLine.substring(0, matcherForComment.end(2) - 1);
					break; // found the comment
				} // if this is it
				startFindLoc = Math.max(matcherForComment.end(1), matcherForComment.end(2));
			} // if any match
		} // while
		return netLine.trim();
	}// findComment1

	private String findComment(String workingLine) {
		return findComment1(workingLine);
		// String netLine = new String(workingLine);
		// this.comment = null;
		// Pattern patternForComment = Pattern.compile(";.*");
		// matcher = patternForComment.matcher(netLine);
		//
		// if (!netLine.contains(COMMENT_CHAR)) {
		// /* just return the line - no comments here */
		// } else if (matcher.lookingAt()) {
		// comment = netLine;
		// netLine = EMPTY_STRING;
		// this.onlyComment = true;
		// } else if (!netLine.contains(SINGLE_QUOTE)) {
		// matcher.reset();
		// matcher.find();
		// comment = matcher.group();
		// netLine = matcher.replaceFirst(EMPTY_STRING);
		// /* simple comment */
		// } else {
		// Integer commentCharIndex = netLine.indexOf(COMMENT_CHAR);
		// Queue<Integer> commentCharIndexes = new LinkedList<Integer>();
		//
		// while (commentCharIndex != -1) {
		// commentCharIndexes.add(commentCharIndex);
		// commentCharIndex = netLine.indexOf(COMMENT_CHAR, commentCharIndex + 1);
		// } // while - get all COMMENT_CHARs
		//
		// /* if there are quotes, there might be literal commentChars */
		// Queue<Point> quotePairs = new LinkedList<Point>();
		// matcher = patternInQuotes.matcher(netLine);
		// while (matcher.find()) {
		// quotePairs.add(new Point(matcher.start(), matcher.end() - 1));
		// } // while
		//
		// boolean commentFound = true;
		// Integer targetIndex = -1;
		// Iterator indexIterator = commentCharIndexes.iterator();
		// while (indexIterator.hasNext()) {
		// commentFound = true;
		// targetIndex = (Integer) indexIterator.next();
		// for (Point p : quotePairs) {
		// if (inRange(targetIndex, p)) {
		// commentFound = false; /* comment char in quotes */
		// continue;
		// } // if in range
		// } // for points
		// if (commentFound) {
		// break;
		// } // get outta here
		// } // while
		//
		// if (commentFound) {
		// comment = workingLine.substring(targetIndex, workingLine.length());
		// netLine = workingLine.substring(0, targetIndex);
		// } // if there is a comment
		// } // if
		//
		// return netLine.trim();

	}// findComment

	private boolean inRange(int testValue, Point limits) {
		/* x = low, y = hi */
		return (limits.x <= testValue) && (testValue <= limits.y) ? true : false;
	}// inRange

	private String findLabel(String workingLine) {
		String netLine = new String(workingLine); // .trim()
		Pattern patternForLabel = Pattern.compile("[\\@\\?A-Za-z]{1}\\w{1,25}:{1}");
		Matcher matcherForLabel = patternForLabel.matcher(netLine);
		if (matcherForLabel.lookingAt()) {
			this.label = matcherForLabel.group();
			netLine = matcherForLabel.replaceFirst(EMPTY_STRING);
		} else {
			this.label = null;
		} // if
		return netLine;
	}// findLabel

	private String findLineNumber(String workingLine) {
		String netLine = new String(workingLine); // .trim()
		Pattern patternForLineNumber = Pattern.compile("^\\d{4}\\s");
		Matcher matcherForLineNumber = patternForLineNumber.matcher(netLine);
		if (matcherForLineNumber.lookingAt()) {
			this.lineNumberStr = matcherForLineNumber.group().trim();
			netLine = matcherForLineNumber.replaceFirst(EMPTY_STRING);
		} else {
			this.lineNumberStr = null;
		} // if

		return netLine;
	}// findInstruction

	private Matcher matcher;

	// private Pattern patternForLineNumber = Pattern.compile("^\\d{4}\\s");
	// private Pattern patternForLabel = Pattern.compile("^[$\\?\\@\\w][\\w$]{1,25}:");
	// private Pattern patternForName = Pattern.compile("^[$\\?\\@\\w][\\w$]{1,25}\\s|[$\\?\\@\\w][\\w$]{1,25}\b");

	/* semicolon inside matching quotes */
	private Pattern patternInQuotes = Pattern.compile("'.*?.*?'");
	// simplest (["'])(\\?.)*?\1
	// this gobbles backslashes (["'])(?:(?=(\\?))\2.)*?\1
	// private Pattern patternForComment = Pattern.compile(";.*");

	// private Pattern patternForInstructions = Pattern.compile(InstructionSet.getRegex());
	// private Pattern patternForDirectives = Pattern.compile(DirectiveSet.getRegex());

	private static final String COMMENT_CHAR = ";"; // semicolon ;
	private static final String SINGLE_QUOTE = "'"; // single quote '
	private static final String SPACE = " "; // space
	private static final String EMPTY_STRING = ""; // empty string

	// private static final String QUOTE_DOUBLE = "\""; // semicolon

}// class LineParser
