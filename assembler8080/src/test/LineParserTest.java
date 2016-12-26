package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import java.util.Set;

import org.junit.Test;

import assembler.DirectiveSet;
import assembler.InstructionSet;
import assembler.LineParser;

public class LineParserTest {

	// @Test
	// public void testTest(){
	// String regexExpression1 = DirectiveSet.getRegex();
	// String regexExpression2 = InstructionSet.getRegex();
	// }//testTest

	@Test
	public void testMT() {
		LineParser lp = new LineParser();
		String sourceLine = "";
		assertThat("Empty Line 1", true, equalTo(lp.parse(sourceLine)));
		assertThat("Empty Line 2", true, equalTo(lp.isEmptyLine()));

		assertThat("No Argument", null, equalTo(lp.getArgument()));
		assertThat("No Comment", null, equalTo(lp.getComment()));
		assertThat("No Directive", null, equalTo(lp.getDirective()));
		assertThat("No Label", null, equalTo(lp.getLabel()));
		assertThat("No LineNumber", -1, equalTo(lp.getLineNumber()));
		assertThat("No LineNumberStr", null, equalTo(lp.getLineNumberStr()));
		assertThat("No Instruction", null, equalTo(lp.getInstruction()));

		assertThat("Has No Argument", false, equalTo(lp.hasArgument()));
		assertThat("Has No Comment", false, equalTo(lp.hasComment()));
		assertThat("Has No Directive", false, equalTo(lp.hasDirective()));
		assertThat("Has No Label", false, equalTo(lp.hasLabel()));
		assertThat("Has No LineNumberStr", false, equalTo(lp.hasLineNumber()));
		assertThat("Has No Instruction", false, equalTo(lp.hasInstruction()));

		sourceLine = "stuff";
		assertThat("Not Empty Line 1", false, equalTo(lp.parse(sourceLine)));
		assertThat("Not Empty Line 2", false, equalTo(lp.isEmptyLine()));

	}// testMT

	@Test
	public void testComments() {
		LineParser lp = new LineParser();
		String sourceLine, comment;

		comment = ";HL-> control table";
		sourceLine = "TTYOutput: LXI H,'TTYTable' 'two' ";
		lp.parse(sourceLine);
		assertThat("No Comments 1", null, equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI H,TTYTable ";
		lp.parse(sourceLine + comment);
		assertThat("Has  Comment", true, equalTo(lp.hasComment()));
		assertThat("Simple Comments 1", comment, equalTo(lp.getComment()));

	}// testComments

	@Test
	public void testCommentsAndQuotes() {
		LineParser lp = new LineParser();
		String sourceLine, comment;

		sourceLine = "TTYOutput: LXI	H,TTYTable	";
		comment = ";HL-> control table";
		lp.parse(sourceLine + comment + "'");
		assertThat(" 1 Quote after semicolon", comment + "'", equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,TTYTable	";
		comment = ";HL-> control table";
		lp.parse(sourceLine + comment + "'pair'");
		assertThat("Quote pair after semicolon", comment + "'pair'", equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,'TTYTable'	";
		comment = ";HL-> control table";
		lp.parse(sourceLine + comment);
		assertThat("Quote pair before semicolon", comment, equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,TTYTable	";
		comment = ";HL-> control table";
		lp.parse(sourceLine + comment + "'enclosed ;'");
		assertThat("Quote pair after semicolon with enclosed semicolon", comment + "'enclosed ;'",
				equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,' ; TTYTable'	";
		comment = ";HL-> control table";
		lp.parse(sourceLine + comment);
		assertThat("Quote pair before semicolon with enclosed semicolon", comment, equalTo(lp.getComment()));

		sourceLine = " ';'  'XYZ ' |";
		comment = "; 'ABC' ';' 'DEF'";
		lp.parse(sourceLine + comment);
		assertThat("multiple quote pairs before/after semicolon with enclosed semicolon", comment,
				equalTo(lp.getComment()));

	}// testCommentsAndQuotes

	@Test
	public void testLabels() {
		LineParser lp = new LineParser();
		String sourceLine, label;

		sourceLine = ";There are no labels";
		lp.parse(sourceLine);
		assertThat("There are no labels or symbols", null, equalTo(lp.getLabel()));
		assertThat("There are no labels or symbols", null, equalTo(lp.getSymbol()));

		label = "simpleLabel";
		lp.parse(label + ":" + sourceLine);
		assertThat("There is a labels", label, equalTo(lp.getLabel()));
		assertThat("Has label", true, equalTo(lp.hasLabel()));
		assertThat("There is a label, no symbol", null, equalTo(lp.getSymbol()));

		label = "bad Label";
		lp.parse(label + ":" + sourceLine);
		assertThat("There is a bad  label", null, equalTo(lp.getLabel()));
		assertThat("There is a bad  label", "bad", equalTo(lp.getSymbol()));

		String comment = "; cannot have label in comment";
		sourceLine = " mvi ";
		lp.parse(sourceLine + comment);
		assertThat("There is a  labels", null, equalTo(lp.getLabel()));
		assertThat("cannot have label in comment", comment, equalTo(lp.getComment()));

	}// testLabels

	@Test
	public void testInstructions() {
		LineParser lp = new LineParser();
		String sourceLine, label, comment;

		sourceLine = "label:       ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment no  instruction", null, equalTo(lp.getInstruction()));

		lp.parse(sourceLine + " ldAx ");
		assertThat("only a label and comment with instruction in it", null, equalTo(lp.getInstruction()));

		sourceLine = "label:  sTaX     ;comment";
		lp.parse(sourceLine);
		assertThat("Has instruction", true, equalTo(lp.hasInstruction()));
		assertThat("only a label and comment and  instruction", "sTaX", equalTo(lp.getInstruction()));

		sourceLine = "label:  sTaXa     ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment and  bad instruction", null, equalTo(lp.getInstruction()));

		Set<String> instructions = InstructionSet.getInstructionSet();
		label = "label: ";
		comment = " ; comment";
		for (String instruction : instructions) {
			lp.parse(label + instruction + comment);
			assertThat("Instruction set: " + instruction, instruction, equalTo(lp.getInstruction()));
		} // for

	}// testInstructions

	@Test
	public void testDirectives() {
		LineParser lp = new LineParser();
		String sourceLine, label, comment;

		sourceLine = "label:       ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment no  directive", null, equalTo(lp.getDirective()));

		lp.parse(sourceLine + " equ ");
		assertThat("only a label and comment with directive in it", null, equalTo(lp.getDirective()));

		sourceLine = "label:  DB     ;comment";
		lp.parse(sourceLine);
		assertThat("Has directive", true, equalTo(lp.hasDirective()));
		assertThat("only a label and comment and  directive", "DB", equalTo(lp.getDirective()));

		sourceLine = "label:  DWX     ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment and  bad Directive", null, equalTo(lp.getDirective()));

		Set<String> directives = DirectiveSet.getDirectiveSet();
		label = "label: ";
		comment = " ; comment";
		for (String directive : directives) {
			lp.parse(label + directive + comment);
			assertThat("Instruction set: " + directive, directive, equalTo(lp.getDirective()));
		} // for
	}// testInstructions

	@Test
	public void testLineNumber() {
		LineParser lp = new LineParser();
		String sourceLine;

		sourceLine = "label:       ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment no  lineNumber String", null, equalTo(lp.getLineNumberStr()));
		assertThat("only a label and comment no  lineNumber", -1, equalTo(lp.getLineNumber()));

		sourceLine = " MVI A,05H       ;comment";

		String lineNumberStr = "0123";
		int lineNumber = Integer.valueOf(lineNumberStr, 10);
		lp.parse(lineNumberStr + sourceLine);
		assertThat("Has -ln 0123, inst, argument and comments", true, equalTo(lp.hasLineNumber()));
		assertThat("Str -ln 0123, inst, argument and comments", lineNumberStr, equalTo(lp.getLineNumberStr()));
		assertThat("Int -ln 0123, inst, argument and comments", lineNumber, equalTo(lp.getLineNumber()));

		lineNumberStr = "01";
		lineNumber = Integer.valueOf(lineNumberStr, 10);
		lp.parse(lineNumberStr + sourceLine);
		assertThat("Has  -ln 01, inst, argument and comments", false, equalTo(lp.hasLineNumber()));
		assertThat("Str  -ln 01, inst, argument and comments", null, equalTo(lp.getLineNumberStr()));
		assertThat("Int  -ln 01, inst, argument and comments", -1, equalTo(lp.getLineNumber()));

		lineNumberStr = "012345";
		lineNumber = Integer.valueOf(lineNumberStr, 10);
		lp.parse(lineNumberStr + sourceLine);
		assertThat("Has  -ln 01, inst, argument and comments", false, equalTo(lp.hasLineNumber()));
		assertThat("Str  -ln 01, inst, argument and comments", null, equalTo(lp.getLineNumberStr()));
		assertThat("Int  -ln 01, inst, argument and comments", -1, equalTo(lp.getLineNumber()));

	}// testLineNumber

}// class LineParserTest
