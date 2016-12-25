package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import org.junit.Test;

import assembler.LineParser;

public class LineParserTest {

	@Test
	public void testMT() {
		LineParser lp = new LineParser();
		String sourceLine = "";
		assertThat("Empty Line 1", true, equalTo(lp.parse(sourceLine)));
		assertThat("Empty Line 2", true, equalTo(lp.isEmptyLine()));

		assertThat("No Argument", null, equalTo(lp.getArgument()));
		assertThat("No Comment", null, equalTo(lp.getComment()));
		assertThat("No Label", null, equalTo(lp.getLabel()));
		assertThat("No OpCode", null, equalTo(lp.getOpCode()));

		sourceLine = "stuff";
		assertThat("Not Empty Line 1", false, equalTo(lp.parse(sourceLine)));
		assertThat("Not Empty Line 2", false, equalTo(lp.isEmptyLine()));

	}// testMT

	@Test
	public void testComments() {
		LineParser lp = new LineParser();
		String comment = ";HL-> control table";

		String sourceLine = "TTYOutput: LXI	H,'TTYTable'	; 'two'		";
		// String sourceLine = "TTYOutput: LXI H,TTYTable ";
		lp.parse(sourceLine);
		assertThat("No Comments 1", null, equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,TTYTable			";
		lp.parse(sourceLine + comment);
		assertThat("Simple Comments 1", comment, equalTo(lp.getComment()));

		lp.parse(sourceLine + comment + "'");
		assertThat("Quote after semicolon 1", comment + "'", equalTo(lp.getComment()));

		sourceLine = "TTYOutput: LXI	H,'; literal'";
		lp.parse(sourceLine);
		assertThat("Semicolon in quote, no comment", null, equalTo(lp.getComment()));

		lp.parse(sourceLine + comment);
		assertThat("Semicolon in quote, with comment", comment, equalTo(lp.getComment()));

	}// testComments

	@Test
	public void testCommentsAndQuotes() {
		LineParser lp = new LineParser();
		String sourceLine, comment;

		sourceLine = "This has two ';comment chars' in';' quotes , but no comment";
		comment = "";
		lp.parse(sourceLine + comment);
		assertThat("Semicolon in quote, with comment 1", null, equalTo(lp.getComment()));
		
		sourceLine = "This has two ';comment chars' in';' quotes , but no comment";
		comment = "; this is a comment";
		lp.parse(sourceLine + comment);
		assertThat("Semicolon in quote, with comment 2", null, equalTo(lp.getComment()));
		
		

	}// testCommentsAndQuotes

}// class LineParserTest
