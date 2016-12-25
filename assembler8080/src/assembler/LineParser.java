package assembler;

import java.awt.Point;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Queue;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LineParser {
	String argument;
	String comment;
	String label;
	String opCode;

	boolean emptyLine;

	Matcher matcher;

	Pattern patternLabel = Pattern.compile("^[a-zA-Z]+\\w+:");
	/* semicolon inside matching quotes */
	Pattern patternInQuotes = Pattern.compile("'.*?.*?'");
	Pattern patternForComment = Pattern.compile(";.*");

	public LineParser() {
		// TODO Auto-generated constructor stub
	}// Constructor

	public boolean isEmptyLine() {
		return this.emptyLine;
	}// isEmptyLine

	public String getArgument() {
		return this.argument;
	}// getArgument

	public String getComment() {
		return this.comment;
	}// getArgument

	public String getLabel() {
		return this.label;
	}// getArgument

	public String getOpCode() {
		return this.opCode;
	}// getArgument

	private void clear() {
		this.argument = null;
		this.comment = null;
		this.label = null;
		this.opCode = null;
		this.emptyLine = false;
	}// clear

	public boolean parse(String sourceLine) {
		String workingLine = sourceLine.replaceAll("\t", " ");
		clear();
		if (workingLine.trim().length() == 0) {
			emptyLine = true;
			return emptyLine;
		} // if
		emptyLine = false;

		workingLine = findComment(workingLine);

		return this.emptyLine;
	}// parse

	private String findComment(String workingLine) {
		String netLine = new String(workingLine);
		this.comment = null;
		if (!netLine.contains(COMMENT_CHAR)) {
			/* just return the line - no comments here */
		} else if (!netLine.contains(SINGLE_QUOTE)) {
			comment = matcher.group();
			netLine = matcher.replaceFirst("");
			/* simple comment */
		} else {
			Integer commentCharIndex = netLine.indexOf(COMMENT_CHAR);
			Queue<Integer> commentCharIndexes = new LinkedList<Integer>();

			while (commentCharIndex != -1) {
				commentCharIndexes.add(commentCharIndex);
				commentCharIndex = netLine.indexOf(COMMENT_CHAR, commentCharIndex);
			} // while - get all COMMENT_CHARs

			/* if there are quotes, there might be literal commentChars */
			Queue<Point> quotePairs = new LinkedList<Point>();
			matcher = patternInQuotes.matcher(netLine);
			while (matcher.find()) {
				quotePairs.add(new Point(matcher.start(), matcher.end()));
			} // while

			boolean commentFound = true;
			Integer targetIndex = -1;
			Iterator indexIterator = commentCharIndexes.iterator();
			while (indexIterator.hasNext()){
				//commentFound = true;
				targetIndex = (Integer) indexIterator.next();
				for (Point p : quotePairs) {
					if (inRange(targetIndex,p)){
						commentFound = false;	/* comment char in quotes */
						continue;
					}//if in range
				}//for points
			}//while
			
			if (commentFound){
				comment = workingLine.substring(targetIndex,workingLine.length()-1);
				netLine = workingLine.substring(0,targetIndex-1);
			}//if there is a comment
		} // if

		return netLine.trim();

	}// findComment
	
	private boolean inRange(int testValue,Point limits){
		/* x = low, y = hi */
		return (limits.x<= testValue)&&(testValue <=limits.y)?true:false;
	}//inRange

	private int rangeCheck(int testValue, Point limits) {
		/* x = low, y = hi */
		int ans = IN_RANGE;
		if (testValue < limits.x) {
			ans = LESS_THAN_RANGE;
		} else if (testValue > limits.y) {
			ans = GREATER_THAN_RANGE;
		} else {
			ans = IN_RANGE;
		} // if
		return ans;
	}// rangeCheck

	private static final String COMMENT_CHAR = ";"; // semicolon
	private static final String SINGLE_QUOTE = "'"; // semicolon

	private static final int LESS_THAN_RANGE = -1;
	private static final int IN_RANGE = 0;
	private static final int GREATER_THAN_RANGE = 1;

	// private static final String QUOTE_DOUBLE = "\""; // semicolon

}// class LineParser
