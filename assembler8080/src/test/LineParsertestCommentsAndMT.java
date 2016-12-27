package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import org.junit.Test;

import assembler.LineParser;

public class LineParsertestCommentsAndMT {
	@Test
	public void testMT() {
		LineParser lp = new LineParser();
		String sourceLine = "";
		assertThat("Empty Line 1", false, equalTo(lp.parse(sourceLine)));
		assertThat("Empty Line 2", false, equalTo(lp.isActiveLine()));

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
		assertThat("Not Empty Line 1", true, equalTo(lp.parse(sourceLine)));
		assertThat("Not Empty Line 2", true, equalTo(lp.isActiveLine()));

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

//	@Test
//	public void testCommentsAndQuotes() {
//		LineParser lp = new LineParser();
//		String sourceLine, comment;
//
//		sourceLine = "TTYOutput: LXI	H,TTYTable	";
//		comment = ";HL-> control table";
//		lp.parse(sourceLine + comment + "'");
//		assertThat(" 1 Quote after semicolon", comment + "'", equalTo(lp.getComment()));
//
//		sourceLine = "TTYOutput: LXI	H,TTYTable	";
//		comment = ";HL-> control table";
//		lp.parse(sourceLine + comment + "'pair'");
//		assertThat("Quote pair after semicolon", comment + "'pair'", equalTo(lp.getComment()));
//
//		sourceLine = "TTYOutput: LXI	H,'TTYTable'	";
//		comment = ";HL-> control table";
//		lp.parse(sourceLine + comment);
//		assertThat("Quote pair before semicolon", comment, equalTo(lp.getComment()));
//
//		sourceLine = "TTYOutput: LXI	H,TTYTable	";
//		comment = ";HL-> control table";
//		lp.parse(sourceLine + comment + "'enclosed ;'");
//		assertThat("Quote pair after semicolon with enclosed semicolon", comment + "'enclosed ;'",
//				equalTo(lp.getComment()));
//
//		sourceLine = "TTYOutput: LXI	H,' ; TTYTable'	";
//		comment = ";HL-> control table";
//		lp.parse(sourceLine + comment);
//		assertThat("Quote pair before semicolon with enclosed semicolon", comment, equalTo(lp.getComment()));
//
//		sourceLine = " ';'  'XYZ ' |";
//		comment = "; 'ABC' ';' 'DEF'";
//		lp.parse(sourceLine + comment);
//		assertThat("multiple quote pairs before/after semicolon with enclosed semicolon", comment,
//				equalTo(lp.getComment()));
//
//	}// testCommentsAndQuotes

}//class LineParsertestCommentsAndMT
