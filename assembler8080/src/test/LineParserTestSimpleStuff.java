package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import org.junit.Test;

import assembler.LineParser;

public class LineParserTestSimpleStuff {
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

	@Test
	public void testOpCodeSize() {
		String[] opCodes = { " NOP", " LXI", " DaD", " CPI", " rst", " LHLD", " JUNK" };
		int[] sizes = { 1, 3, 1, 2, 1, 3, 0 };

		LineParser lp = new LineParser();
		for (int i = 0; i < opCodes.length; i++) {
			lp.parse(opCodes[i]);
			assertThat(opCodes[i] + " - OpCode Size", sizes[i], equalTo(lp.getOpCodeSize()));
		} // for

	}// testOpCodeSize


}//LineParserTestLabels
